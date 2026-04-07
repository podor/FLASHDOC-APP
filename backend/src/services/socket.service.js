const { Server } = require('socket.io');
const jwt        = require('jsonwebtoken');
const prisma     = require('../config/database');
const { getRedis } = require('../config/redis');
const logger     = require('../utils/logger');

let io;

const REDIS_KEYS = {
  doctorOnline:   (id) => `doctor:online:${id}`,
  pendingRequest: (id) => `consultation:pending:${id}`,
  room:           (id) => `room:${id}`,
};

function initSocket(server) {
  io = new Server(server, {
    cors: {
      origin: (process.env.ALLOWED_ORIGINS || '').split(','),
      credentials: true,
    },
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) return next(new Error('Token manquant'));
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: { id: true, role: true, firstName: true, lastName: true, status: true },
      });
      if (!user || user.status !== 'ACTIVE') return next(new Error('Non autorisé'));
      socket.user = user;
      next();
    } catch (err) {
      next(new Error('Token invalide'));
    }
  });

  io.on('connection', async (socket) => {
    const { user } = socket;
    logger.info(`🔌 Socket connecté : ${user.firstName} ${user.lastName} (${user.role}) — ${socket.id}`);

    socket.join(`user:${user.id}`);

    if (user.role === 'DOCTOR') {
      socket.on('doctor:available', async () => {
        const redis = getRedis();
        await redis.set(REDIS_KEYS.doctorOnline(user.id), socket.id, { EX: 3600 });
        await prisma.doctor.update({ where: { userId: user.id }, data: { isAvailable: true } });
        socket.join('doctors:available');
        logger.info(`🟢 Médecin disponible : ${user.firstName} ${user.lastName}`);
        socket.emit('doctor:status', { available: true });
      });

      socket.on('doctor:unavailable', async () => {
        await setDoctorUnavailable(user.id);
        socket.leave('doctors:available');
        socket.emit('doctor:status', { available: false });
      });

      socket.on('consultation:accept', async ({ consultationId }) => {
        await handleDoctorAccept(socket, user, consultationId);
      });
    }

    socket.on('consultation:join', async ({ consultationId }) => {
      const consultation = await prisma.consultation.findUnique({ where: { id: consultationId } });
      if (!consultation) return socket.emit('error', { message: 'Consultation introuvable' });

      const isParticipant =
        (user.role === 'PATIENT' && consultation.patientId === (await getPatientId(user.id))) ||
        (user.role === 'DOCTOR'  && consultation.doctorId  === (await getDoctorId(user.id)));

      if (!isParticipant) return socket.emit('error', { message: 'Accès refusé' });

      const room = `consultation:${consultationId}`;
      socket.join(room);
      logger.info(`📞 ${user.firstName} a rejoint la room ${room}`);
      socket.to(room).emit('participant:joined', { userId: user.id, role: user.role });
    });

    // ── DÉMARRAGE CONSULTATION ─────────────────────────────────────
    // ✅ Le premier qui appuie sur "Démarrer" déclenche la navigation des deux
    socket.on('consultation:start', async ({ consultationId }) => {
      try {
        const redis = getRedis();
        const lockKey = `start:consultation:${consultationId}`;

        // Lock atomique — seul le premier appel passe
        const locked = await redis.set(lockKey, user.id, { NX: true, EX: 30 });
        if (!locked) {
          // Déjà démarré par l'autre — ne rien faire (l'événement est déjà parti)
          logger.info(`⚡ Consultation ${consultationId} déjà démarrée`);
          return;
        }

        // Mettre à jour le statut en DB
        await prisma.consultation.update({
          where: { id: consultationId },
          data: { status: 'IN_PROGRESS', startedAt: new Date() },
        }).catch(() => {}); // Ignorer si déjà IN_PROGRESS

        logger.info(`🚀 ${user.firstName} a démarré la consultation ${consultationId}`);

        // ✅ Envoyer consultation:started à TOUS les membres de la room
        // (y compris l'expéditeur via io.to)
        io.to(`consultation:${consultationId}`).emit('consultation:started', {
          consultationId,
          startedBy: user.role,
        });
      } catch (err) {
        logger.error(`Erreur démarrage consultation: ${err.message}`);
      }
    });

    // ── MESSAGE CHAT ─────────────────────────────────────────────
    socket.on('message:send', async ({ consultationId, content, fileUrl }) => {
      const sender = user.role === 'PATIENT' ? 'PATIENT' : 'DOCTOR';
      const msg = await prisma.message.create({
        data: { consultationId, sender, content, fileUrl },
      });
      socket.to(`consultation:${consultationId}`).emit('message:new', msg);
      socket.emit('message:sent', { localId: fileUrl, ...msg });
    });

    socket.on('webrtc:signal', ({ consultationId, signal }) => {
      socket.to(`consultation:${consultationId}`).emit('webrtc:signal', { signal, from: user.id });
    });

    socket.on('disconnect', async () => {
      logger.info(`🔴 Socket déconnecté : ${user.firstName} ${user.lastName}`);
      if (user.role === 'DOCTOR') await setDoctorUnavailable(user.id);
    });
  });

  logger.info('✅ Socket.io initialisé');
  return io;
}

