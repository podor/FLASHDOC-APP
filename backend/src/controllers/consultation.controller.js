const prisma   = require('../config/database');
const response = require('../utils/response');
const { asyncHandler } = require('../middleware/error.middleware');
const { dispatchConsultation } = require('../services/socket.service');

// Prix par mode de consultation (en FCFA)
const PRICES = { CHAT: 5000, AUDIO: 8000, VIDEO: 10000 };

// POST /api/consultations — Créer une demande de consultation
const create = asyncHandler(async (req, res) => {
  const { mode, speciality, symptomsText, symptomsImageUrls, type } = req.body;

  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  if (!patient) return response.notFound(res, 'Profil patient introuvable.');

  const totalAmount = PRICES[mode] || PRICES.VIDEO;

  const consultation = await prisma.consultation.create({
    data: {
      patientId:        patient.id,
      mode,
      type:             type || 'IMMEDIATE',
      speciality:       speciality || 'Généraliste',
      symptomsText,
      symptomsImageUrls: symptomsImageUrls || [],
      totalAmount,
      status:           'PENDING_PAYMENT',
    },
  });

  return response.created(res, { consultation, totalAmount }, 'Demande créée. Procédez au paiement.');
});

// GET /api/consultations — Historique du patient
const getMyConsultations = asyncHandler(async (req, res) => {
  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  if (!patient) return response.notFound(res, 'Profil patient introuvable.');

  const consultations = await prisma.consultation.findMany({
    where:   { patientId: patient.id },
    include: {
      doctor: { include: { user: { select: { firstName: true, lastName: true, avatarUrl: true } } } },
      rating: true,
      payment: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  return response.success(res, { consultations });
});

// GET /api/consultations/:id
const getById = asyncHandler(async (req, res) => {
  const consultation = await prisma.consultation.findUnique({
    where:   { id: req.params.id },
    include: {
      doctor:   { include: { user: { select: { firstName: true, lastName: true, avatarUrl: true } } } },
      patient:  { include: { user: { select: { firstName: true, lastName: true } } } },
      messages: { orderBy: { createdAt: 'asc' } },
      payment:  true,
      rating:   true,
    },
  });

  if (!consultation) return response.notFound(res, 'Consultation introuvable.');
  return response.success(res, { consultation });
});

// POST /api/consultations/:id/start — Médecin démarre la consultation
const start = asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.findUnique({ where: { userId: req.user.id } });

  const consultation = await prisma.consultation.findFirst({
    where: { id: req.params.id, doctorId: doctor.id, status: 'MATCHED' },
  });

  if (!consultation) return response.notFound(res, 'Consultation introuvable ou non assignée.');

  const updated = await prisma.consultation.update({
    where: { id: req.params.id },
    data:  { status: 'IN_PROGRESS', startedAt: new Date() },
  });

  return response.success(res, { consultation: updated }, 'Consultation démarrée.');
});

// POST /api/consultations/:id/end — Médecin termine la consultation
const end = asyncHandler(async (req, res) => {
  const { notes, prescriptionUrl } = req.body;
  const doctor = await prisma.doctor.findUnique({ where: { userId: req.user.id } });

  const consultation = await prisma.consultation.findFirst({
    where: { id: req.params.id, doctorId: doctor.id, status: 'IN_PROGRESS' },
  });
  if (!consultation) return response.notFound(res, 'Consultation introuvable.');

  const endedAt = new Date();
  const durationMinutes = Math.round((endedAt - consultation.startedAt) / 60000);

  const updated = await prisma.consultation.update({
    where: { id: req.params.id },
    data: { status: 'COMPLETED', endedAt, durationMinutes, notes, prescriptionUrl },
  });

  // Créditer le wallet du médecin
  await prisma.doctor.update({
    where: { id: doctor.id },
    data: {
      walletBalance: { increment: consultation.doctorAmount || 0 },
      totalConsults: { increment: 1 },
    },
  });

  // Enregistrer la transaction
  await prisma.transaction.create({
    data: {
      doctorId:  doctor.id,
      type:      'CREDIT_CONSULTATION',
      amount:    consultation.doctorAmount || 0,
      status:    'COMPLETED',
      reference: consultation.id,
    },
  });

  return response.success(res, { consultation: updated }, 'Consultation terminée.');
});

// POST /api/consultations/:id/rate — Patient note le médecin
const rate = asyncHandler(async (req, res) => {
  const { score, comment } = req.body;
  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });

  // ✅ Autoriser la notation si consultation IN_PROGRESS ou COMPLETED
  const consultation = await prisma.consultation.findFirst({
    where: { id: req.params.id, patientId: patient.id,
      status: { in: ['IN_PROGRESS', 'COMPLETED'] } },
  });
  if (!consultation) return response.notFound(res, 'Consultation introuvable ou non terminée.');

  const rating = await prisma.rating.upsert({
    where:  { consultationId: consultation.id },
    update: { score, comment },
    create: { consultationId: consultation.id, doctorId: consultation.doctorId, score, comment },
  });

  // Recalculer la note moyenne du médecin
  const avg = await prisma.rating.aggregate({
    where:   { doctorId: consultation.doctorId },
    _avg:    { score: true },
    _count:  true,
  });

  await prisma.doctor.update({
    where: { id: consultation.doctorId },
    data:  { averageRating: Math.round((avg._avg.score || 0) * 10) / 10 },
  });

  return response.success(res, { rating }, 'Merci pour votre évaluation.');
});

// Consultation activée après paiement — appelé depuis payment.service
async function activateAfterPayment(consultationId) {
  const consultation = await prisma.consultation.update({
    where: { id: consultationId },
    data:  { status: 'WAITING_DOCTOR' },
  });
  await dispatchConsultation(consultation);
  return consultation;
}

module.exports = { create, getMyConsultations, getById, start, end, rate, activateAfterPayment };
