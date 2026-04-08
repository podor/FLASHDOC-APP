// lib/features/doctor/home/doctor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/doctor_provider.dart';
import '../../../core/services/api_service.dart';
import '../widgets/doctor_bottom_nav.dart';

// ── Provider stats médecin ────────────────────────────────────────
final doctorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().getDoctorProfile();
    if (res['success'] == true) {
      final doctor = (res['data'] as Map? ?? {})['doctor'] as Map? ?? {};
      return {
        'totalConsults': doctor['totalConsults'] as int? ?? 0,
        'walletBalance': (doctor['walletBalance'] as num?)?.toDouble() ?? 0.0,
        'averageRating': (doctor['averageRating'] as num?)?.toDouble() ?? 0.0,
        'speciality':   doctor['speciality'] as String? ?? '',
      };
    }
  } catch (_) {}
  return {'totalConsults': 0, 'walletBalance': 0.0, 'averageRating': 0.0, 'speciality': ''};
});

class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authProvider).user;
    final isAvailable = ref.watch(doctorProvider).isAvailable;
    final statsAsync  = ref.watch(doctorStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.doctorPrimary,
          onRefresh: () => ref.refresh(doctorStatsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Hero Header ──────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006B4E), Color(0xFF00A878)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28)),
                ),
                child: Column(children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      RichText(text: const TextSpan(children: [
                        TextSpan(text: 'Flash', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: Colors.white)),
                        TextSpan(text: 'Doc', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: Colors.white60)),
                      ])),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/doctor/profile'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4), width: 2)),
                          child: Center(child: Text(user?.initials ?? 'Dr',
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w800, color: Colors.white))),
                        ),
                      ),
                    ]),
                  ),

                  // Salutation
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Bonjour,', style: TextStyle(
                            fontSize: 15, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text('Dr. ${user?.lastName ?? 'Médecin'}',
                          style: const TextStyle(fontSize: 26,
                              fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        statsAsync.maybeWhen(
                          data: (s) => Text(s['speciality'] as String? ?? '',
                            style: const TextStyle(fontSize: 13,
                                color: Colors.white70)),
                          orElse: () => const SizedBox.shrink()),
                      ])),
                      // Badge disponibilité
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAvailable
                                  ? Colors.greenAccent : Colors.white38)),
                          const SizedBox(width: 6),
                          Text(isAvailable ? 'En ligne' : 'Hors ligne',
                            style: const TextStyle(fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── Toggle disponibilité ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => ref.read(doctorProvider.notifier)
                          .setAvailable(!isAvailable),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.white
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: isAvailable
                              ? null
                              : Border.all(color: Colors.white24),
                          boxShadow: isAvailable ? [BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Row(children: [
                          // Icône animée
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppColors.doctorPrimary.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle),
                            child: Icon(
                              isAvailable
                                  ? Icons.wifi_tethering_rounded
                                  : Icons.wifi_tethering_off_rounded,
                              color: isAvailable
                                  ? AppColors.doctorPrimary : Colors.white60,
                              size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(isAvailable
                                ? 'Vous êtes disponible'
                                : 'Vous êtes indisponible',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: isAvailable
                                    ? AppColors.doctorPrimary : Colors.white70)),
                            const SizedBox(height: 2),
                            Text(isAvailable
                                ? 'Les patients peuvent vous contacter'
                                : 'Activez pour recevoir des demandes',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAvailable
                                    ? AppColors.textSecondary
                                    : Colors.white50)),
                          ])),
                          Switch(
                            value: isAvailable,
                            onChanged: (v) => ref.read(doctorProvider.notifier)
                                .setAvailable(v),
                            activeColor: AppColors.doctorPrimary,
                            inactiveThumbColor: Colors.white60,
                            inactiveTrackColor: Colors.white24,
                          ),
                        ]),
                      ),
                    ),
                  ),

                  // ── Stats ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: statsAsync.when(
                      loading: () => const Center(child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) {
                        final consults = stats['totalConsults'] as int;
                        final balance  = stats['walletBalance'] as double;
                        final rating   = stats['averageRating'] as double;
                        return Row(children: [
                          _HeroStat(
                            value: consults.toString(),
                            label: 'Consultations',
                            icon: Icons.medical_services_rounded),
                          _HeroStatDivider(),
                          _HeroStat(
                            value: balance >= 1000
                                ? '${(balance / 1000).toStringAsFixed(0)}k F'
                                : '${balance.toInt()} F',
                            label: 'Wallet',
                            icon: Icons.account_balance_wallet_rounded),
                          _HeroStatDivider(),
                          _HeroStat(
                            value: rating > 0
                                ? '${rating.toStringAsFixed(1)}/10' : '—',
                            label: 'Note moy.',
                            icon: Icons.star_rounded),
                        ]);
                      },
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Actions rapides ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('Actions rapides',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),

              // Demandes en attente — card principale
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.go('/doctor/requests'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006B4E), Color(0xFF00A878)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: AppColors.doctorPrimary.withOpacity(0.3),
                          blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.inbox_rounded,
                            color: Colors.white, size: 28)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Demandes en attente',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(isAvailable
                            ? 'Vous pouvez accepter des consultations'
                            : 'Activez votre disponibilité d\'abord',
                          style: TextStyle(fontSize: 12,
                              color: Colors.white.withOpacity(0.8))),
                      ])),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3 actions secondaires
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: _SecondaryAction(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Mon wallet',
                    sublabel: 'Retrait Mobile Money',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.go('/doctor/wallet'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _SecondaryAction(
                    icon: Icons.folder_special_outlined,
                    label: 'Mon dossier',
                    sublabel: 'Statut affiliation',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/doctor/application-status'),
                  )),
                ]),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: _SecondaryAction(
                    icon: Icons.person_rounded,
                    label: 'Mon profil',
                    sublabel: 'Infos & spécialité',
                    color: AppColors.primary,
                    onTap: () => context.go('/doctor/profile'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _SecondaryAction(
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    sublabel: 'Mes consultations',
                    color: const Color(0xFF0EA5E9),
                    onTap: () => context.go('/doctor/requests'),
                  )),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Conseil du jour ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: const Row(children: [
                    Text('💡', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Conseil',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                      SizedBox(height: 3),
                      Text(
                        'Pour une consultation de qualité, assurez-vous d\'être dans un endroit calme et bien éclairé.',
                        style: TextStyle(fontSize: 12,
                            color: AppColors.textSecondary, height: 1.4)),
                    ])),
                  ]),
                ),
              ),
              const SizedBox(height: 28),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 0),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _HeroStat({required this.value, required this.label,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18,
          fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60),
          textAlign: TextAlign.center),
    ]));
  }
}

class _HeroStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40,
        color: Colors.white.withOpacity(0.2));
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _SecondaryAction({required this.icon, required this.label,
      required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(sublabel, style: const TextStyle(fontSize: 10,
                color: AppColors.textSecondary)),
          ])),
        ]),
      ),
    );
  }
}
