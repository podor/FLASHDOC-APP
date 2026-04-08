require('dotenv').config();
const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');
const rateLimit  = require('express-rate-limit');

const authRoutes         = require('./routes/auth.routes');
const patientRoutes      = require('./routes/patient.routes');
const doctorRoutes       = require('./routes/doctor.routes');
const consultationRoutes = require('./routes/consultation.routes');
const paymentRoutes      = require('./routes/payment.routes');
const adminRoutes        = require('./routes/admin.routes');
// ✅ Nouvelles routes
const userRoutes         = require('./routes/user.routes');
const prescriptionRoutes = require('./routes/prescription.routes');
const appointmentRoutes  = require('./routes/appointment.routes');

const { errorHandler }   = require('./middleware/error.middleware');
const logger             = require('./utils/logger');

const app = express();

// ✅ Trust proxy — obligatoire quand derrière Nginx
// Permet à express-rate-limit de lire correctement X-Forwarded-For
app.set('trust proxy', 1);

// ── Sécurité ────────────────────────────────────────────────────
app.use(helmet());

// ── CORS ────────────────────────────────────────────────────────
if (process.env.NODE_ENV === 'development') {
  app.use(cors());
} else {
  const allowedOrigins = (process.env.ALLOWED_ORIGINS || '').split(',').map(o => o.trim());
  app.use(cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error('Non autorisé par CORS'));
    },
    credentials: true,
  }));
}

// ── Rate limiting global ─────────────────────────────────────────
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: process.env.NODE_ENV === 'development' ? 1000 : 100,
  message: { success: false, message: 'Trop de requêtes, réessayez dans 15 minutes.' },
}));

// ── Parsers ──────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Logs HTTP ────────────────────────────────────────────────────
app.use(morgan('combined', {
  stream: { write: (msg) => logger.http(msg.trim()) },
}));

// ── Fichiers statiques (avatars + documents uploadés) ──────────────────
// Sert /uploads/avatars/* et /uploads/doctor-docs/*
app.use('/uploads', express.static('/app/uploads'));

// ── Health check ─────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'FlashDoc API opérationnelle',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString(),
  });
});

// ── Routes API ───────────────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/patients',      patientRoutes);
app.use('/api/doctors',       doctorRoutes);
app.use('/api/consultations', consultationRoutes);
app.use('/api/payments',      paymentRoutes);
app.use('/api/admin',         adminRoutes);
// ✅ Nouvelles routes montées
app.use('/api/users',         userRoutes);
app.use('/api/prescriptions', prescriptionRoutes);
app.use('/api/appointments',  appointmentRoutes);

// ── 404 ──────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route introuvable : ${req.method} ${req.path}` });
});

// ── Gestionnaire d'erreurs global ────────────────────────────────
app.use(errorHandler);

module.exports = app;
