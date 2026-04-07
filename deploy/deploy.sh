#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# FlashDoc — Script de déploiement VPS
# Usage : bash deploy.sh
# Prérequis : code pushé sur le VPS dans /opt/flashdoc/
# ═══════════════════════════════════════════════════════════════

set -e  # Stopper en cas d'erreur
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${GREEN}🚀 Déploiement FlashDoc...${NC}"

# ── 1. Vérifications préliminaires ─────────────────────────────
echo -e "\n${YELLOW}[1/7] Vérifications...${NC}"

if [ ! -f "/opt/flashdoc/.env" ]; then
    echo -e "${RED}❌ Fichier .env manquant dans /opt/flashdoc/.env${NC}"
    echo "   Copie .env.production vers /opt/flashdoc/.env et remplis les valeurs"
    exit 1
fi

if [ ! -f "/opt/flashdoc/backend/Dockerfile" ]; then
    echo -e "${RED}❌ Dockerfile manquant${NC}"
    exit 1
fi

# ── 2. Créer dossiers nécessaires ──────────────────────────────
echo -e "\n${YELLOW}[2/7] Création des dossiers...${NC}"
mkdir -p /opt/flashdoc/backend/uploads/avatars
chmod 755 /opt/flashdoc/backend/uploads/avatars
echo -e "${GREEN}✓ Dossiers créés${NC}"

# ── 3. Build de l'image Docker ─────────────────────────────────
echo -e "\n${YELLOW}[3/7] Build de l'image backend...${NC}"
cd /opt/flashdoc
docker build -t flashdoc_backend:latest ./backend/
echo -e "${GREEN}✓ Image buildée${NC}"

# ── 4. Arrêter les anciens conteneurs ──────────────────────────
echo -e "\n${YELLOW}[4/7] Arrêt des anciens conteneurs...${NC}"
docker compose -f docker-compose.yml down --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✓ Anciens conteneurs arrêtés${NC}"

# ── 5. Démarrer les services ────────────────────────────────────
echo -e "\n${YELLOW}[5/7] Démarrage des services...${NC}"
docker compose -f docker-compose.yml up -d
echo -e "${GREEN}✓ Services démarrés${NC}"

# ── 6. Attendre que la DB soit prête ───────────────────────────
echo -e "\n${YELLOW}[6/7] Attente de la base de données...${NC}"
sleep 5
MAX_TRIES=30
TRIES=0
until docker exec flashdoc_postgres pg_isready -U flashdoc_user -d flashdoc_prod > /dev/null 2>&1; do
    TRIES=$((TRIES+1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        echo -e "${RED}❌ La base de données ne répond pas${NC}"
        docker compose logs flashdoc_postgres
        exit 1
    fi
    echo "   En attente... ($TRIES/$MAX_TRIES)"
    sleep 2
done
echo -e "${GREEN}✓ Base de données prête${NC}"

# ── 7. Vérification finale ─────────────────────────────────────
echo -e "\n${YELLOW}[7/7] Vérification de l'API...${NC}"
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5003/api/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ API répond sur le port 5003${NC}"
else
    echo -e "${RED}❌ L'API ne répond pas (code: $HTTP_CODE)${NC}"
    docker compose logs flashdoc_backend
    exit 1
fi

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ FlashDoc déployé avec succès !${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "  Backend  : http://localhost:5003/api/health"
echo "  API HTTPS: https://api.flashdoc.tchoukheadcorp.net/api/health"
echo ""
echo "  Logs    : docker compose logs -f flashdoc_backend"
echo "  Status  : docker compose ps"
echo ""
