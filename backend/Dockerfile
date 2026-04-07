# ── Dockerfile backend FlashDoc ───────────────────────────────
# Doit être placé dans : backend/Dockerfile

FROM node:20-alpine

# Dépendances système pour Prisma
RUN apk add --no-cache openssl

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./
COPY prisma ./prisma/

# Installer les dépendances production uniquement
RUN npm ci --only=production

# Générer le client Prisma
RUN npx prisma generate

# Copier le code source
COPY src ./src/

# Créer le dossier uploads
RUN mkdir -p /app/uploads/avatars

# Exposer le port
EXPOSE 3000

# Script de démarrage : migration + lancement
CMD ["sh", "-c", "npx prisma migrate deploy && node src/index.js"]
