const { createClient } = require('redis');
const logger = require('../utils/logger');

let client;

async function connectRedis() {
  // ✅ Construire l'URL Redis correctement selon les variables disponibles
  let redisUrl = process.env.REDIS_URL;

  // Si REDIS_URL n'est pas défini mais REDIS_PASSWORD l'est, construire l'URL
  if (!redisUrl && process.env.REDIS_PASSWORD) {
    redisUrl = `redis://:${process.env.REDIS_PASSWORD}@flashdoc_redis:6379`;
  }

  // Fallback sans auth pour le développement local
  if (!redisUrl) {
    redisUrl = 'redis://localhost:6379';
  }

  logger.info(`Redis: connexion vers ${redisUrl.replace(/:([^@]+)@/, ':***@')}`);

  client = createClient({
    url: redisUrl,
    socket: {
      // ✅ Reconnexion avec backoff exponentiel — évite la boucle infinie
      reconnectStrategy: (retries) => {
        if (retries > 20) {
          logger.error('Redis: trop de tentatives, abandon');
          return new Error('Redis max retries reached');
        }
        const delay = Math.min(retries * 500, 5000);
        logger.info(`Redis: reconnexion dans ${delay}ms (tentative ${retries})`);
        return delay;
      },
    },
  });

  client.on('error', (err) => {
    // Log une seule fois par type d'erreur pour ne pas spammer
    logger.error(`Redis erreur : ${err.message}`);
  });

  client.on('connect', () => logger.info('✅ Redis connecté'));
  client.on('reconnecting', () => logger.info('🔄 Redis reconnexion...'));
  client.on('ready', () => logger.info('✅ Redis prêt'));

  try {
    await client.connect();
    // Tester l'authentification
    await client.ping();
    logger.info('✅ Redis ping OK');
  } catch (err) {
    logger.error(`Redis connexion échouée : ${err.message}`);
    // ✅ Ne pas crasher le serveur si Redis échoue — les locks socket seront désactivés
    logger.warn('⚠️  Redis indisponible — les locks de consultation seront désactivés');
  }

  return client;
}

function getRedis() {
  if (!client) throw new Error('Redis non initialisé — appeler connectRedis() d\'abord');
  return client;
}

// ✅ Vérifier si Redis est vraiment connecté avant d'utiliser
function isRedisReady() {
  return client && client.isReady;
}

module.exports = { connectRedis, getRedis, isRedisReady };
