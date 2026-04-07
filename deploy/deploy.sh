#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# FlashDoc — Script de déploiement initial sur le VPS
# Usage : cd /opt/flashdoc && bash deploy/deploy.sh
# ⚠️  Toujours lancer depuis /opt/flashdoc (là où est le .env)
# ═══════════════════════════════════════════════════════════════

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
DEPLOY_DIR="/opt/flashdoc"
COMPOSE="docker compose -f $DEPLOY_DIR/deploy/docker-compose.yml --env-file $DEPLOY_DIR/.env"

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

# ── 1. Vérifications ────────────────────────────────────────────
echo -e "${YELLOW}[1/8] Vérifications préliminaires...${NC}"

cd "$DEPLOY_DIR"

[ ! -f "$DEPLOY_DIR/.env" ] && \
    echo -e "${RED}❌ .env manquant dans $DEPLOY_DIR/.env${NC}" && exit 1

[ ! -f "$DEPLOY_DIR/backend/Dockerfile" ] && \
    echo -e "${RED}❌ Dockerfile manquant${NC}" && exit 1

# Charger les variables du .env pour les utiliser dans ce script
set -a; source "$DEPLOY_DIR/.env"; set +a

echo -e "${GREEN}✓ Fichiers présents${NC}"
echo "  DB       : $POSTGRES_DB @ flashdoc_postgres"
echo "  Base URL : $BASE_URL"

# ── 2. Dossiers ─────────────────────────────────────────────────
echo -e "\n${YELLOW}[2/8] Création des dossiers...${NC}"
mkdir -p "$DEPLOY_DIR/backend/uploads/avatars"
chmod 755 "$DEPLOY_DIR/backend/uploads/avatars"
echo -e "${GREEN}✓ Dossiers créés${NC}"

# ── 3. Build ────────────────────────────────────────────────────
echo -e "\n${YELLOW}[3/8] Build de l'image backend...${NC}"
docker build -t flashdoc_backend:latest "$DEPLOY_DIR/backend/"
echo -e "${GREEN}✓ Image buildée${NC}"

# ── 4. Arrêt propre ─────────────────────────────────────────────
echo -e "\n${YELLOW}[4/8] Arrêt des anciens conteneurs...${NC}"
$COMPOSE down --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✓ Nettoyé${NC}"

# ── 5. Démarrer DB et Redis d'abord ─────────────────────────────
echo -e "\n${YELLOW}[5/8] Démarrage DB + Redis...${NC}"
$COMPOSE up -d flashdoc_postgres flashdoc_redis

# Attendre PostgreSQL
MAX=30; COUNT=0
until docker exec flashdoc_postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" > /dev/null 2>&1; do
    COUNT=$((COUNT+1))
    [ $COUNT -ge $MAX ] && echo -e "${RED}❌ PostgreSQL timeout${NC}" && exit 1
    printf "."
    sleep 2
done
echo -e "\n${GREEN}✓ PostgreSQL prêt${NC}"

# ── 6. Migration Prisma (db push pour le premier déploiement) ───
echo -e "\n${YELLOW}[6/8] Migration base de données...${NC}"
docker run --rm \
  --network flashdoc_network \
  -e DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@flashdoc_postgres:5432/${POSTGRES_DB}" \
  flashdoc_backend:latest \
  sh -c "npx prisma db push --accept-data-loss && echo 'Migration OK'"
echo -e "${GREEN}✓ Base de données migrée${NC}"

# ── 7. Démarrer tous les services ──────────────────────────────
echo -e "\n${YELLOW}[7/8] Démarrage de tous les services...${NC}"
$COMPOSE up -d
echo -e "${GREEN}✓ Services démarrés${NC}"

# ── 8. Health check ─────────────────────────────────────────────
echo -e "\n${YELLOW}[8/8] Health check API...${NC}"
sleep 10
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5003/api/health)
if [ "$HTTP" = "200" ]; then
    echo -e "${GREEN}✓ API opérationnelle${NC}"
else
    echo -e "${RED}❌ API ne répond pas (HTTP $HTTP)${NC}"
    docker logs flashdoc_backend --tail=40
    exit 1
fi

# ── Résumé ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ FlashDoc déployé avec succès !${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}API         ${NC}: https://api.flashdoc.tchoukheadcorp.net/api/health"
echo -e "  ${CYAN}pgAdmin     ${NC}: https://pgadmin.flashdoc.tchoukheadcorp.net"
echo -e "  ${CYAN}RedisInsight${NC}: https://redis.flashdoc.tchoukheadcorp.net"
echo ""
echo -e "  ${YELLOW}Logs    ${NC}: docker logs flashdoc_backend -f"
echo -e "  ${YELLOW}Status  ${NC}: docker ps --filter name=flashdoc"
echo ""
