#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# FlashDoc — Mise à jour APK (nouvelle version de l'app mobile)
# Usage : bash update-apk.sh
# ═══════════════════════════════════════════════════════════════

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}🔄 Mise à jour backend FlashDoc...${NC}"

cd /opt/flashdoc

# Rebuild et redémarrer seulement le backend (pas la DB)
docker build -t flashdoc_backend:latest ./backend/
docker compose up -d --no-deps flashdoc_backend

sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5003/api/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Mise à jour réussie !${NC}"
else
    echo "❌ Problème — vérifier les logs : docker compose logs flashdoc_backend"
fi
