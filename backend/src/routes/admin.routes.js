const express  = require('express');
const router   = express.Router();
const prisma   = require('../config/database');
const response = require('../utils/response');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

router.use(authenticate, requireRole('ADMIN'));

// GET /api/admin/dashboard
router.get('/dashboard', asyncHandler(async (req, res) => {
  const [totalUsers, totalDoctors, totalConsultations, pendingDoctors, totalRevenue] = await Promise.all([
    prisma.user.count(),
    prisma.doctor.count({ where: { status: 'APPROVED' } }),
    prisma.consultation.count({ where: { status: 'COMPLETED' } }),
    prisma.doctor.count({ where: { status: { in: ['PENDING_REVIEW', 'PENDING_INTERVIEW'] } } }),
    prisma.payment.aggregate({ where: { status: 'SUCCESS' }, _sum: { amount: true } }),
  ]);

  return response.success(res, {
    totalUsers,
    totalDoctors,
    totalConsultations,
    pendingDoctors,
    totalRevenue: totalRevenue._sum.amount || 0,
  });
}));

// GET /api/admin/doctors/pending — Médecins en attente de validation
router.get('/doctors/pending', asyncHandler(async (req, res) => {
  const doctors = await prisma.doctor.findMany({
    where: { status: { in: ['PENDING_REVIEW', 'PENDING_INTERVIEW'] } },
    include: { user: { select: { firstName: true, lastName: true, email: true, phone: true } } },
    orderBy: { createdAt: 'asc' },
  });
  return response.success(res, { doctors });
}));

// PUT /api/admin/doctors/:id/approve — Approuver un médecin
router.put('/doctors/:id/approve', asyncHandler(async (req, res) => {
  const doctor = await prisma.doctor.update({
    where: { id: req.params.id },
    data:  { status: 'APPROVED' },
  });
  await prisma.user.update({ where: { id: doctor.userId }, data: { status: 'ACTIVE' } });
  return response.success(res, { doctor }, 'Médecin approuvé.');
}));

// PUT /api/admin/doctors/:id/suspend
router.put('/doctors/:id/suspend', asyncHandler(async (req, res) => {
  const { reason } = req.body;
  const doctor = await prisma.doctor.update({
    where: { id: req.params.id },
    data:  { status: 'SUSPENDED', isAvailable: false },
  });
  return response.success(res, { doctor }, `Médecin suspendu. Raison : ${reason || 'non précisée'}`);
}));

// GET /api/admin/consultations — Toutes les consultations
router.get('/consultations', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
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

// GET /api/admin/specialities
router.get('/specialities', asyncHandler(async (req, res) => {
  const specialities = await prisma.speciality.findMany({ orderBy: { name: 'asc' } });
  return response.success(res, { specialities });
}));

module.exports = router;
