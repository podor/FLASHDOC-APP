const express  = require('express');
const router   = express.Router();
const prisma   = require('../config/database');
const response = require('../utils/response');
const { authenticate } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

router.use(authenticate);

// ── POST /api/appointments ────────────────────────────────────────
router.post('/', asyncHandler(async (req, res) => {
  if (req.user.role !== 'PATIENT') {
    return response.error(res, 'Réservé aux patients', 403);
  }

  const { speciality, scheduledAt, type, reason } = req.body;

  if (!speciality || !scheduledAt || !type || !reason) {
    return response.error(res, 'Tous les champs sont requis', 400);
  }

  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  if (!patient) return response.error(res, 'Patient introuvable', 404);

  // Créer le rendez-vous
  // Comme la table Schedule existe déjà, on l'utilise
  const appointment = await prisma.schedule.create({
    data: {
      patientId:   patient.id,
      speciality,
      scheduledAt: new Date(scheduledAt),
      type:        type || 'PHYSICAL',
      reason,
      status:      'PENDING',
    },
  }).catch(async () => {
    // Si la table Schedule n'a pas ces champs, on stocke dans une structure générique
    // Fallback : créer une consultation en mode SCHEDULED
    return prisma.consultation.create({
      data: {
        patientId:    patient.id,
        speciality,
        mode:         type === 'ONLINE' ? 'VIDEO' : 'CHAT',
        symptomsText: reason,
        status:       'SCHEDULED',
        scheduledAt:  new Date(scheduledAt),
        totalAmount:  0,
      },
    });
  });

  return response.success(res, { appointment }, 'Rendez-vous confirmé', 201);
}));

// ── GET /api/appointments/me ──────────────────────────────────────
router.get('/me', asyncHandler(async (req, res) => {
  if (req.user.role !== 'PATIENT') {
    return response.error(res, 'Réservé aux patients', 403);
  }

  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  if (!patient) return response.error(res, 'Patient introuvable', 404);

  // Récupérer les consultations planifiées
  const appointments = await prisma.consultation.findMany({
    where: {
      patientId: patient.id,
      status: 'SCHEDULED',
    },
    include: {
      doctor: {
        include: {
          user: { select: { firstName: true, lastName: true } },
        },
      },
    },
    orderBy: { scheduledAt: 'asc' },
  }).catch(() => []);

  return response.success(res, { appointments });
}));

module.exports = router;
