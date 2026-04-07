// lib/features/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/consultation_model.dart';
import '../../core/providers/consultation_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(consultationProvider.notifier).loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes consultations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.consultations.isEmpty
              ? _EmptyHistory()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(consultationProvider.notifier).loadHistory(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: state.consultations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _ConsultationCard(consultation: state.consultations[i]),
                  ),
                ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;
  const _ConsultationCard({required this.consultation});

  Color get _statusColor {
    switch (consultation.status) {
      case 'COMPLETED':   return AppColors.success;
      case 'IN_PROGRESS': return AppColors.primary;
      case 'CANCELLED':   return AppColors.error;
      case 'EXPIRED':     return AppColors.textHint;
      default:            return AppColors.warning;
    }
  }

  IconData get _modeIcon {
    switch (consultation.mode) {
      case 'AUDIO': return Icons.mic_rounded;
      case 'VIDEO': return Icons.videocam_rounded;
      default:      return Icons.chat_bubble_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm')
        .format(consultation.createdAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // En-tête
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_modeIcon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(consultation.speciality ?? 'Généraliste',
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 15, color: AppColors.textPrimary)),
                Text(consultation.modeLabel,
                  style: const TextStyle(fontSize: 12,
                      color: AppColors.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(consultation.statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _statusColor)),
              ),
            ]),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            if (consultation.doctor != null)
              Row(children: [
                const Icon(Icons.person_outline, size: 15,
                    color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(consultation.doctor!.fullName,
                  style: const TextStyle(fontSize: 13,
                      color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                Text(' ${consultation.doctor!.averageRating}',
                  style: const TextStyle(fontSize: 12,
                      color: AppColors.textSecondary)),
              ]),

            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14,
                    color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(fontSize: 12,
                    color: AppColors.textSecondary)),
              ]),
              Text('${consultation.totalAmount.toInt()} FCFA',
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),

            if (consultation.canRate || consultation.prescriptionUrl != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                if (consultation.canRate)
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => context.push('/consult/rating',
                        extra: {'consultationId': consultation.id}),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Évaluer',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  )),
                if (consultation.canRate && consultation.prescriptionUrl != null)
                  const SizedBox(width: 8),
                if (consultation.prescriptionUrl != null)
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Ordonnance',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        backgroundColor: AppColors.primary),
                  )),
              ]),
            ],

            if (consultation.rating != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(children: [
                  ...List.generate(5, (i) => Icon(
                    i < (consultation.rating!.score / 2).round()
                        ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning, size: 16)),
                  const SizedBox(width: 6),
                  Text('${consultation.rating!.score}/10',
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
              color: AppColors.surfaceGrey, shape: BoxShape.circle),
          child: const Icon(Icons.history_outlined, size: 50,
              color: AppColors.textHint),
        ),
        const SizedBox(height: 20),
        const Text('Aucune consultation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Vos consultations apparaîtront ici',
          style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.go('/consult/symptoms'),
          icon: const Icon(Icons.flash_on_rounded),
          label: const Text('Consulter maintenant'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.consultNow,
              foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
        onTap: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/history');
          if (i == 2) context.go('/profile');
        },
      ),
    );
  }
}
