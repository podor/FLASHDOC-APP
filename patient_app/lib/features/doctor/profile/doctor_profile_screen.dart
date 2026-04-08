// lib/features/doctor/profile/doctor_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/fd_snackbar.dart';
import '../widgets/doctor_bottom_nav.dart';
import '../home/doctor_home_screen.dart';

// ── Provider profil médecin ───────────────────────────────────────
final doctorProfileDetailProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().getDoctorProfile();
    if (res['success'] == true) {
      return res['data']['doctor'] as Map<String, dynamic>? ?? {};
    }
  } catch (_) {}
  return {};
});

class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authProvider).user;
    final profileAsync = ref.watch(doctorProfileDetailProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F5),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar avec photo ──────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.doctorPrimary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => ref.invalidate(doctorProfileDetailProvider)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: profileAsync.when(
                loading: () => _buildHeader(context, ref, user, null),
                error:   (_, __) => _buildHeader(context, ref, user, null),
                data: (d) => _buildHeader(context, ref, user, d),
              ),
            ),
            title: Text('Dr. ${user?.lastName ?? ''}',
              style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w700)),
          ),

          // ── Contenu ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              profileAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: AppColors.doctorPrimary))),
                error: (_, __) => const SizedBox.shrink(),
                data: (doctor) => _buildContent(context, ref, user, doctor),
              ),
            ])),
          ),
        ],
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }

  // ── Header avec photo modifiable ─────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user,
      Map<String, dynamic>? doctor) {
    final avatarUrl = user?.avatarUrl as String?;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006B4E), Color(0xFF00A878)],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.only(top: 90, bottom: 16),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        // Photo avec bouton modifier
        GestureDetector(
          onTap: () => _showPhotoOptions(context, ref),
          child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipOval(child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(avatarUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsWidget(user))
                  : _initialsWidget(user)),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6)]),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.doctorPrimary, size: 14)),
          ]),
        ),
        const SizedBox(height: 10),

        Text('Dr. ${user?.fullName ?? ''}',
          style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 3),
        Text(doctor?['speciality'] as String? ?? user?.phone ?? '',
          style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 8),

        // Badge statut
        _buildStatusBadge(doctor?['status'] as String?),
        const SizedBox(height: 6),
      ]),
    );
  }

  Widget _initialsWidget(dynamic user) => Container(
    color: AppColors.doctorPrimary,
    child: Center(child: Text(user?.initials ?? 'Dr',
      style: const TextStyle(fontSize: 32,
          fontWeight: FontWeight.w800, color: Colors.white))));

  Widget _buildStatusBadge(String? status) {
    final configs = {
      'APPROVED':          {'label': '✓ Médecin certifié', 'color': const Color(0xFF10B981)},
      'PENDING_REVIEW':    {'label': '⏳ Dossier en examen', 'color': const Color(0xFFF59E0B)},
      'PENDING_INTERVIEW': {'label': '🎥 Interview planifiée', 'color': const Color(0xFF0066FF)},
      'PENDING_DOCS':      {'label': '📄 Documents requis', 'color': const Color(0xFF6B7280)},
    };
    final cfg = configs[status] ??
        {'label': '📋 Dossier en attente', 'color': const Color(0xFF6B7280)};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Text(cfg['label'] as String,
        style: const TextStyle(color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w600)));
  }

  // ── Contenu principal ────────────────────────────────────────
  Widget _buildContent(BuildContext context, WidgetRef ref,
      dynamic user, Map<String, dynamic> doctor) {
    return Column(children: [
      // Stats rapides
      Row(children: [
        _StatMini(
          value: '${doctor['totalConsults'] ?? 0}',
          label: 'Consultations',
          icon: Icons.medical_services_rounded,
          color: AppColors.doctorPrimary),
        const SizedBox(width: 10),
        _StatMini(
          value: doctor['averageRating'] != null &&
              (doctor['averageRating'] as num) > 0
              ? '${(doctor['averageRating'] as num).toStringAsFixed(1)}/10'
              : '—',
          label: 'Note moyenne',
          icon: Icons.star_rounded,
          color: const Color(0xFFF59E0B)),
        const SizedBox(width: 10),
        _StatMini(
          value: doctor['walletBalance'] != null
              ? '${((doctor['walletBalance'] as num) / 1000).toStringAsFixed(0)}k F'
              : '0 F',
          label: 'Wallet',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF8B5CF6)),
      ]),
      const SizedBox(height: 16),

      // Mon dossier
      _Section(title: 'Mon dossier FlashDoc', items: [
        _MenuItem(
          icon: Icons.folder_special_outlined,
          label: 'Statut de mon dossier',
          value: 'Voir l\'avancement',
          color: AppColors.doctorPrimary,
          onTap: () => context.push('/doctor/application-status')),
        _MenuItem(
          icon: Icons.edit_document,
          label: 'Modifier mon dossier',
          onTap: () => context.push('/doctor/onboarding')),
      ]),
      const SizedBox(height: 12),

      // Infos pro depuis le backend
      _Section(title: 'Informations professionnelles', items: [
        _MenuItem(
          icon: Icons.medical_services_outlined,
          label: 'Spécialité',
          value: doctor['speciality'] as String? ?? 'Non renseignée',
          onTap: () {}),
        _MenuItem(
          icon: Icons.badge_outlined,
          label: 'Numéro ONMC',
          value: doctor['onmcNumber'] as String? ?? 'Non renseigné',
          onTap: () {}),
        _MenuItem(
          icon: Icons.location_on_outlined,
          label: 'Ville',
          value: doctor['city'] as String? ?? 'Non renseignée',
          onTap: () {}),
        _MenuItem(
          icon: Icons.language_outlined,
          label: 'Langues',
          value: (doctor['languages'] as List?)?.join(', ') ?? 'fr',
          onTap: () {}),
      ]),
      const SizedBox(height: 12),

      // Photo de profil
      _Section(title: 'Photo de profil', items: [
        _MenuItem(
          icon: Icons.camera_alt_outlined,
          label: 'Modifier ma photo',
          value: 'Galerie ou appareil photo',
          color: AppColors.doctorPrimary,
          onTap: () => _showPhotoOptions(context, ref)),
      ]),
      const SizedBox(height: 12),

      // Paramètres
      _Section(title: 'Paramètres', items: [
        _MenuItem(icon: Icons.notifications_outlined,
            label: 'Notifications', onTap: () {}),
        _MenuItem(icon: Icons.help_outline,
            label: 'Support FlashDoc',
            value: 'support@flashdoc.cm',
            onTap: () => FdSnackbar.show(context, '📧 support@flashdoc.cm')),
        _MenuItem(icon: Icons.info_outline,
            label: 'FlashDoc v1.0.0', onTap: () {}),
      ]),
      const SizedBox(height: 12),

      // Déconnexion
      Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 20)),
          title: const Text('Se déconnecter',
            style: TextStyle(color: AppColors.error,
                fontWeight: FontWeight.w600, fontSize: 15)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.error, size: 18),
          onTap: () => _showLogout(context, ref),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }

  // ── Gestion photo ────────────────────────────────────────────
  void _showPhotoOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.doctorPrimary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_outlined,
                size: 30, color: AppColors.doctorPrimary)),
          const SizedBox(height: 12),
          const Text('Photo de profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Cette photo sera visible par les patients',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          _photoBtn(context, ref, Icons.camera_alt_outlined,
              'Prendre une photo', ImageSource.camera),
          const SizedBox(height: 10),
          _photoBtn(context, ref, Icons.photo_library_outlined,
              'Choisir depuis la galerie', ImageSource.gallery),
        ]),
      ),
    );
  }

  Widget _photoBtn(BuildContext context, WidgetRef ref,
      IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => _pickAndUpload(context, ref, source),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.doctorPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.doctorPrimary.withOpacity(0.2))),
        child: Row(children: [
          Icon(icon, color: AppColors.doctorPrimary, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref,
      ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked == null) return;
      if (context.mounted)
        FdSnackbar.show(context, 'Upload en cours...');
      await ApiService().uploadProfilePhoto(picked.path);
      ref.invalidate(doctorProfileDetailProvider);
      ref.invalidate(doctorStatsProvider);
      if (context.mounted)
        FdSnackbar.show(context, '✓ Photo mise à jour');
    } catch (e) {
      if (context.mounted)
        FdSnackbar.show(context, 'Erreur: $e', isError: true);
    }
  }

  void _showLogout(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Se déconnecter ?'),
      content: const Text('Vous devrez vous reconnecter à votre compte médecin.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, foregroundColor: Colors.white),
          child: const Text('Déconnecter')),
      ],
    ));
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _StatMini extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatMini({required this.value, required this.label,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10,
              color: AppColors.textSecondary),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    ));
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
            fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))]),
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
        child: Icon(icon, color: c, size: 18)),
      title: Text(label, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (value != null) Flexible(child: Text(value!,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
      ]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
