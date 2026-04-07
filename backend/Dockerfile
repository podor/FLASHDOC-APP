# ── Dockerfile backend FlashDoc ─────────────────────────────
FROM node:20-alpine

# Dépendances système (openssl pour Prisma, wget+curl pour healthcheck)
RUN apk add --no-cache openssl wget curl

WORKDIR /app

# Dépendances Node
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --only=production

# Générer le client Prisma
RUN npx prisma generate

# Code source
COPY src ./src/

# Dossier uploads avatars
RUN mkdir -p /app/uploads/avatars

EXPOSE 3000

# Démarrage : db push + serveur
CMD ["sh", "-c", "npx prisma db push --accept-data-loss && node src/index.js"]
