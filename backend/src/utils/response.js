// Réponses API standardisées — toujours le même format pour le frontend
const response = {
  success: (res, data = {}, message = 'Succès', statusCode = 200) => {
    return res.status(statusCode).json({ success: true, message, data });
  },

  created: (res, data = {}, message = 'Créé avec succès') => {
    return res.status(201).json({ success: true, message, data });
  },

  error: (res, message = 'Erreur serveur', statusCode = 500, errors = null) => {
    const body = { success: false, message };
    if (errors) body.errors = errors;
    return res.status(statusCode).json(body);
  },

  notFound: (res, message = 'Ressource introuvable') => {
    return res.status(404).json({ success: false, message });
  },

  unauthorized: (res, message = 'Non autorisé') => {
    return res.status(401).json({ success: false, message });
  },

  forbidden: (res, message = 'Accès refusé') => {
    return res.status(403).json({ success: false, message });
  },

  badRequest: (res, message = 'Requête invalide', errors = null) => {
    const body = { success: false, message };
    if (errors) body.errors = errors;
    return res.status(400).json(body);
  },
};

module.exports = response;
