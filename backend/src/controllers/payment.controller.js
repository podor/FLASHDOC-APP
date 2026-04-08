const prisma   = require('../config/database');
const response = require('../utils/response');
const { asyncHandler } = require('../middleware/error.middleware');
const { activateAfterPayment } = require('./consultation.controller');
const logger   = require('../utils/logger');

// ── Simulation OTM (à remplacer par les vraies API Orange Money / MTN MoMo)
// En production, ces fonctions appelleront les APIs officielles des opérateurs

// POST /api/payments/initiate — Initier un paiement Mobile Money
const initiate = asyncHandler(async (req, res) => {
  const { consultationId, provider, phoneNumber } = req.body;

  const consultation = await prisma.consultation.findUnique({ where: { id: consultationId } });
  if (!consultation) return response.notFound(res, 'Consultation introuvable.');
  if (consultation.status !== 'PENDING_PAYMENT') {
    return response.badRequest(res, 'Cette consultation n\'attend pas de paiement.');
  }

  // Vérifier que c'est bien le bon patient
  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  if (consultation.patientId !== patient.id) return response.forbidden(res);

  // Créer l'enregistrement paiement
  const payment = await prisma.payment.create({
    data: {
      consultationId,
      patientId: patient.id,
      provider,
      amount:   consultation.totalAmount,
      currency: 'XAF',
      status:   'PENDING',
    },
  });

  // ── Appel API OTM ─────────────────────────────────────────────
  let providerResponse;
  try {
    if (provider === 'ORANGE_MONEY') {
      providerResponse = await initiateOrangeMoney(payment, phoneNumber);
    } else if (provider === 'MTN_MOMO') {
      providerResponse = await initiateMtnMomo(payment, phoneNumber);
    } else {
      return response.badRequest(res, 'Opérateur non supporté. Choisir ORANGE_MONEY ou MTN_MOMO.');
    }
  } catch (err) {
    await prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'FAILED', failureReason: err.message },
    });
    return response.error(res, 'Erreur de paiement : ' + err.message, 502);
  }

  await prisma.payment.update({
    where: { id: payment.id },
    data: { providerRef: providerResponse.reference },
  });

  return response.success(res, {
    paymentId: payment.id,
    reference: providerResponse.reference,
    message:   providerResponse.message,
  }, 'Demande de paiement envoyée. Validez sur votre téléphone.');
});

// POST /api/payments/callback — Webhook OTM (Orange Money / MTN MoMo)
const callback = asyncHandler(async (req, res) => {
  const { reference, status, providerTxId } = req.body;
  logger.info(`💳 Callback paiement reçu : ref=${reference} status=${status}`);

  const payment = await prisma.payment.findFirst({ where: { providerRef: reference } });
  if (!payment) return res.status(200).json({ received: true }); // Toujours 200 pour les webhooks

  if (status === 'SUCCESS') {
    await prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'SUCCESS', providerTxId, paidAt: new Date() },
    });

    // Activer la consultation et déclencher le dispatch
    await activateAfterPayment(payment.consultationId);
    logger.info(`✅ Paiement confirmé — consultation ${payment.consultationId} dispatchée`);

  } else if (status === 'FAILED') {
    await prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'FAILED', failureReason: 'Paiement refusé par l\'opérateur' },
    });
    logger.warn(`❌ Paiement échoué — consultation ${payment.consultationId}`);
  }

  return res.status(200).json({ received: true });
});

// GET /api/payments/status/:paymentId — Vérifier le statut d'un paiement
const getStatus = asyncHandler(async (req, res) => {
  const payment = await prisma.payment.findUnique({ where: { id: req.params.paymentId } });
  if (!payment) return response.notFound(res, 'Paiement introuvable.');
  return response.success(res, { payment });
});

// POST /api/payments/simulate — Simulation paiement (démo + dev)
const simulate = asyncHandler(async (req, res) => {
  // ✅ Autorisé en demo/dev — sera remplacé par vraie API OTM en production finale
  // if (process.env.NODE_ENV === 'production') {
  //   return response.forbidden(res, 'Non disponible en production.');
  // }

  const { consultationId } = req.body;
  const patient = await prisma.patient.findUnique({ where: { userId: req.user.id } });
  const consultation = await prisma.consultation.findFirst({
    where: { id: consultationId, patientId: patient.id, status: 'PENDING_PAYMENT' },
  });
  if (!consultation) return response.notFound(res, 'Consultation introuvable.');

  const payment = await prisma.payment.create({
    data: {
      consultationId,
      patientId: patient.id,
      provider: 'ORANGE_MONEY',
      amount:   consultation.totalAmount,
      currency: 'XAF',
      status:   'SUCCESS',
      paidAt:   new Date(),
      providerTxId: 'SIM-' + Date.now(),
    },
  });

  await activateAfterPayment(consultationId);
  return response.success(res, { payment }, '✅ Paiement simulé — consultation en cours de dispatch.');
});

// ── Intégrations OTM (stubs à compléter) ─────────────────────────

async function initiateOrangeMoney(payment, phoneNumber) {
  // TODO: Intégrer l'API Orange Money Cameroun officielle
  // Documentation : https://developer.orange.com/apis/orange-money-webpay-cm
  logger.info(`[Orange Money] Initiation paiement ${payment.amount} XAF → ${phoneNumber}`);

  // Pour l'instant on retourne une référence simulée
  return {
    reference: 'OM-' + Date.now(),
    message: `Entrez votre code Orange Money sur le ${phoneNumber}`,
  };
}

async function initiateMtnMomo(payment, phoneNumber) {
  // TODO: Intégrer l'API MTN MoMo officielle
  // Documentation : https://momodeveloper.mtn.com
  logger.info(`[MTN MoMo] Initiation paiement ${payment.amount} XAF → ${phoneNumber}`);

  return {
    reference: 'MOMO-' + Date.now(),
    message: `Validez le paiement MoMo sur le ${phoneNumber}`,
  };
}

module.exports = { initiate, callback, getStatus, simulate };
