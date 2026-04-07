const authService = require('../services/auth.service');
const response    = require('../utils/response');
const { asyncHandler } = require('../middleware/error.middleware');

// POST /api/auth/register
const register = asyncHandler(async (req, res) => {
  const { phone, password, firstName, lastName, role, email } = req.body;
  const user = await authService.register({ phone, password, firstName, lastName, role, email });
  return response.created(res, { user }, 'Compte créé. Un code OTP a été envoyé par SMS.');
});

// POST /api/auth/verify-otp
const verifyOtp = asyncHandler(async (req, res) => {
  const { phone, code } = req.body;
  const data = await authService.verifyOtp(phone, code);
  return response.success(res, data, 'Compte vérifié avec succès.');
});

// POST /api/auth/resend-otp
const resendOtp = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const user = await require('../config/database').user.findUnique({ where: { phone } });
  if (!user) return response.notFound(res, 'Numéro introuvable.');
  await authService.sendOtp(user.id, phone);
  return response.success(res, {}, 'Code OTP renvoyé.');
});

// POST /api/auth/login
const login = asyncHandler(async (req, res) => {
  const { phone, password } = req.body;
  const data = await authService.login({ phone, password });
  return response.success(res, data, 'Connexion réussie.');
});

// POST /api/auth/refresh
const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return response.badRequest(res, 'Refresh token manquant.');
  const data = await authService.refreshToken(refreshToken);
  return response.success(res, data);
});

// GET /api/auth/me
const me = asyncHandler(async (req, res) => {
  return response.success(res, { user: req.user });
});

module.exports = { register, verifyOtp, resendOtp, login, refresh, me };
