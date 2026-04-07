const { validationResult } = require('express-validator');
const response = require('../utils/response');

// Middleware à placer après les règles express-validator
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return response.badRequest(res, 'Données invalides.', errors.array());
  }
  next();
}

module.exports = { validate };
