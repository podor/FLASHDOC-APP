// lib/features/consultation/screens/waiting_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/api_service.dart';

class WaitingScreen extends StatefulWidget {
  final String consultationId;
  const WaitingScreen({super.key, required this.consultationId});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _rippleCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Timer _timer;
  Timer? _pollTimer;
  int _elapsed = 0;
  static const _timeout = 60;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _setupSocket();
    _startPolling();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _navigating) return;
      setState(() => _elapsed++);
      if (_elapsed >= _timeout) {
        _cancelAll();
        _showExpiredDialog();
      }
    });
  }

  void _setupSocket() {
    final socket = SocketService();
    socket.joinConsultation(widget.consultationId);
    socket.onConsultationMatched = (data) {
      final doctor = data['doctor'] as Map<String, dynamic>?;
      _navigateToDoctorFound(doctorFromSocket: doctor);
    };
    socket.onConsultationExpired = (_) {
      if (!_navigating) { _cancelAll(); _showExpiredDialog(); }
    };
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _navigating) return;
      try {
        final res = await ApiService().getConsultation(widget.consultationId);
        if (res['success'] == true) {
          final data = res['data']['consultation'] as Map<String, dynamic>? ?? {};
          final status = data['status'] as String? ?? '';
          if (status == 'MATCHED' || status == 'IN_PROGRESS') {
            final doctorData = data['doctor'] as Map<String, dynamic>?;
            final mode = data['mode'] as String? ?? 'CHAT';
            _navigateToDoctorFound(doctorFromApi: doctorData, mode: mode);
          } else if (status == 'EXPIRED' || status == 'CANCELLED') {
            _cancelAll();
            _showExpiredDialog();
          }
        }
      } catch (_) {}
    });
  }

  void _navigateToDoctorFound({
    Map<String, dynamic>? doctorFromSocket,
    Map<String, dynamic>? doctorFromApi,
    String mode = 'CHAT',
  }) {
    if (_navigating || !mounted) return;
    _navigating = true;
    _cancelAll();
    final doctor = doctorFromSocket ?? doctorFromApi ?? {};
    String firstName = '', lastName = '', speciality = 'Généraliste';
    double rating = 0.0;
    String? avatarUrl;
    if (doctor.containsKey('user')) {
      final u = doctor['user'] as Map<String, dynamic>? ?? {};
      firstName = u['firstName'] as String? ?? '';
      lastName  = u['lastName']  as String? ?? '';
      avatarUrl = u['avatarUrl'] as String?;
    } else {
      firstName = doctor['firstName'] as String? ?? '';
      lastName  = doctor['lastName']  as String? ?? '';
      avatarUrl = doctor['avatarUrl'] as String?;
    }
    speciality = doctor['speciality']     as String? ?? 'Généraliste';
    rating     = (doctor['averageRating'] as num?)?.toDouble() ?? 0.0;
    context.go('/patient/consult/doctor-found', extra: {
      'consultationId':   widget.consultationId,
      'doctorFirstName':  firstName,
      'doctorLastName':   lastName,
      'doctorSpeciality': speciality,
      'doctorRating':     rating,
      'doctorAvatarUrl':  avatarUrl,
      'mode':             mode,
    });
  }

  void _cancelAll() {
    _timer.cancel();
    _pollTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_navigating) _setupSocket();
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.schedule_outlined,
                color: AppColors.warning, size: 36)),
          const SizedBox(height: 16),
          const Text('Aucun médecin disponible',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Text(
            'Tous les médecins sont occupés en ce moment. Réessayez dans quelques instants.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/patient/home');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Retour',
                  style: TextStyle(color: AppColors.textSecondary)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/patient/consult/symptoms');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Réessayer',
                  style: TextStyle(fontWeight: FontWeight.w700)))),
          ]),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rippleCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _pollTimer?.cancel();
    if (!_navigating) {
      _timer.cancel();
      SocketService().onConsultationMatched = null;
      SocketService().onConsultationExpired = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _timeout - _elapsed;
    final progress  = _elapsed / _timeout;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // ── AppBar custom ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textPrimary),
                onPressed: () { _cancelAll(); context.go('/patient/home'); }),
              const Expanded(child: Text('Recherche en cours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary), textAlign: TextAlign.center)),
              const SizedBox(width: 48),
            ]),
          ),

          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Spacer(),

              // ── Animation centrale ────────────────────────────
              SizedBox(
                width: 220, height: 220,
                child: Stack(alignment: Alignment.center, children: [
                  // Ripples
                  ...List.generate(3, (i) => AnimatedBuilder(
                    animation: _rippleCtrl,
                    builder: (_, __) {
                      final v = (_rippleCtrl.value + i / 3) % 1.0;
                      return Transform.scale(
                        scale: 0.5 + v * 0.8,
                        child: Opacity(
                          opacity: (1 - v) * 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 2)),
                          )));
                    },
                  )),

                  // Cercle rotatif pointillé
                  AnimatedBuilder(
                    animation: _rotateCtrl,
                    builder: (_, child) => Transform.rotate(
                      angle: _rotateCtrl.value * 2 * pi,
                      child: child),
                    child: CustomPaint(
                      size: const Size(160, 160),
                      painter: _DashedCirclePainter(
                          color: AppColors.primary.withOpacity(0.3))),
                  ),

                  // Centre pulsé
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: 0.95 + _pulseCtrl.value * 0.05,
                      child: child),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0066FF), Color(0xFF4D94FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 20, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.medical_services_rounded,
                          color: Colors.white, size: 44)),
                  ),
                ])),
              const SizedBox(height: 40),

              // ── Texte ─────────────────────────────────────────
              const Text('Recherche d\'un médecin...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Le premier médecin disponible\nprendra en charge votre consultation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary,
                    height: 1.5)),
              const SizedBox(height: 28),

              // ── Timer arc ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('$remaining secondes restantes',
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Progress bar ─────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    progress > 0.7 ? AppColors.warning : AppColors.primary)),
              ),
              const SizedBox(height: 8),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                const Text('En cours...', style: TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
                Text('Max 60 sec', style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
              ]),

              const Spacer(),

              // ── Astuce ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(children: [
                  Icon(Icons.lightbulb_outline,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Le médecin doit être connecté et avoir activé son statut "Disponible".',
                    style: TextStyle(fontSize: 12,
                        color: AppColors.textSecondary, height: 1.4))),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Annuler ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _cancelAll();
                    context.go('/patient/home');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Annuler la recherche',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 20;
    const dashAngle = 2 * pi / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      final end   = start + dashAngle * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, end - start, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
