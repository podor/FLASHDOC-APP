require('dotenv').config();
const http   = require('http');
const app    = require('./app');
const { initSocket } = require('./services/socket.service');
const { connectRedis } = require('./config/redis');
const logger = require('./utils/logger');

const PORT = process.env.PORT || 3000;
// ⚠️ Écouter sur 0.0.0.0 pour être accessible depuis le réseau local (téléphone)
const HOST = '0.0.0.0';

async function startServer() {
  await connectRedis();

  const server = http.createServer(app);
  initSocket(server);

  server.listen(PORT, HOST, () => {
    logger.info(`🚀 FlashDoc API démarrée sur http://${HOST}:${PORT}`);
    logger.info(`📱 Accessible depuis le téléphone : http://192.168.0.54:${PORT}/api/health`);
    logger.info(`📡 Environnement : ${process.env.NODE_ENV}`);
  });

  const shutdown = async (signal) => {
    logger.info(`${signal} reçu — arrêt propre...`);
    server.close(() => {
      logger.info('Serveur HTTP fermé');
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT',  () => shutdown('SIGINT'));
}

startServer().catch((err) => {
  logger.error('Erreur démarrage serveur :', err);
  process.exit(1);
});
