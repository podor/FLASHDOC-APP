const express  = require('express');
const { body, query } = require('express-validator');
const router   = express.Router();
const ctrl     = require('../controllers/consultation.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validate.middleware');

// Toutes les routes nécessitent une authentification
router.use(authenticate);

// POST /api/consultations — Créer une consultation
router.post('/',
  requireRole('PATIENT'),
  [
    body('mode').isIn(['CHAT', 'AUDIO', 'VIDEO']).withMessage('Mode invalide'),
    body('symptomsText').optional().isLength({ max: 1000 }),
    body('speciality').optional().isString(),
  ],
  validate,
  ctrl.create
);

// GET /api/consultations — Mes consultations (patient ou médecin)
router.get('/', ctrl.getMyConsultations);

// GET /api/consultations/:id
router.get('/:id', ctrl.getById);

// POST /api/consultations/:id/start — Médecin démarre
router.post('/:id/start',
  requireRole('DOCTOR'),
  ctrl.start
);

// POST /api/consultations/:id/end — Médecin termine
router.post('/:id/end',
  requireRole('DOCTOR'),
  [
    body('notes').optional().isString(),
    body('prescriptionUrl').optional().isURL(),
  ],
  validate,
  ctrl.end
);

// POST /api/consultations/:id/rate — Patient note le médecin
router.post('/:id/rate',
  requireRole('PATIENT'),
  [
    body('score').isInt({ min: 1, max: 10 }).withMessage('Note entre 1 et 10'),
    body('comment').optional().isLength({ max: 500 }),
  ],
  validate,
  ctrl.rate
);

module.exports = router;
