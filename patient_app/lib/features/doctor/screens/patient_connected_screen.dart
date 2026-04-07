// lib/features/doctor/screens/patient_connected_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/socket_service.dart';

class PatientConnectedScreen extends StatefulWidget {
  final String consultationId;
  final String patientFirstName;
  final String patientLastName;
  final String speciality;
  final String mode;
  final String? symptomsText;

  const PatientConnectedScreen({
    super.key,
    required this.consultationId,
    required this.patientFirstName,
    required this.patientLastName,
    required this.speciality,
    required this.mode,
    this.symptomsText,
  });

  @override
  State<PatientConnectedScreen> createState() => _PatientConnectedScreenState();
}

class _PatientConnectedScreenState extends State<PatientConnectedScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
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
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeCtrl.forward();
    });

    // ✅ Rejoindre la room et écouter consultation:started
    // (déclenché si le patient appuie en premier)
    SocketService().joinConsultation(widget.consultationId);
    SocketService().onConsultationStarted = (data) {
      _navigateToConsultation();
    };
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    SocketService().onConsultationStarted = null;
    super.dispose();
  }

  void _navigateToConsultation() {
    if (_navigating || !mounted) return;
    _navigating = true;
    context.go('/doctor/consultation',
        extra: {'consultationId': widget.consultationId});
  }

  // ✅ Quand le médecin appuie : émettre consultation:start
  // Le backend notifie les deux → les deux naviguent
  void _startConsultation() {
    SocketService().emitConsultationStart(widget.consultationId);
    // Naviguer immédiatement côté médecin (optimiste)
    _navigateToConsultation();
  }

  String get _modeLabel {
    switch (widget.mode) {
      case 'AUDIO': return 'Appel audio';
      case 'VIDEO': return 'Vidéo';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.doctorPrimary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medical_services_rounded,
                    color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Flash', style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: AppColors.doctorPrimary)),
                TextSpan(text: 'Doc', style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: Colors.black54)),
              ])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 13),
                  SizedBox(width: 4),
                  Text('Acceptée', style: TextStyle(color: AppColors.success,
                      fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 32),

            FadeTransition(opacity: _fadeAnim,
              child: Column(children: [
                const Text('Nouveau patient !',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Votre patient attend.\nDémarrez quand vous êtes prêt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              ])),
            const SizedBox(height: 32),

            // Carte patient
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.doctorPrimary.withOpacity(0.2), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.doctorPrimary.withOpacity(0.1),
                      blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(children: [
                  // Avatar
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [AppColors.doctorPrimary.withOpacity(0.7), AppColors.doctorPrimary]),
                      boxShadow: [BoxShadow(color: AppColors.doctorPrimary.withOpacity(0.3),
                          blurRadius: 16, offset: const Offset(0, 4))]),
                    child: Center(child: Text(
                      '${widget.patientFirstName.isNotEmpty ? widget.patientFirstName[0] : ''}${widget.patientLastName.isNotEmpty ? widget.patientLastName[0] : ''}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                  const SizedBox(height: 16),

                  Text('${widget.patientFirstName} ${widget.patientLastName}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('Patient', style: TextStyle(fontSize: 12,
                        color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: _InfoChip(icon: Icons.local_hospital_outlined,
                        label: widget.speciality, color: AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoChip(icon: _modeIcon,
                        label: _modeLabel, color: AppColors.doctorPrimary)),
                  ]),

                  if (widget.symptomsText != null && widget.symptomsText!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withOpacity(0.2))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [
                          Icon(Icons.notes_outlined, color: AppColors.warning, size: 14),
                          SizedBox(width: 6),
                          Text('Symptômes décrits', style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600, color: AppColors.warning)),
                        ]),
                        const SizedBox(height: 6),
                        Text(widget.symptomsText!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                          maxLines: 4, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),

            const Spacer(),

            // ✅ Bouton "Démarrer" — déclenche les deux navigations
            FadeTransition(
              opacity: _fadeAnim,
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _startConsultation,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Démarrer la consultation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.doctorPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