async function dispatchConsultation(consultation) {
  if (!io) return;
  logger.info(`📡 Dispatch consultation ${consultation.id} aux médecins disponibles`);

  io.to('doctors:available').emit('consultation:new_request', {
    id:           consultation.id,
    speciality:   consultation.speciality,
    mode:         consultation.mode,
    symptomsText: consultation.symptomsText,
    amount:       consultation.totalAmount,
  });

  const timeout = parseInt(process.env.DISPATCH_TIMEOUT_SECONDS || '60') * 1000;
  setTimeout(async () => {
    const current = await prisma.consultation.findUnique({ where: { id: consultation.id } });
    if (current && current.status === 'WAITING_DOCTOR') {
      await prisma.consultation.update({ where: { id: consultation.id }, data: { status: 'EXPIRED' } });
      io.to(`user:${await getUserIdFromPatient(consultation.patientId)}`).emit(
        'consultation:expired',
        { consultationId: consultation.id, message: 'Aucun médecin disponible. Vous serez remboursé.' }
      );
      logger.warn(`⚠️ Consultation ${consultation.id} expirée — aucun médecin`);
    }
  }, timeout);
}

async function handleDoctorAccept(socket, user, consultationId) {
  const redis = getRedis();
  const lockKey = `lock:consultation:${consultationId}`;
  const locked = await redis.set(lockKey, user.id, { NX: true, EX: 30 });
  if (!locked) { socket.emit('consultation:already_taken', { consultationId }); return; }

  try {
    const consultation = await prisma.consultation.findUnique({ where: { id: consultationId } });
    if (!consultation || consultation.status !== 'WAITING_DOCTOR') {
      socket.emit('consultation:already_taken', { consultationId }); return;
    }

    const doctor = await prisma.doctor.findUnique({ where: { userId: user.id } });
    const COMMISSION = parseFloat(process.env.PLATFORM_COMMISSION_RATE || '0.25');
    const doctorAmount = consultation.totalAmount * (1 - COMMISSION);

    await prisma.consultation.update({
      where: { id: consultationId },
      data: { doctorId: doctor.id, status: 'MATCHED', platformFee: consultation.totalAmount * COMMISSION, doctorAmount },
    });

    const patientUserId = await getUserIdFromPatient(consultation.patientId);

    io.to(`user:${patientUserId}`).emit('consultation:matched', {
      consultationId,
      doctor: { id: doctor.id, firstName: user.firstName, lastName: user.lastName, speciality: doctor.speciality, averageRating: doctor.averageRating },
    });

    io.to('doctors:available').emit('consultation:request_taken', { consultationId });
    socket.emit('consultation:accepted_confirmed', { consultationId });
    logger.info(`✅ Consultation ${consultationId} matchée avec Dr. ${user.lastName}`);
  } finally {
    await redis.del(lockKey);
  }
}

async function setDoctorUnavailable(userId) {
  const redis = getRedis();
  await redis.del(REDIS_KEYS.doctorOnline(userId));
  await prisma.doctor.update({ where: { userId }, data: { isAvailable: false } }).catch(() => {});
}

async function getPatientId(userId) {
  const p = await prisma.patient.findUnique({ where: { userId }, select: { id: true } });
  return p?.id;
}

async function getDoctorId(userId) {
  const d = await prisma.doctor.findUnique({ where: { userId }, select: { id: true } });
  return d?.id;
}

async function getUserIdFromPatient(patientId) {
  const p = await prisma.patient.findUnique({ where: { id: patientId }, select: { userId: true } });
  return p?.userId;
}

function getIO() {
  if (!io) throw new Error('Socket.io non initialisé');
  return io;
}

module.exports = { initSocket, getIO, dispatchConsultation };
