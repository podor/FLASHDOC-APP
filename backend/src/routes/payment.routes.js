const express  = require('express');
const { body } = require('express-validator');
const router   = express.Router();
const ctrl     = require('../controllers/payment.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validate.middleware');

// POST /api/payments/callback — Webhook OTM (pas d'auth, vient de l'opérateur)
router.post('/callback', ctrl.callback);

// Routes protégées
router.use(authenticate);

// POST /api/payments/initiate — Patient initie un paiement
router.post('/initiate',
  requireRole('PATIENT'),
  [
    body('consultationId').notEmpty().withMessage('ID consultation requis'),
    body('provider').isIn(['ORANGE_MONEY', 'MTN_MOMO']).withMessage('Opérateur invalide'),
    body('phoneNumber').notEmpty().withMessage('Numéro de téléphone requis'),
  ],
  validate,
  ctrl.initiate
);

// GET /api/payments/status/:paymentId
router.get('/status/:paymentId', ctrl.getStatus);

// POST /api/payments/simulate — Dev uniquement
router.post('/simulate',
  requireRole('PATIENT'),
  [body('consultationId').notEmpty()],
  validate,
  ctrl.simulate
);

module.exports = router;
