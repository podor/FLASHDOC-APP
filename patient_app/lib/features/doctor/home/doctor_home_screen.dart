// lib/features/doctor/home/doctor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/doctor_provider.dart';
import '../../../core/services/api_service.dart';
import '../widgets/doctor_bottom_nav.dart';

// ── Provider des stats médecin ────────────────────────────────────
final doctorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().getDoctorProfile();
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final doctor = data['doctor'] as Map<String, dynamic>? ?? {};
      return {
        'totalConsults':   doctor['totalConsults'] as int? ?? 0,
        'walletBalance':   (doctor['walletBalance'] as num?)?.toDouble() ?? 0.0,
        'averageRating':   (doctor['averageRating'] as num?)?.toDouble() ?? 0.0,
      };
    }
  } catch (_) {}
  return {'totalConsults': 0, 'walletBalance': 0.0, 'averageRating': 0.0};
});

class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authProvider).user;
    final isAvailable = ref.watch(doctorProvider).isAvailable;
    final statsAsync  = ref.watch(doctorStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.doctorPrimary,
          // Pull-to-refresh recharge les stats
          onRefresh: () => ref.refresh(doctorStatsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header vert ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: AppColors.doctorPrimary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        RichText(text: const TextSpan(children: [
                          TextSpan(text: 'Flash',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          TextSpan(text: 'Doc',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white70)),
                        ])),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => context.go('/doctor/profile'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: Text(user?.initials ?? 'Dr',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Text('Dr. ${user?.lastName ?? 'Médecin'}',
                        style: const TextStyle(fontSize: 22,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('Espace médecin',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 16),

                      // Toggle disponibilité
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 10, height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              color: isAvailable
                                  ? AppColors.success : AppColors.textHint),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            isAvailable ? 'Vous êtes disponible'
                                : 'Vous êtes indisponible',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? AppColors.success
                                    : AppColors.textSecondary),
                          )),
                          Switch(
                            value: isAvailable,
                            onChanged: (v) => ref
                                .read(doctorProvider.notifier)
                                .setAvailable(v),
                            activeColor: AppColors.doctorPrimary,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Stats depuis l'API ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: statsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.doctorPrimary, strokeWidth: 2)),
                    error: (_, __) => Row(children: [
                      Expanded(child: _StatCard(
                          label: 'Consultations', value: '—',
                          icon: Icons.medical_services_outlined,
                          color: AppColors.doctorPrimary)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                          label: 'Revenus', value: '—',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.warning)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                          label: 'Note', value: '—',
                          icon: Icons.star_outline_rounded,
                          color: AppColors.consultNow)),
                    ]),
                    data: (stats) {
                      final consults = stats['totalConsults'] as int;
                      final balance  = stats['walletBalance'] as double;
                      final rating   = stats['averageRating'] as double;
                      final ratingStr = rating > 0
                          ? rating.toStringAsFixed(1)
                          : '—';
                      final balanceStr = balance >= 1000
                          ? '${(balance / 1000).toStringAsFixed(0)}k F'
                          : '${balance.toInt()} F';

                      return Row(children: [
                        Expanded(child: _StatCard(
                            label: 'Consultations',
                            value: consults.toString(),
                            icon: Icons.medical_services_outlined,
                            color: AppColors.doctorPrimary)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                            label: 'Wallet',
                            value: balanceStr,
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.warning)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                            label: 'Note',
                            value: ratingStr,
                            icon: Icons.star_outline_rounded,
                            color: AppColors.consultNow)),
                      ]);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Actions ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text('Actions rapides',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    _ActionCard(
                      icon: Icons.inbox_outlined,
                      title: 'Demandes en attente',
                      subtitle: 'Voir les consultations disponibles',
                      color: AppColors.doctorPrimary,
                      onTap: () => context.go('/doctor/requests'),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Mon wallet',
                      subtitle: 'Solde et retraits Mobile Money',
                      color: AppColors.warning,
                      onTap: () => context.go('/doctor/wallet'),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.person_outline,
                      title: 'Mon profil',
                      subtitle: 'Informations, spécialité, agenda',
                      color: AppColors.secondary,
                      onTap: () => context.go('/doctor/profile'),
                    ),
                  ]),
                ),

                if (!isAvailable) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Activez votre disponibilité pour recevoir des demandes.',
                          style: TextStyle(fontSize: 12,
                              color: AppColors.textSecondary),
                        )),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 0),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10,
              color: AppColors.textSecondary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12,
                color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14,
              color: AppColors.textHint),
        ]),
      ),
    );
  }
}
