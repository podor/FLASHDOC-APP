// lib/features/doctor/requests/doctor_requests_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/doctor_provider.dart';
import '../widgets/doctor_bottom_nav.dart';

class DoctorRequestsScreen extends ConsumerStatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  ConsumerState<DoctorRequestsScreen> createState() =>
      _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState
    extends ConsumerState<DoctorRequestsScreen> {

  @override
  void initState() {
    super.initState();
    // Navigation auto si une consultation déjà active au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(doctorProvider);
      if (state.activeConsultationId != null && mounted) {
        // ✅ Naviguer vers patient-connected avec les infos disponibles
        final req = state.activeRequest;
        context.go('/doctor/patient-connected', extra: {
          'consultationId':   state.activeConsultationId,
          'patientFirstName': req?.patientFirstName ?? '',
          'patientLastName':  req?.patientLastName  ?? '',
          'speciality':       req?.speciality        ?? 'Généraliste',
          'mode':             req?.mode              ?? 'CHAT',
          'symptomsText':     req?.symptomsText,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorProvider);

    // ✅ Écouter les nouvelles acceptations → naviguer vers patient-connected
    ref.listen(doctorProvider, (prev, next) {
      if (next.activeConsultationId != null &&
          prev?.activeConsultationId != next.activeConsultationId) {
        if (mounted) {
          final req = next.activeRequest;
          context.go('/doctor/patient-connected', extra: {
            'consultationId':   next.activeConsultationId,
            'patientFirstName': req?.patientFirstName ?? '',
            'patientLastName':  req?.patientLastName  ?? '',
            'speciality':       req?.speciality        ?? 'Généraliste',
            'mode':             req?.mode              ?? 'CHAT',
            'symptomsText':     req?.symptomsText,
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Demandes de consultation',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          Text('${state.requests.length} en attente',
            style: const TextStyle(fontSize: 12,
                color: AppColors.textSecondary)),
        ]),
        actions: [
          // Toggle disponibilité
          GestureDetector(
            onTap: () => ref.read(doctorProvider.notifier)
                .setAvailable(!state.isAvailable),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.isAvailable
                    ? AppColors.doctorLight : AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isAvailable
                        ? AppColors.doctorPrimary : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isAvailable ? 'Disponible' : 'Indisponible',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: state.isAvailable
                        ? AppColors.doctorPrimary : AppColors.textHint,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      body: state.requests.isEmpty
          ? _EmptyRequests(isAvailable: state.isAvailable)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _RequestCard(
                request: state.requests[i],
                onAccept: () => ref.read(doctorProvider.notifier)
                    .acceptConsultation(state.requests[i].id),
                onExpired: () => ref.read(doctorProvider.notifier)
                    .removeExpiredRequest(state.requests[i].id),
              ),
            ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 1),
    );
  }
}

// ── Card de demande avec timer 60s ────────────────────────────────
class _RequestCard extends StatefulWidget {
  final ConsultationRequest request;
  final VoidCallback onAccept;
  final VoidCallback onExpired;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onExpired,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  late Timer _countdown;
  int _remaining = 60;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..forward();

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _countdown.cancel();
        widget.onExpired();
      }
    });
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _countdown.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining > 30) return AppColors.doctorPrimary;
    if (_remaining > 15) return AppColors.warning;
    return AppColors.error;
  }

  IconData get _modeIcon {
    switch (widget.request.mode) {
      case 'AUDIO': return Icons.mic_rounded;
      case 'VIDEO': return Icons.videocam_rounded;
      default:      return Icons.chat_bubble_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.doctorPrimary.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(
          color: AppColors.doctorPrimary.withOpacity(0.08),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        // Timer barre
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(17),
            topRight: Radius.circular(17),
          ),
          child: AnimatedBuilder(
            animation: _timerCtrl,
            builder: (_, __) => LinearProgressIndicator(
              value: 1.0 - _timerCtrl.value,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(_timerColor),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.doctorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_modeIcon,
                    color: AppColors.doctorPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.request.speciality ?? 'Généraliste',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
                Text(widget.request.modeLabel,
                  style: const TextStyle(fontSize: 13,
                      color: AppColors.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$_remaining s',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800, color: _timerColor)),
                Text('${widget.request.amount.toInt()} F',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              ]),
            ]),

            if (widget.request.symptomsText != null &&
                widget.request.symptomsText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.notes_outlined,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.request.symptomsText!,
                    style: const TextStyle(fontSize: 13,
                        color: AppColors.textPrimary, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _accepting ? null : () async {
                  setState(() => _accepting = true);
                  widget.onAccept();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.doctorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _accepting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Accepter la consultation',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────────
class _EmptyRequests extends StatelessWidget {
  final bool isAvailable;
  const _EmptyRequests({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.doctorLight : AppColors.surfaceGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable
                  ? Icons.inbox_outlined : Icons.wifi_off_outlined,
              size: 50,
              color: isAvailable
                  ? AppColors.doctorPrimary : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isAvailable
                ? 'En attente de demandes...'
                : 'Vous êtes indisponible',
            style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isAvailable
                ? 'Les nouvelles demandes apparaîtront ici automatiquement.'
                : 'Activez votre disponibilité pour recevoir des demandes.',
            style: const TextStyle(fontSize: 14,
                color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
