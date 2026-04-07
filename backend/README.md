# FlashDoc Backend — Guide de démarrage

## Prérequis

- **Docker Desktop** installé et démarré (Windows)
- **Node.js 20+** installé (pour le développement local)
- **Git** installé

---

## Démarrage en 3 commandes

Ouvre un terminal PowerShell dans `D:\PROJETS\FLASHDOC-APP\backend\` et exécute :

```powershell
# 1. Installer les dépendances Node.js
npm install

# 2. Lancer PostgreSQL + Redis + l'API (tout en un)
docker-compose up --build

# 3. (Premier lancement uniquement) Dans un 2e terminal :
npm run db:migrate    # Crée les tables
npm run db:seed       # Injecte les données de test
```

L'API est disponible sur : **http://localhost:3000**

---

## Vérifier que tout fonctionne

```powershell
# Test health check
curl http://localhost:3000/api/health

# Réponse attendue :
# { "success": true, "message": "FlashDoc API opérationnelle", "version": "1.0.0" }
```

---

## Comptes de test (créés par le seed)

| Rôle    | Téléphone       | Mot de passe          |
|---------|-----------------|-----------------------|
| Admin   | +237600000000   | Admin@FlashDoc2024!   |
| Médecin | +237611111111   | Doctor@Test2024!      |
| Patient | +237622222222   | Patient@Test2024!     |

---

## Endpoints API principaux

### Authentification
```
POST /api/auth/register      — Créer un compte
POST /api/auth/verify-otp    — Vérifier le code OTP
POST /api/auth/login         — Se connecter
POST /api/auth/refresh       — Renouveler le token
GET  /api/auth/me            — Mon profil (auth requise)
```

### Consultations (Patient)
```
POST /api/consultations             — Créer une demande
GET  /api/consultations             — Mon historique
GET  /api/consultations/:id         — Détail d'une consultation
POST /api/consultations/:id/rate    — Noter le médecin
```

### Consultations (Médecin)
```
POST /api/consultations/:id/start   — Démarrer la consultation
POST /api/consultations/:id/end     — Terminer + envoyer ordonnance
```

### Paiements
```
POST /api/payments/initiate         — Initier un paiement OTM
GET  /api/payments/status/:id       — Vérifier le statut
POST /api/payments/simulate         — [DEV] Simuler un paiement réussi
POST /api/payments/callback         — Webhook OTM (Orange/MoMo)
```

### Médecins
```
GET  /api/doctors                   — Liste des médecins
GET  /api/doctors/:id               — Profil public
POST /api/doctors/register          — Soumettre dossier d'affiliation
GET  /api/doctors/me/profile        — Mon profil médecin
PUT  /api/doctors/me/profile        — Modifier mon profil
GET  /api/doctors/me/wallet         — Mon wallet + transactions
GET  /api/doctors/me/consultations  — Mes consultations
```

### Admin
```
GET /api/admin/dashboard            — Statistiques globales
GET /api/admin/doctors/pending      — Médecins en attente
PUT /api/admin/doctors/:id/approve  — Approuver un médecin
PUT /api/admin/doctors/:id/suspend  — Suspendre un médecin
GET /api/admin/consultations        — Toutes les consultations
```

---

## Flux de test complet (scénario "consultation immédiate")

### Étape 1 — Connexion Patient
```powershell
curl -X POST http://localhost:3000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"phone":"+237622222222","password":"Patient@Test2024!"}'
```
→ Récupérer le `accessToken`

### Étape 2 — Créer une consultation
```powershell
curl -X POST http://localhost:3000/api/consultations `
  -H "Authorization: Bearer TOKEN_ICI" `
  -H "Content-Type: application/json" `
  -d '{"mode":"VIDEO","speciality":"Généraliste","symptomsText":"Douleur à la poitrine"}'
```
→ Récupérer le `consultationId`

### Étape 3 — Simuler le paiement (mode dev)
```powershell
curl -X POST http://localhost:3000/api/payments/simulate `
  -H "Authorization: Bearer TOKEN_ICI" `
  -H "Content-Type: application/json" `
  -d '{"consultationId":"ID_ICI"}'
