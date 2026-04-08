// lib/features/doctor/profile/doctor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/doctor_bottom_nav.dart';

class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mon profil médecin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // En-tête vert médecin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              gradient: AppColors.doctorGradient,
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: Text(user?.initials ?? 'Dr',
                  style: const TextStyle(fontSize: 28,
                      fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              Text('Dr. ${user?.fullName ?? ''}',
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(user?.phone ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.pending_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Dossier en attente de validation',
                    style: TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w500)),
                ]),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _Section(title: 'Mon dossier FlashDoc', items: [
                _MenuItem(
                  icon: Icons.folder_special_outlined,
                  label: 'Statut de mon dossier',
                  value: 'Voir l\'avancement',
                  onTap: () => context.push('/doctor/application-status'),
                  color: AppColors.doctorPrimary,
                ),
                _MenuItem(
                  icon: Icons.edit_document,
                  label: 'Modifier mon dossier',
                  onTap: () => context.push('/doctor/onboarding'),
                ),
              ]),
              const SizedBox(height: 12),
              _Section(title: 'Informations professionnelles', items: [
                _MenuItem(icon: Icons.badge_outlined,
                    label: 'Numéro ONMC', value: 'Non renseigné', onTap: () {}),
                _MenuItem(icon: Icons.local_hospital_outlined,
                    label: 'Spécialité', value: 'Non renseignée', onTap: () {}),
                _MenuItem(icon: Icons.location_on_outlined,
                    label: 'Ville', value: 'Non renseignée', onTap: () {}),
              ]),
              const SizedBox(height: 12),
              _Section(title: 'Documents', items: [
                _MenuItem(icon: Icons.upload_file_outlined,
                    label: 'Diplôme', value: 'Non soumis', onTap: () {}),
                _MenuItem(icon: Icons.upload_file_outlined,
                    label: 'Licence ONMC', value: 'Non soumis', onTap: () {}),
              ]),
              const SizedBox(height: 12),
              _Section(title: 'Paramètres', items: [
                _MenuItem(icon: Icons.schedule_outlined,
                    label: 'Mes disponibilités', onTap: () {}),
                _MenuItem(icon: Icons.notifications_outlined,
                    label: 'Notifications', onTap: () {}),
                _MenuItem(icon: Icons.help_outline,
                    label: 'Support FlashDoc', onTap: () {}),
              ]),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 20),
                  ),
                  title: const Text('Se déconnecter',
                    style: TextStyle(color: AppColors.error,
                        fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Column(children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) return const Divider(height: 1, indent: 52);
          return items[i ~/ 2];
        })),
      ),
    ]);
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label,
      this.value, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.doctorPrimary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (value != null) Text(value!, style: const TextStyle(
            fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
      ]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
