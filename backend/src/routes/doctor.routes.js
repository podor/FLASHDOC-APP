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

// POST /api/doctors/apply — Soumettre dossier d'affiliation (onboarding app)
// POST /api/doctors/register — Alias
const applyValidation = [
  body('speciality').notEmpty().withMessage('Spécialité requise'),
  body('onmcNumber').notEmpty().withMessage('Numéro ONMC requis'),
  body('city').optional().isString(),
  body('experience').optional().isInt({ min: 0 }),
  body('languages').optional().isArray(),
  body('bio').optional().isLength({ max: 1000 }),
  body('hospital').optional().isString(),
  body('availableDays').optional(),
  body('startTime').optional().isString(),
  body('endTime').optional().isString(),
  body('consultationsPerDay').optional().isInt({ min: 1 }),
];

router.post('/apply',    requireRole('DOCTOR'), applyValidation, validate, ctrl.applyDoctor);
router.post('/register', requireRole('DOCTOR'), applyValidation, validate, ctrl.applyDoctor);

// GET /api/doctors/application/status — Statut du dossier
router.get('/application/status', requireRole('DOCTOR'), ctrl.getApplicationStatus);

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
