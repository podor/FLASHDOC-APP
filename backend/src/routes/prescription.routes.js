const express  = require('express');
const router   = express.Router();
const prisma   = require('../config/database');
const response = require('../utils/response');
const { authenticate } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

router.use(authenticate);

// ── POST /api/prescriptions ───────────────────────────────────────
// Médecin crée une ordonnance certifiée pour le patient
router.post('/', asyncHandler(async (req, res) => {
  if (req.user.role !== 'DOCTOR') {
    return response.error(res, 'Réservé aux médecins', 403);
  }

  const { consultationId, prescriptionId, hash, diagnosis, medications, instructions, issuedAt } = req.body;

  if (!consultationId || !hash || !diagnosis) {
    return response.error(res, 'Données manquantes (consultationId, hash, diagnosis)', 400);
  }

  const doctor = await prisma.doctor.findUnique({ where: { userId: req.user.id } });
  if (!doctor) return response.error(res, 'Médecin introuvable', 404);

  const consultation = await prisma.consultation.findUnique({
    where: { id: consultationId },
  });
  if (!consultation) return response.error(res, 'Consultation introuvable', 404);
  if (consultation.doctorId !== doctor.id) return response.error(res, 'Accès refusé', 403);

  // ✅ Stocker l'ordonnance dans le champ Json de la consultation
  const prescriptionData = {
    id:           prescriptionId,
    hash,
    diagnosis,
    medications:  medications || [],
    instructions: instructions || '',
    issuedAt:     issuedAt || new Date().toISOString(),
    doctorId:     doctor.id,
    patientId:    consultation.patientId,
  };

  await prisma.consultation.update({
    where: { id: consultationId },
    data:  { prescription: prescriptionData },
  });

  return response.success(res, { prescriptionId, hash }, 'Ordonnance créée avec succès');
}));

// ── GET /api/prescriptions/me ─────────────────────────────────────
// Patient consulte ses ordonnances
router.get('/me', asyncHandler(async (req, res) => {
  if (req.user.role !== 'PATIENT') {
    return response.error(res, 'Réservé aux patients', 403);
  }

  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  if (!patient) return response.error(res, 'Patient introuvable', 404);

  // Récupérer les consultations avec une ordonnance
  const consultations = await prisma.consultation.findMany({
    where: {
      patientId: patient.id,
      NOT: { prescription: null },
    },
    include: {
      doctor: {
        include: {
          user: { select: { firstName: true, lastName: true, avatarUrl: true } },
        },
      },
    },
    orderBy: { updatedAt: 'desc' },
  });

  const prescriptions = consultations
    .filter(c => c.prescription)
    .map(c => {
      const presc = c.prescription || {};
      return {
        ...presc,
        qrData: JSON.stringify({
          id:             presc.id,
          hash:           presc.hash,
          consultationId: c.id,
          verify:         `https://flashdoc.cm/verify/${presc.hash}`,
        }),
        doctor: {
          firstName:  c.doctor?.user?.firstName || '',
          lastName:   c.doctor?.user?.lastName  || '',
          speciality: c.doctor?.speciality      || '',
          avatarUrl:  c.doctor?.user?.avatarUrl || null,
        },
      };
    });

  return response.success(res, { prescriptions });
}));

// ── GET /api/prescriptions/verify/:hash ───────────────────────────
// Vérification publique de l'authenticité d'une ordonnance via QR code
router.get('/verify/:hash', asyncHandler(async (req, res) => {
  const { hash } = req.params;

  const consultation = await prisma.consultation.findFirst({
    where: { prescription: { path: ['hash'], equals: hash } },
    include: {
      doctor: {
        include: { user: { select: { firstName: true, lastName: true } } },
      },
    },
  });

  if (!consultation?.prescription) {
    return response.error(res, 'Ordonnance introuvable ou invalide', 404);
  }

  const presc = consultation.prescription;
  return response.success(res, {
    valid:   true,
    hash,
    issuedAt: presc.issuedAt,
    doctor:   `Dr. ${consultation.doctor?.user?.firstName} ${consultation.doctor?.user?.lastName}`,
  }, 'Ordonnance authentique ✓');
}));

module.exports = router;
