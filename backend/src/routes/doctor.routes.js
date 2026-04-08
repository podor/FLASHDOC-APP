const express  = require('express');
const { body } = require('express-validator');
const router   = express.Router();
const path     = require('path');
const fs       = require('fs');
const multer   = require('multer');
const ctrl     = require('../controllers/doctor.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validate.middleware');
const { asyncHandler } = require('../middleware/error.middleware');
const prisma   = require('../config/database');
const response = require('../utils/response');

// ── Config multer pour documents médecin ───────────────────────
const docsDir = process.env.UPLOAD_PATH
  ? process.env.UPLOAD_PATH.replace('avatars', 'doctor-docs')
  : './uploads/doctor-docs';
if (!fs.existsSync(docsDir)) fs.mkdirSync(docsDir, { recursive: true });

const docStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, docsDir),
  filename: (req, file, cb) => {
    const ext  = path.extname(file.originalname) || '.jpg';
    const type = file.fieldname; // diplome, onmc, specialite, cni, selfie
    cb(null, `${type}_${req.user.id}_${Date.now()}${ext}`);
  },
});

const uploadDocs = multer({
  storage: docStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Format non supporté. Utilisez JPG, PNG, WebP ou PDF.'));
  },
});

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

// POST /api/doctors/me/documents — Upload documents affiliation
// Champs acceptés : diplome, onmc, specialite, cni, selfie
router.post('/me/documents',
  requireRole('DOCTOR'),
  uploadDocs.fields([
    { name: 'diplome',    maxCount: 1 },
    { name: 'onmc',       maxCount: 1 },
    { name: 'specialite', maxCount: 1 },
    { name: 'cni',        maxCount: 1 },
    { name: 'selfie',     maxCount: 1 },
  ]),
  asyncHandler(async (req, res) => {
    const files   = req.files || {};
    const baseUrl = process.env.BASE_URL || 'http://localhost:3000';

    // Construire les URLs des fichiers uploadés
    const urls = {};
    for (const [field, fileArr] of Object.entries(files)) {
      if (fileArr && fileArr[0]) {
        const subdir = docsDir.includes('doctor-docs') ? 'doctor-docs' : 'avatars';
        urls[field] = `${baseUrl}/uploads/${subdir}/${fileArr[0].filename}`;
      }
    }

    if (Object.keys(urls).length === 0) {
      return response.badRequest(res, 'Aucun fichier reçu.');
    }

    // Mapper les champs vers les colonnes Prisma
    const updateData = {};
    if (urls.diplome)    updateData.diplomaUrl  = urls.diplome;
    if (urls.onmc)       updateData.licenseUrl  = urls.onmc;
    if (urls.specialite) updateData.specialtyDiplomaUrl = urls.specialite;

    // Upsert du dossier médecin avec les URLs des documents
    await prisma.doctor.upsert({
      where:  { userId: req.user.id },
      update: updateData,
      create: { userId: req.user.id, speciality: 'Généraliste', ...updateData },
    });

    // Si selfie uploadé → mettre à jour l'avatar de l'utilisateur
    if (urls.selfie) {
      await prisma.user.update({
        where: { id: req.user.id },
        data:  { avatarUrl: urls.selfie },
      });
    }

    return response.success(res, { urls }, 'Documents uploadés avec succès.');
  })
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
