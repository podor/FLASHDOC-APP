const express  = require('express');
const router   = express.Router();
const prisma   = require('../config/database');
const bcrypt   = require('bcryptjs');
const response = require('../utils/response');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

router.use(authenticate, requireRole('PATIENT'));

// ── GET /api/patients/me ──────────────────────────────────────────
router.get('/me', asyncHandler(async (req, res) => {
  const patient = await prisma.patient.findUnique({
    where: { userId: req.user.id },
    include: {
      user: {
        select: {
          firstName: true,
          lastName:  true,
          email:     true,
          phone:     true,
          avatarUrl: true,
          createdAt: true,
        },
      },
    },
  });

  if (!patient) return response.notFound(res, 'Profil patient introuvable');

  // Compter les consultations
  const totalConsultations = await prisma.consultation.count({
    where: { patientId: patient.id },
  });
  const completedConsultations = await prisma.consultation.count({
    where: { patientId: patient.id, status: 'COMPLETED' },
  });

  return response.success(res, {
    patient: {
      ...patient,
      totalConsultations,
      completedConsultations,
    },
  });
}));

// ── PUT /api/patients/me ──────────────────────────────────────────
router.put('/me', asyncHandler(async (req, res) => {
  const {
    // Champs user
    firstName, lastName, email, password,
    // Champs patient
    birthDate, gender, bloodType, city, allergies,
  } = req.body;

  // ── Validation des champs obligatoires ───────────────────────────
  const errors = [];
  if (firstName !== undefined && !firstName?.trim()) {
    errors.push('Le prénom est obligatoire');
  }
  if (lastName !== undefined && !lastName?.trim()) {
    errors.push('Le nom est obligatoire');
  }
  if (email !== undefined) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) errors.push('Email invalide');
  }
  if (password !== undefined && password.length < 8) {
    errors.push('Le mot de passe doit avoir au moins 8 caractères');
  }
  if (errors.length > 0) {
    return response.error(res, errors.join(', '), 400);
  }

  // ── Mise à jour table user ────────────────────────────────────────
  const userData = {};
  if (firstName?.trim()) userData.firstName = firstName.trim();
  if (lastName?.trim())  userData.lastName  = lastName.trim();
  if (email?.trim())     userData.email     = email.trim().toLowerCase();
  if (password)          userData.password  = await bcrypt.hash(password, 10);

  if (Object.keys(userData).length > 0) {
    await prisma.user.update({
      where: { id: req.user.id },
      data:  userData,
    });
  }

  // ── Mise à jour table patient ─────────────────────────────────────
  const patientData = {};
  if (birthDate)  patientData.birthDate = new Date(birthDate);
  if (gender)     patientData.gender    = gender;
  if (bloodType)  patientData.bloodType = bloodType;
  if (city?.trim()) patientData.city   = city.trim();

  // allergies : accepter String ou String[]
  if (allergies !== undefined) {
    if (Array.isArray(allergies)) {
      patientData.allergies = allergies.filter(a => a?.trim());
    } else if (typeof allergies === 'string') {
      patientData.allergies = allergies
        .split(',')
        .map(a => a.trim())
        .filter(a => a.length > 0);
    }
  }

  let patient = null;
  if (Object.keys(patientData).length > 0) {
    patient = await prisma.patient.update({
      where: { userId: req.user.id },
      data:  patientData,
      include: {
        user: {
          select: {
            firstName: true,
            lastName:  true,
            email:     true,
            phone:     true,
            avatarUrl: true,
          },
        },
      },
    });
  } else {
    patient = await prisma.patient.findUnique({
      where: { userId: req.user.id },
      include: {
        user: {
          select: {
            firstName: true,
            lastName:  true,
            email:     true,
            phone:     true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  return response.success(res, { patient }, 'Profil mis à jour avec succès.');
}));

module.exports = router;