```
→ La consultation passe en `WAITING_DOCTOR` et le dispatch Socket.io est déclenché

### Étape 4 — Connexion Médecin (Socket.io)
Le médecin se connecte via Socket.io avec son token et émet `doctor:available`.
Il reçoit l'événement `consultation:new_request` et répond `consultation:accept`.
→ Le patient reçoit `consultation:matched` avec les infos du médecin.

---

## Base de données — Prisma Studio (interface visuelle)

```powershell
npm run db:studio
# Ouvre http://localhost:5555 — interface graphique pour voir les tables
```

---

## Commandes utiles

```powershell
# Arrêter tous les containers
docker-compose down

# Tout supprimer (y compris les données)
docker-compose down -v

# Voir les logs en direct
docker-compose logs -f api

# Accéder à PostgreSQL directement
docker exec -it flashdoc_postgres psql -U flashdoc_user -d flashdoc_db

# Réinitialiser la base de données
npm run db:migrate -- --name reset
npm run db:seed
```

---

## Architecture Socket.io — Événements temps réel

### Côté Patient (émet)
| Événement | Description |
|-----------|-------------|
| `consultation:join` | Rejoindre une room de consultation |
| `message:send` | Envoyer un message chat |
| `webrtc:signal` | Signal WebRTC pour audio/vidéo |

### Côté Patient (reçoit)
| Événement | Description |
|-----------|-------------|
| `consultation:matched` | Un médecin a accepté |
| `consultation:expired` | Aucun médecin disponible (60s) |
| `message:new` | Nouveau message |
| `webrtc:signal` | Signal WebRTC du médecin |

### Côté Médecin (émet)
| Événement | Description |
|-----------|-------------|
| `doctor:available` | Se mettre disponible |
| `doctor:unavailable` | Se mettre indisponible |
| `consultation:accept` | Accepter une consultation |
| `message:send` | Envoyer un message |
| `webrtc:signal` | Signal WebRTC |

### Côté Médecin (reçoit)
| Événement | Description |
|-----------|-------------|
| `consultation:new_request` | Nouvelle demande disponible |
| `consultation:request_taken` | Demande prise par un autre médecin |
| `consultation:already_taken` | Acceptation trop tardive |
| `doctor:status` | Confirmation statut disponibilité |

---

## Structure du projet

```
backend/
├── Dockerfile
├── docker-compose.yml
├── package.json
├── .env                    ← Variables d'environnement (ne pas committer)
├── .env.example            ← Template à partager
├── .gitignore
├── prisma/
│   ├── schema.prisma       ← Schéma base de données (10 tables)
│   └── seed.js             ← Données de test
├── uploads/                ← Fichiers uploadés (diplômes, photos)
├── logs/                   ← Logs applicatifs
└── src/
    ├── index.js            ← Point d'entrée
    ├── app.js              ← Express app
    ├── config/
    │   ├── database.js     ← Prisma client
    │   └── redis.js        ← Redis client
    ├── middleware/
    │   ├── auth.middleware.js
    │   ├── error.middleware.js
    │   └── validate.middleware.js
    ├── services/
    │   ├── auth.service.js         ← Inscription, OTP, JWT
    │   └── socket.service.js       ← Dispatch temps réel
    ├── controllers/
    │   ├── auth.controller.js
    │   ├── consultation.controller.js
    │   ├── doctor.controller.js
    │   └── payment.controller.js
    └── routes/
        ├── auth.routes.js
        ├── consultation.routes.js
        ├── doctor.routes.js
        ├── patient.routes.js
        ├── payment.routes.js
        └── admin.routes.js
```

---

## Prochaines étapes de développement

1. **Intégrer les vraies APIs Mobile Money**
   - Orange Money Cameroun : https://developer.orange.com/apis/orange-money-webpay-cm
   - MTN MoMo : https://momodeveloper.mtn.com

2. **Intégrer un provider SMS pour les OTP**
   - Option locale : CinetPay SMS, Twilio, ou Africa's Talking

3. **Ajouter la génération PDF d'ordonnances**
   - Fichier à créer : `src/services/prescription.service.js`

4. **Déployer sur le VPS OVH**
   - Copier le projet via `scp` ou `git clone`
   - Configurer `.env` de production
   - Lancer `docker-compose up -d`

5. **Démarrer le développement Flutter**
   - App Patient (25 écrans)
   - App Médecin (15 écrans)
