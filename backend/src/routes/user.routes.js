const express  = require('express');
const router   = express.Router();
const path     = require('path');
const fs       = require('fs');
const multer   = require('multer');
const prisma   = require('../config/database');
const response = require('../utils/response');
const { authenticate } = require('../middleware/auth.middleware');
const { asyncHandler } = require('../middleware/error.middleware');

router.use(authenticate);

// ── Config multer — stockage local ─────────────────────────────
const uploadDir = path.join(process.env.UPLOAD_PATH || './uploads', 'avatars');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `avatar_${req.user.id}_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Format non supporté. Utilisez JPG, PNG ou WebP.'));
  },
});

// ── POST /api/users/me/avatar ────────────────────────────────────
router.post('/me/avatar', upload.single('avatar'), asyncHandler(async (req, res) => {
  if (!req.file) {
    return response.error(res, 'Aucun fichier reçu', 400);
  }

  // URL publique de l'avatar
  const baseUrl  = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
  const avatarUrl = `${baseUrl}/uploads/avatars/${req.file.filename}`;

  // Supprimer l'ancien avatar si existant
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: { avatarUrl: true },
  });

  if (user?.avatarUrl) {
    const oldFile = user.avatarUrl.split('/uploads/avatars/').pop();
    const oldPath = path.join(uploadDir, oldFile || '');
    if (oldFile && fs.existsSync(oldPath)) {
      fs.unlinkSync(oldPath);
    }
  }

  // Mettre à jour l'avatarUrl en base
  await prisma.user.update({
    where: { id: req.user.id },
    data:  { avatarUrl },
  });

  return response.success(res, { avatarUrl }, 'Photo de profil mise à jour');
}));

// ── GET /api/users/me ────────────────────────────────────────────
router.get('/me', asyncHandler(async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: {
      id: true, firstName: true, lastName: true,
      email: true, phone: true, avatarUrl: true, role: true,
    },
  });
  return response.success(res, { user });
}));

module.exports = router;
