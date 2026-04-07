// lib/features/consultation/screens/doctor_found_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/socket_service.dart';

class DoctorFoundScreen extends StatefulWidget {
  final String consultationId;
  final String doctorFirstName;
  final String doctorLastName;
  final String doctorSpeciality;
  final double doctorRating;
  final String? doctorAvatarUrl;
  final String mode;

  const DoctorFoundScreen({
    super.key,
    required this.consultationId,
    required this.doctorFirstName,
    required this.doctorLastName,
    required this.doctorSpeciality,
    required this.doctorRating,
    this.doctorAvatarUrl,
    required this.mode,
  });

  @override
  State<DoctorFoundScreen> createState() => _DoctorFoundScreenState();
}

class _DoctorFoundScreenState extends State<DoctorFoundScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fadeCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeCtrl.forward();
    });

    // ✅ Rejoindre la room et écouter consultation:started
    // (déclenché si le médecin appuie en premier)
    SocketService().joinConsultation(widget.consultationId);
    SocketService().onConsultationStarted = (data) {
      _navigateToSession();
    };
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    SocketService().onConsultationStarted = null;
    super.dispose();
  }

  void _navigateToSession() {
    if (_navigating || !mounted) return;
    _navigating = true;
    context.go('/patient/consult/session',
        extra: {'consultationId': widget.consultationId});
  }

  // ✅ Quand le patient appuie : émettre consultation:start
  // Le backend notifie les deux → les deux naviguent
  void _startConsultation() {
    SocketService().emitConsultationStart(widget.consultationId);
    // Naviguer immédiatement côté patient (optimiste)
    _navigateToSession();
  }

  String get _modeLabel {
    switch (widget.mode) {
      case 'AUDIO': return 'Appel audio';
      case 'VIDEO': return 'Vidéo consultation';
      default:      return 'Chat texte';
    }
  }

  IconData get _modeIcon {
    switch (widget.mode) {
      case 'AUDIO': return Icons.mic_rounded;
      case 'VIDEO': return Icons.videocam_rounded;
      default:      return Icons.chat_bubble_rounded;
    }
  }

  Color get _modeColor {
    switch (widget.mode) {
      case 'AUDIO': return AppColors.secondary;
      case 'VIDEO': return AppColors.consultNow;
      default:      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(children: [
            // En-tête
            Row(children: [
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Flash', style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: AppColors.primary)),
                TextSpan(text: 'Doc', style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: AppColors.secondary)),
              ])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                  SizedBox(width: 5),
                  Text('Médecin trouvé !',
                    style: TextStyle(color: AppColors.success, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 32),

            FadeTransition(opacity: _fadeAnim,
              child: Column(children: [
                const Text('Votre médecin est prêt',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Un médecin a accepté votre demande.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              ])),
            const SizedBox(height: 32),

            // Carte médecin
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(children: [
                  // Avatar
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Container(
                      padding: EdgeInsets.all(4 + _pulseCtrl.value * 3),
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.05 + _pulseCtrl.value * 0.05)),
                      child: child),
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary]),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16, offset: const Offset(0, 4))]),
                      child: widget.doctorAvatarUrl != null
                          ? ClipOval(child: Image.network(widget.doctorAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _initials))
                          : _initials,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Dr. ${widget.doctorFirstName} ${widget.doctorLastName}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(widget.doctorSpeciality,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),

                  _RatingStars(rating: widget.doctorRating),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _modeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _modeColor.withOpacity(0.2))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_modeIcon, color: _modeColor, size: 18),
                      const SizedBox(width: 8),
                      Text(_modeLabel, style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600, color: _modeColor)),
                    ]),
                  ),
                ]),
              ),
            ),

            const Spacer(),

            // ✅ Un seul bouton — déclenche les deux navigations
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _startConsultation,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Démarrer la consultation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.lock_outline, size: 13, color: AppColors.textHint),
                  SizedBox(width: 5),
                  Text('Consultation sécurisée et confidentielle',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget get _initials => Center(
    child: Text(
      '${widget.doctorFirstName.isNotEmpty ? widget.doctorFirstName[0] : ''}${widget.doctorLastName.isNotEmpty ? widget.doctorLastName[0] : ''}',
      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white),
    ),
  );
}

class _RatingStars extends StatelessWidget {
  final double rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) {
      return const Text('Nouveau médecin',
        style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic));
    }
    final stars = rating / 2;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(children: List.generate(5, (i) {
        if (i < stars.floor())
          return const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 20);
        else if (i < stars.ceil() && stars % 1 != 0)
          return const Icon(Icons.star_half_rounded, color: Color(0xFFFFC107), size: 20);
        else
          return const Icon(Icons.star_outline_rounded, color: AppColors.border, size: 20);
      })),
      const SizedBox(width: 8),
      Text('${rating.toStringAsFixed(1)}/10',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
    ]);
  }
}
