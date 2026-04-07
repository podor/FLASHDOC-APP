const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const prisma  = require('../config/database');
const { getRedis } = require('../config/redis');
const logger  = require('../utils/logger');

// ── Génération tokens ────────────────────────────────────────────
function generateAccessToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

function generateRefreshToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  });
}

// ── Génération OTP 6 chiffres ────────────────────────────────────
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ── Inscription ──────────────────────────────────────────────────
async function register({ phone, password, firstName, lastName, role, email }) {
  const existing = await prisma.user.findUnique({ where: { phone } });
  if (existing) throw Object.assign(new Error('Ce numéro est déjà utilisé.'), { statusCode: 409 });

  const hashed = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: {
      phone, email, password: hashed,
      firstName, lastName,
      role: role || 'PATIENT',
      status: 'PENDING',
      // Création du profil Patient ou Médecin selon le rôle
      ...(role === 'PATIENT' && { patient: { create: {} } }),
      ...(role === 'DOCTOR'  && { doctor:  { create: { speciality: '', onmcNumber: '' } } }),
    },
    select: { id: true, phone: true, email: true, role: true, firstName: true, lastName: true },
  });

  // Envoi OTP
  await sendOtp(user.id, user.phone);

  return user;
}

// ── Envoi OTP SMS ────────────────────────────────────────────────
async function sendOtp(userId, phone) {
  const code = generateOtp();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  // Invalider les anciens OTP de cet utilisateur
  await prisma.otpCode.updateMany({
    where: { userId, used: false },
    data:  { used: true },
  });

  await prisma.otpCode.create({ data: { userId, code, expiresAt } });

  // TODO: Intégrer le vrai provider SMS (Twilio, CinetPay, etc.)
  // En développement, on log le code
  logger.info(`📱 OTP pour ${phone} : ${code} (expire dans 10 min)`);

  return true;
}

// ── Vérification OTP ─────────────────────────────────────────────
async function verifyOtp(phone, code) {
  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user) throw Object.assign(new Error('Utilisateur introuvable.'), { statusCode: 404 });

  const otp = await prisma.otpCode.findFirst({
    where: {
      userId: user.id,
      code,
      used: false,
      expiresAt: { gt: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!otp) throw Object.assign(new Error('Code OTP invalide ou expiré.'), { statusCode: 400 });

  // Marquer comme utilisé + activer le compte
  await prisma.otpCode.update({ where: { id: otp.id }, data: { used: true } });
  await prisma.user.update({ where: { id: user.id }, data: { status: 'ACTIVE' } });

  const accessToken  = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  return {
    accessToken, refreshToken,
    user: {
      id: user.id, phone: user.phone, email: user.email,
      role: user.role, firstName: user.firstName, lastName: user.lastName,
    },
  };
}

// ── Connexion ────────────────────────────────────────────────────
async function login({ phone, password }) {
  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user) throw Object.assign(new Error('Téléphone ou mot de passe incorrect.'), { statusCode: 401 });

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) throw Object.assign(new Error('Téléphone ou mot de passe incorrect.'), { statusCode: 401 });

  if (user.status === 'PENDING') {
    await sendOtp(user.id, user.phone);
    throw Object.assign(new Error('Compte non vérifié. Un nouveau code OTP a été envoyé.'), { statusCode: 403 });
  }
  if (user.status === 'SUSPENDED') throw Object.assign(new Error('Compte suspendu.'), { statusCode: 403 });
  if (user.status === 'BANNED')    throw Object.assign(new Error('Compte radié.'), { statusCode: 403 });

  const accessToken  = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  return {
    accessToken, refreshToken,
    user: {
      id: user.id, phone: user.phone, email: user.email, role: user.role,
      firstName: user.firstName, lastName: user.lastName, avatarUrl: user.avatarUrl,
    },
  };
}

// ── Refresh token ────────────────────────────────────────────────
async function refreshToken(token) {
  const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
  if (!user || user.status !== 'ACTIVE') throw Object.assign(new Error('Session invalide.'), { statusCode: 401 });

  return { accessToken: generateAccessToken(user.id) };
}

module.exports = { register, login, verifyOtp, sendOtp, refreshToken };
