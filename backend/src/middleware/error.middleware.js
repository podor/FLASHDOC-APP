const logger = require('../utils/logger');
const response = require('../utils/response');

// Erreurs Prisma connues
const PRISMA_ERRORS = {
  P2002: 'Cette valeur existe déjà (doublon).',
  P2025: 'Enregistrement introuvable.',
  P2003: 'Référence invalide (clé étrangère).',
};

function errorHandler(err, req, res, next) {
  logger.error(`${req.method} ${req.path} — ${err.message}`);

  // Erreurs Prisma
  if (err.code && PRISMA_ERRORS[err.code]) {
    return response.badRequest(res, PRISMA_ERRORS[err.code]);
  }

  // Erreurs JWT
  if (err.name === 'JsonWebTokenError') {
    return response.unauthorized(res, 'Token invalide.');
  }
  if (err.name === 'TokenExpiredError') {
    return response.unauthorized(res, 'Session expirée, veuillez vous reconnecter.');
  }

  // Erreur CORS
  if (err.message && err.message.includes('CORS')) {
    return response.forbidden(res, 'Origine non autorisée.');
  }

  // Erreur générique
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Une erreur interne est survenue.'
    : err.message;

  return response.error(res, message, statusCode);
}

// Wrapper async pour éviter try/catch partout dans les controllers
function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

module.exports = { errorHandler, asyncHandler };
