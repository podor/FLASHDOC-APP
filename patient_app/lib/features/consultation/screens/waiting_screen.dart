// lib/features/consultation/screens/waiting_screen.dart
import 'dart:async';
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
  late AnimationController _pulseCtrl;
  late AnimationController _dotCtrl;
  late Timer _timer;
  Timer? _pollTimer;
  int _elapsed = 0;
  static const _timeout = 60;
  bool _navigating = false;

  // Données du médecin reçues via socket
  Map<String, dynamic>? _doctorData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

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
      print('🎯 Socket: consultation:matched reçu : $data');
      // ✅ Récupérer les infos du médecin depuis l'événement socket
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
          print('📊 Polling status: $status');
          if (status == 'MATCHED' || status == 'IN_PROGRESS') {
            // ✅ Récupérer les infos du médecin depuis l'API
            final doctorData = data['doctor'] as Map<String, dynamic>?;
            final mode = data['mode'] as String? ?? 'CHAT';
            _navigateToDoctorFound(doctorFromApi: doctorData, mode: mode);
          } else if (status == 'EXPIRED' || status == 'CANCELLED') {
            _cancelAll();
            _showExpiredDialog();
          }
        }
      } catch (e) {
        print('⚠️ Polling error: $e');
      }
    });
  }

  // ✅ Navigation vers l'écran "Médecin trouvé" avec ses infos
  void _navigateToDoctorFound({
    Map<String, dynamic>? doctorFromSocket,
    Map<String, dynamic>? doctorFromApi,
    String mode = 'CHAT',
  }) {
    if (_navigating || !mounted) return;
    _navigating = true;
    _cancelAll();

    final doctor = doctorFromSocket ?? doctorFromApi ?? {};

    // Extraire les infos du médecin
    String firstName = '';
    String lastName  = '';
    String speciality = 'Généraliste';
    double rating = 0.0;
    String? avatarUrl;

    // Format depuis socket : { firstName, lastName, speciality, averageRating, avatarUrl }
    // Format depuis API (nested) : { user: { firstName, lastName }, speciality, averageRating }
    if (doctor.containsKey('user')) {
      final user = doctor['user'] as Map<String, dynamic>? ?? {};
      firstName  = user['firstName'] as String? ?? '';
      lastName   = user['lastName']  as String? ?? '';
      avatarUrl  = user['avatarUrl'] as String?;
    } else {
      firstName  = doctor['firstName'] as String? ?? '';
      lastName   = doctor['lastName']  as String? ?? '';
      avatarUrl  = doctor['avatarUrl'] as String?;
    }
    speciality = doctor['speciality']    as String? ?? 'Généraliste';
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
    if (state == AppLifecycleState.resumed && !_navigating) {
      _setupSocket();
    }
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.schedule_outlined, color: AppColors.warning, size: 48),
        title: const Text('Aucun médecin disponible', textAlign: TextAlign.center),
        content: const Text(
          'Aucun médecin n\'était disponible.\n\nAssurez-vous qu\'un médecin est connecté et a activé son toggle "Disponible".',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); context.go('/patient/home'); },
            child: const Text('Retour')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.go('/patient/consult/symptoms'); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Réessayer')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Recherche en cours...',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () { _cancelAll(); context.go('/patient/home'); },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 40),

          SizedBox(
            width: 160, height: 160,
            child: Stack(alignment: Alignment.center, children: [
              ...List.generate(3, (i) => AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + (_pulseCtrl.value * 0.3) + (i * 0.15),
                  child: Container(width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.08 - i * 0.02))),
                ),
              )),
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.scale(
                      scale: 0.9 + _pulseCtrl.value * 0.1, child: child),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 36)),
              ),
            ]),
          ),
          const SizedBox(height: 32),

          _AnimatedDots(controller: _dotCtrl),
          const SizedBox(height: 24),

          Text('Temps estimé : $remaining sec',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Recherche d\'un médecin disponible...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Le médecin doit être connecté et avoir activé le toggle "Disponible".',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ]),
          ),
          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _elapsed / _timeout, minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
          ),

          const Spacer(),

          TextButton(
            onPressed: () { _cancelAll(); context.go('/patient/home'); },
            child: const Text('Annuler la recherche',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(8, (i) {
          final progress = (controller.value * 8 - i) % 1.0;
          final opacity  = (1.0 - progress).clamp(0.1, 1.0);
          final size     = 8.0 + (1.0 - progress) * 4;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(opacity)));
        }),
      ),
    );
  }
}
