const { createClient } = require('redis');
const logger = require('../utils/logger');

let client;

async function connectRedis() {
  client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });

  client.on('error', (err) => logger.error('Redis erreur :', err));
  client.on('connect', () => logger.info('✅ Redis connecté'));

  await client.connect();
  return client;
}

function getRedis() {
  if (!client) throw new Error('Redis non initialisé — appeler connectRedis() d\'abord');
  return client;
}

module.exports = { connectRedis, getRedis };
