const jwt      = require('jsonwebtoken');
const prisma   = require('../config/database');
const response = require('../utils/response');

// Vérifie le token JWT et attache req.user
async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return response.unauthorized(res, 'Token manquant.');
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true, phone: true, email: true,
        role: true, status: true,
        firstName: true, lastName: true, avatarUrl: true,
      },
    });

    if (!user) return response.unauthorized(res, 'Utilisateur introuvable.');
    if (user.status === 'SUSPENDED') return response.forbidden(res, 'Compte suspendu.');
    if (user.status === 'BANNED')    return response.forbidden(res, 'Compte radié.');
    if (user.status === 'PENDING')   return response.forbidden(res, 'Compte non vérifié.');

    req.user = user;
    next();
  } catch (err) {
    next(err); // JWT errors remontés au errorHandler
  }
}

// Middleware de rôle — ex: requireRole('ADMIN') ou requireRole('DOCTOR', 'ADMIN')
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return response.unauthorized(res);
    if (!roles.includes(req.user.role)) {
      return response.forbidden(res, `Accès réservé aux : ${roles.join(', ')}`);
    }
    next();
  };
}

// Middleware spécifique : vérifie que le médecin est APPROVED
async function requireApprovedDoctor(req, res, next) {
  if (req.user.role !== 'DOCTOR') return response.forbidden(res, 'Réservé aux médecins.');

  const doctor = await prisma.doctor.findUnique({ where: { userId: req.user.id } });
  if (!doctor || doctor.status !== 'APPROVED') {
    return response.forbidden(res, 'Votre dossier médecin n\'est pas encore approuvé.');
  }
  req.doctor = doctor;
  next();
}

module.exports = { authenticate, requireRole, requireApprovedDoctor };
