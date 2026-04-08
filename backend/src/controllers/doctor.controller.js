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

// POST /api/doctors/apply — Soumission dossier d'affiliation médecin (onboarding complet)
const applyDoctor = asyncHandler(async (req, res) => {
  const {
    speciality, onmcNumber, bio, city, languages,
    hospital, experience, availableDays, startTime, endTime, consultationsPerDay,
  } = req.body;

  // Vérifier si un dossier existe déjà
  // ✅ Autoriser la mise à jour même si APPROVED (modification du profil)
  // Bloquer uniquement si SUSPENDED ou BANNED
  const existing = await prisma.doctor.findUnique({ where: { userId: req.user.id } });
  if (existing && ['SUSPENDED', 'BANNED'].includes(existing.status)) {
    return response.badRequest(res, `Compte ${existing.status === 'SUSPENDED' ? 'suspendu' : 'radié'}. Contactez le support.`);
  }

  // Déterminer le nouveau statut
  // Si déjà APPROVED, garder APPROVED (mise à jour du profil)
  // Sinon passer à PENDING_REVIEW
  const newStatus = (existing?.status === 'APPROVED') ? 'APPROVED' : 'PENDING_REVIEW';

  const doctor = await prisma.doctor.upsert({
    where:  { userId: req.user.id },
    update: {
      speciality, onmcNumber, bio, city,
      languages: languages || ['fr'],
      status: newStatus,
    },
    create: {
      userId: req.user.id,
      speciality, onmcNumber, bio, city,
      languages: languages || ['fr'],
      status: 'PENDING_REVIEW',
    },
  });

  const msg = newStatus === 'APPROVED'
    ? 'Profil mis à jour avec succès.'
    : 'Dossier soumis avec succès. Notre équipe va vérifier vos documents sous 24-48h.';

  return response.success(res, { doctor }, msg);
});

// GET /api/doctors/application/status — Statut du dossier du médecin connecté
const getApplicationStatus = asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.findUnique({
    where: { userId: req.user.id },
    select: {
      id: true, status: true, speciality: true, onmcNumber: true,
      createdAt: true, updatedAt: true,
    },
  });

  if (!doctor) {
    return response.success(res, { status: 'NOT_SUBMITTED', message: 'Aucun dossier soumis.' });
  }

  const statusMessages = {
    PENDING_DOCS:      'Documents manquants — veuillez compléter votre dossier.',
    PENDING_REVIEW:    'Dossier en cours d\'examen par notre équipe (24-48h).',
    PENDING_INTERVIEW: 'Dossier validé — en attente de votre interview vidéo.',
    APPROVED:          'Félicitations ! Votre compte est actif.',
    SUSPENDED:         'Compte suspendu temporairement. Contactez le support.',
    BANNED:            'Compte radié de la plateforme.',
  };

  return response.success(res, {
    status: doctor.status,
    message: statusMessages[doctor.status] || doctor.status,
    doctorId: doctor.id,
    submittedAt: doctor.createdAt,
    updatedAt: doctor.updatedAt,
  });
});

// POST /api/doctors/register — Alias (ancien nom)
const registerDoctor = applyDoctor;

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

module.exports = { getAll, getById, getMe, updateMe, applyDoctor, registerDoctor, getApplicationStatus, getWallet, getMyConsultations };
