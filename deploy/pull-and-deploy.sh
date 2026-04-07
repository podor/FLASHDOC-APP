#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# FlashDoc — Pull & Deploy depuis GitHub
# Usage : bash /opt/flashdoc/deploy/pull-and-deploy.sh
# Cron  : 0 3 * * * bash /opt/flashdoc/deploy/pull-and-deploy.sh >> /var/log/flashdoc-deploy.log 2>&1
# ═══════════════════════════════════════════════════════════════

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
DEPLOY_DIR="/opt/flashdoc"
LOG_DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "\n${YELLOW}[$LOG_DATE] 🔄 FlashDoc pull & deploy...${NC}"
cd "$DEPLOY_DIR"

# ── 1. Pull depuis GitHub ───────────────────────────────────────
echo -e "${YELLOW}[1/4] Git pull...${NC}"
git fetch origin main

# Vérifier s'il y a des changements
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}✓ Déjà à jour ($(git rev-parse --short HEAD))${NC}"
    exit 0
fi

echo "  Nouveau commit : $(git log --oneline origin/main -1)"
git pull origin main
echo -e "${GREEN}✓ Code mis à jour$(git rev-parse --short HEAD)${NC}"

# ── 2. Rebuild l'image Docker ───────────────────────────────────
echo -e "${YELLOW}[2/4] Build image...${NC}"
docker build -t flashdoc_backend:latest ./backend/
echo -e "${GREEN}✓ Image buildée${NC}"

# ── 3. Redémarrer le backend (pas la DB ni Redis) ──────────────
echo -e "${YELLOW}[3/4] Redémarrage backend...${NC}"
docker compose -f docker-compose.yml up -d --no-deps flashdoc_backend
echo -e "${GREEN}✓ Backend redémarré${NC}"

# ── 4. Vérification ────────────────────────────────────────────
echo -e "${YELLOW}[4/4] Health check...${NC}"
sleep 8
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5003/api/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Déploiement réussi ! (commit: $(git rev-parse --short HEAD))${NC}"
else
    echo -e "${RED}❌ Health check échoué (HTTP $HTTP_CODE)${NC}"
    docker compose logs --tail=30 flashdoc_backend
    exit 1
fi
