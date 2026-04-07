#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# FlashDoc — Script de déploiement initial sur le VPS
# Usage : bash /opt/flashdoc/deploy/deploy.sh
# ═══════════════════════════════════════════════════════════════

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}"
echo "  ███████╗██╗      █████╗ ███████╗██╗  ██╗██████╗  ██████╗  ██████╗"
echo "  ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔════╝"
echo "  █████╗  ██║     ███████║███████╗███████║██║  ██║██║   ██║██║"
echo "  ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║██║  ██║██║   ██║██║"
echo "  ██║     ███████╗██║  ██║███████║██║  ██║██████╔╝╚██████╔╝╚██████╗"
echo "  ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝"
echo -e "${NC}"
echo -e "${GREEN}🚀 Déploiement FlashDoc Production${NC}"
echo ""

DEPLOY_DIR="/opt/flashdoc"

# ── 1. Vérifications ────────────────────────────────────────────
echo -e "${YELLOW}[1/8] Vérifications préliminaires...${NC}"

[ ! -f "$DEPLOY_DIR/.env" ] && \
    echo -e "${RED}❌ .env manquant. Copie deploy/.env.production vers $DEPLOY_DIR/.env${NC}" && exit 1

[ ! -f "$DEPLOY_DIR/backend/Dockerfile" ] && \
    echo -e "${RED}❌ Dockerfile manquant${NC}" && exit 1

[ ! -f "$DEPLOY_DIR/deploy/config/pgadmin-servers.json" ] && \
    echo -e "${RED}❌ pgadmin-servers.json manquant${NC}" && exit 1

echo -e "${GREEN}✓ Fichiers présents${NC}"

# ── 2. Dossiers ─────────────────────────────────────────────────
echo -e "${YELLOW}[2/8] Création des dossiers...${NC}"
mkdir -p "$DEPLOY_DIR/backend/uploads/avatars"
chmod 755 "$DEPLOY_DIR/backend/uploads/avatars"
echo -e "${GREEN}✓ Dossiers créés${NC}"

# ── 3. Build ────────────────────────────────────────────────────
echo -e "${YELLOW}[3/8] Build de l'image backend...${NC}"
cd "$DEPLOY_DIR"
docker build -t flashdoc_backend:latest ./backend/
echo -e "${GREEN}✓ Image buildée${NC}"

# ── 4. Arrêt ancien ─────────────────────────────────────────────
echo -e "${YELLOW}[4/8] Arrêt des anciens conteneurs...${NC}"
docker compose -f deploy/docker-compose.yml down --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✓ Nettoyé${NC}"

# ── 5. Démarrage ────────────────────────────────────────────────
echo -e "${YELLOW}[5/8] Démarrage de tous les services...${NC}"
docker compose -f deploy/docker-compose.yml --env-file .env up -d
echo -e "${GREEN}✓ Services démarrés${NC}"

# ── 6. Attente PostgreSQL ────────────────────────────────────────
echo -e "${YELLOW}[6/8] Attente PostgreSQL...${NC}"
MAX=30; COUNT=0
until docker exec flashdoc_postgres pg_isready -U flashdoc_user > /dev/null 2>&1; do
    COUNT=$((COUNT+1))
    [ $COUNT -ge $MAX ] && echo -e "${RED}❌ PostgreSQL timeout${NC}" && \
        docker compose -f deploy/docker-compose.yml logs flashdoc_postgres && exit 1
    printf "."
    sleep 2
done
echo -e "\n${GREEN}✓ PostgreSQL prêt${NC}"

# ── 7. Health check API ──────────────────────────────────────────
echo -e "${YELLOW}[7/8] Health check API...${NC}"
sleep 8
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5003/api/health)
if [ "$HTTP" = "200" ]; then
    echo -e "${GREEN}✓ API opérationnelle${NC}"
else
    echo -e "${RED}❌ API ne répond pas (HTTP $HTTP)${NC}"
    docker compose -f deploy/docker-compose.yml logs --tail=40 flashdoc_backend
    exit 1
fi

# ── 8. Résumé ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ FlashDoc déployé avec succès !${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}API         ${NC}: https://api.flashdoc.tchoukheadcorp.net"
echo -e "  ${CYAN}pgAdmin     ${NC}: https://pgadmin.flashdoc.tchoukheadcorp.net"
echo -e "  ${CYAN}RedisInsight${NC}: https://redis.flashdoc.tchoukheadcorp.net"
echo ""
echo -e "  ${YELLOW}Logs    ${NC}: docker compose -f deploy/docker-compose.yml logs -f"
echo -e "  ${YELLOW}Status  ${NC}: docker compose -f deploy/docker-compose.yml ps"
echo ""
