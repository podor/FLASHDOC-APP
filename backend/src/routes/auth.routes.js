const express  = require('express');
const { body } = require('express-validator');
const router   = express.Router();
const ctrl     = require('../controllers/auth.controller');
const { validate } = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const rateLimit = require('express-rate-limit');

// Rate limiting strict sur les routes auth
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: 'Trop de tentatives, réessayez dans 15 minutes.' },
});

// POST /api/auth/register
router.post('/register',
  authLimiter,
  [
    body('phone').matches(/^\+237[6-9]\d{8}$/).withMessage('Numéro camerounais invalide (+237XXXXXXXXX)'),
    body('password').isLength({ min: 8 }).withMessage('Mot de passe minimum 8 caractères'),
    body('firstName').trim().notEmpty().withMessage('Prénom requis'),
    body('lastName').trim().notEmpty().withMessage('Nom requis'),
    body('role').optional().isIn(['PATIENT', 'DOCTOR']).withMessage('Rôle invalide'),
    body('email').optional().isEmail().withMessage('Email invalide'),
  ],
  validate,
  ctrl.register
);

// POST /api/auth/verify-otp
router.post('/verify-otp',
  authLimiter,
  [
    body('phone').notEmpty().withMessage('Téléphone requis'),
    body('code').isLength({ min: 6, max: 6 }).withMessage('Code OTP 6 chiffres'),
  ],
  validate,
  ctrl.verifyOtp
);

// POST /api/auth/resend-otp
router.post('/resend-otp',
  authLimiter,
  [body('phone').notEmpty()],
  validate,
  ctrl.resendOtp
);

// POST /api/auth/login
router.post('/login',
  authLimiter,
  [
    body('phone').notEmpty().withMessage('Téléphone requis'),
    body('password').notEmpty().withMessage('Mot de passe requis'),
  ],
  validate,
  ctrl.login
);

// POST /api/auth/refresh
router.post('/refresh',
  [body('refreshToken').notEmpty()],
  validate,
  ctrl.refresh
);

// GET /api/auth/me — Profil de l'utilisateur connecté
router.get('/me', authenticate, ctrl.me);

module.exports = router;
