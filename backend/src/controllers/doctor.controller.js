const prisma   = require('../config/database');
const response = require('../utils/response');
const { asyncHandler } = require('../middleware/error.middleware');

// GET /api/doctors — Liste des médecins approuvés
const getAll = asyncHandler(async (req, res) => {
  const { speciality, city, available } = req.query;

  const doctors = await prisma.doctor.findMany({
    where: {
      status: 'APPROVED',
      ...(speciality && { speciality }),
      ...(city       && { city }),
      ...(available  && { isAvailable: available === 'true' }),
    },
    include: {
      user: { select: { firstName: true, lastName: true, avatarUrl: true } },
    },
    orderBy: { averageRating: 'desc' },
  });

  return response.success(res, { doctors });
});

// GET /api/doctors/:id
const getById = asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.findUnique({
    where: { id: req.params.id },
    include: {
      user:    { select: { firstName: true, lastName: true, avatarUrl: true, email: true } },
      ratings: { orderBy: { createdAt: 'desc' }, take: 10 },
      schedules: true,
    },
  });
  if (!doctor || doctor.status !== 'APPROVED') return response.notFound(res, 'Médecin introuvable.');
  return response.success(res, { doctor });
});

// GET /api/doctors/me — Profil du médecin connecté
const getMe = asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.findUnique({
    where:   { userId: req.user.id },
    include: { user: { select: { firstName: true, lastName: true, avatarUrl: true, email: true, phone: true } } },
  });
  if (!doctor) return response.notFound(res, 'Profil médecin introuvable.');
  return response.success(res, { doctor });
});

// PUT /api/doctors/me — Mise à jour profil médecin
const updateMe = asyncHandler(async (req, res) => {
  const { bio, city, languages, speciality, schedules } = req.body;

  const doctor = await prisma.doctor.update({
    where: { userId: req.user.id },
    data: {
      ...(bio        && { bio }),
      ...(city       && { city }),
      ...(languages  && { languages }),
      ...(speciality && { speciality }),
    },
  });

  // Mise à jour des plages horaires
  if (schedules && Array.isArray(schedules)) {
    await prisma.schedule.deleteMany({ where: { doctorId: doctor.id } });
    await prisma.schedule.createMany({
      data: schedules.map((s) => ({ ...s, doctorId: doctor.id })),
    });
  }

  return response.success(res, { doctor }, 'Profil mis à jour.');
});

// POST /api/doctors/register — Soumission dossier d'affiliation médecin
const registerDoctor = asyncHandler(async (req, res) => {
  const { speciality, onmcNumber, bio, city, languages } = req.body;

  const existing = await prisma.doctor.findUnique({ where: { userId: req.user.id } });
  if (existing && existing.status !== 'PENDING_DOCS') {
    return response.badRequest(res, 'Dossier déjà soumis.');
  }

  const doctor = await prisma.doctor.upsert({
    where:  { userId: req.user.id },
    update: { speciality, onmcNumber, bio, city, languages, status: 'PENDING_REVIEW' },
    create: { userId: req.user.id, speciality, onmcNumber, bio, city, languages: languages || ['fr'], status: 'PENDING_REVIEW' },
  });

  return response.success(res, { doctor }, 'Dossier soumis. Vérification ONMC en cours.');
});

// GET /api/doctors/me/wallet — Wallet et historique du médecin
const getWallet = asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.findUnique({
    where: { userId: req.user.id },
    select: { walletBalance: true },
  });
  if (!doctor) return response.notFound(res);

  const transactions = await prisma.transaction.findMany({
    where:   { doctorId: doctor.id },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });

  return response.success(res, { balance: doctor.walletBalance, transactions });
});

// GET /api/doctors/me/consultations — Consultations du médecin
const getMyConsultations = asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.findUnique({ where: { userId: req.user.id } });
  if (!doctor) return response.notFound(res);

  const consultations = await prisma.consultation.findMany({
    where:   { doctorId: doctor.id },
    include: {
      patient: { include: { user: { select: { firstName: true, lastName: true } } } },
      rating:  true,
    },
    orderBy: { createdAt: 'desc' },
  });

  return response.success(res, { consultations });
});

module.exports = { getAll, getById, getMe, updateMe, registerDoctor, getWallet, getMyConsultations };
