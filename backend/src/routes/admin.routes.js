const express  = require('express');
const router   = express.Router();
const prisma   = require('../config/database');
const response = require('../utils/response');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

// Toutes les routes admin nécessitent auth + rôle ADMIN
router.use(authenticate, requireRole('ADMIN'));

// ── GET /api/admin/stats ──────────────────────────────────────
router.get('/stats', asyncHandler(async (req, res) => {
  const [totalUsers, totalDoctors, totalConsultations, pendingDoctors, totalRevenue] = await Promise.all([
    prisma.user.count(),
    prisma.doctor.count({ where: { status: 'APPROVED' } }),
    prisma.consultation.count({ where: { status: 'COMPLETED' } }),
    prisma.doctor.count({ where: { status: { in: ['PENDING_REVIEW', 'PENDING_INTERVIEW'] } } }),
    prisma.payment.aggregate({ where: { status: 'SUCCESS' }, _sum: { amount: true } }),
  ]);
  return response.success(res, {
    totalUsers, totalDoctors, totalConsultations,
    pendingDoctors, totalRevenue: totalRevenue._sum.amount || 0,
  });
}));

// ── GET /api/admin/dashboard (alias stats) ───────────────────
router.get('/dashboard', asyncHandler(async (req, res) => {
  const [totalUsers, totalDoctors, totalConsultations, pendingDoctors, totalRevenue] = await Promise.all([
    prisma.user.count(),
    prisma.doctor.count({ where: { status: 'APPROVED' } }),
    prisma.consultation.count({ where: { status: 'COMPLETED' } }),
    prisma.doctor.count({ where: { status: { in: ['PENDING_REVIEW', 'PENDING_INTERVIEW'] } } }),
    prisma.payment.aggregate({ where: { status: 'SUCCESS' }, _sum: { amount: true } }),
  ]);
  return response.success(res, {
    totalUsers, totalDoctors, totalConsultations,
    pendingDoctors, totalRevenue: totalRevenue._sum.amount || 0,
  });
}));

// ── GET /api/admin/doctors ────────────────────────────────────
router.get('/doctors', asyncHandler(async (req, res) => {
  const { status } = req.query;
  const doctors = await prisma.doctor.findMany({
    where: status ? { status } : undefined,
    include: {
      user: {
        select: {
          id: true, firstName: true, lastName: true,
          email: true, phone: true, status: true, avatarUrl: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
  return response.success(res, { doctors });
}));

// ── GET /api/admin/doctors/pending ───────────────────────────
router.get('/doctors/pending', asyncHandler(async (req, res) => {
  const doctors = await prisma.doctor.findMany({
    where: { status: { in: ['PENDING_REVIEW', 'PENDING_INTERVIEW'] } },
    include: {
      user: { select: { firstName: true, lastName: true, email: true, phone: true } },
    },
    orderBy: { createdAt: 'asc' },
  });
  return response.success(res, { doctors });
}));

// ── PUT /api/admin/doctors/:id/status ────────────────────────
router.put('/doctors/:id/status', asyncHandler(async (req, res) => {
  const { status, note } = req.body;

  const validStatuses = [
    'PENDING_DOCS', 'PENDING_REVIEW', 'PENDING_INTERVIEW',
    'APPROVED', 'SUSPENDED', 'BANNED',
  ];
  if (!validStatuses.includes(status)) {
    return response.badRequest(res, 'Statut invalide.');
  }

  const updateData = { status };
  if (status === 'SUSPENDED' || status === 'BANNED') {
    updateData.isAvailable = false;
  }

  const doctor = await prisma.doctor.update({
    where: { id: req.params.id },
    data:  updateData,
    include: { user: { select: { firstName: true, lastName: true } } },
  });

  // Mettre à jour le statut user aussi si approuvé ou banni
  if (status === 'APPROVED') {
    await prisma.user.update({
      where: { id: doctor.userId },
      data:  { status: 'ACTIVE' },
    });
  } else if (status === 'BANNED') {
    await prisma.user.update({
      where: { id: doctor.userId },
      data:  { status: 'BANNED' },
    });
  } else if (status === 'SUSPENDED') {
    await prisma.user.update({
      where: { id: doctor.userId },
      data:  { status: 'SUSPENDED' },
    });
  }

  return response.success(res, { doctor },
    `Dr. ${doctor.user.firstName} ${doctor.user.lastName} → ${status}`);
}));

// ── PUT /api/admin/doctors/:id/approve (ancien endpoint) ─────
router.put('/doctors/:id/approve', asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.update({
    where: { id: req.params.id },
    data:  { status: 'APPROVED' },
  });
  await prisma.user.update({ where: { id: doctor.userId }, data: { status: 'ACTIVE' } });
  return response.success(res, { doctor }, 'Médecin approuvé.');
}));

// ── PUT /api/admin/doctors/:id/suspend (ancien endpoint) ─────
router.put('/doctors/:id/suspend', asyncHandler(async (req, res) => {
  const { reason } = req.body;
  const doctor = await prisma.doctor.update({
    where: { id: req.params.id },
    data:  { status: 'SUSPENDED', isAvailable: false },
  });
  return response.success(res, { doctor },
    `Médecin suspendu. Raison : ${reason || 'non précisée'}`);
}));

// ── GET /api/admin/patients ───────────────────────────────────
router.get('/patients', asyncHandler(async (req, res) => {
  const patients = await prisma.patient.findMany({
    include: {
      user: {
        select: {
          id: true, firstName: true, lastName: true,
          email: true, phone: true, status: true, createdAt: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
  return response.success(res, { patients });
}));

// ── GET /api/admin/consultations ──────────────────────────────
router.get('/consultations', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 50 } = req.query;
  const consultations = await prisma.consultation.findMany({
    where:   status ? { status } : undefined,
    include: {
      patient: { include: { user: { select: { firstName: true, lastName: true } } } },
      doctor:  { include: { user: { select: { firstName: true, lastName: true } } } },
    },
    orderBy: { createdAt: 'desc' },
    skip:    (parseInt(page) - 1) * parseInt(limit),
    take:    parseInt(limit),
  });
  return response.success(res, { consultations });
}));

// ── GET /api/admin/payments ───────────────────────────────────
router.get('/payments', asyncHandler(async (req, res) => {
  const payments = await prisma.payment.findMany({
    include: {
      patient: { include: { user: { select: { firstName: true, lastName: true } } } },
    },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  return response.success(res, { payments });
}));

// ── GET /api/admin/specialities ───────────────────────────────
router.get('/specialities', asyncHandler(async (req, res) => {
  const specialities = await prisma.speciality.findMany({ orderBy: { name: 'asc' } });
  return response.success(res, { specialities });
}));

module.exports = router;
