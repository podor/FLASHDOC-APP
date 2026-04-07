const express  = require('express');
const { body } = require('express-validator');
const router   = express.Router();
const ctrl     = require('../controllers/doctor.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validate.middleware');

// GET /api/doctors — Liste publique des médecins approuvés
router.get('/', ctrl.getAll);
router.get('/:id', ctrl.getById);

// Routes protégées
router.use(authenticate);

// POST /api/doctors/register — Soumettre dossier d'affiliation
router.post('/register',
  requireRole('DOCTOR'),
  [
    body('speciality').notEmpty().withMessage('Spécialité requise'),
    body('onmcNumber').notEmpty().withMessage('Numéro ONMC requis'),
    body('city').optional().isString(),
  ],
  validate,
  ctrl.registerDoctor
);

// GET /api/doctors/me/profile
router.get('/me/profile', requireRole('DOCTOR'), ctrl.getMe);

// PUT /api/doctors/me/profile
router.put('/me/profile',
  requireRole('DOCTOR'),
  [
    body('bio').optional().isLength({ max: 500 }),
    body('city').optional().isString(),
  ],
  validate,
  ctrl.updateMe
);

// GET /api/doctors/me/wallet
router.get('/me/wallet', requireRole('DOCTOR'), ctrl.getWallet);

// GET /api/doctors/me/consultations
router.get('/me/consultations', requireRole('DOCTOR'), ctrl.getMyConsultations);

module.exports = router;
