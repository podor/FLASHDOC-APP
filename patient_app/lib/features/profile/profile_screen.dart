// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/fd_snackbar.dart';
import '../home/home_screen.dart';

// ── Provider profil patient complet ──────────────────────────────
final patientProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().getPatientProfile();
    if (res['success'] == true) {
      return res['data']['patient'] as Map<String, dynamic>? ?? {};
    }
  } catch (_) {}
  return {};
});

// ── Modèle profil ─────────────────────────────────────────────────
class _PatientProfile {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String? birthDate;
  final String? gender;
  final String? bloodType;
  final String? city;
  final List<String> allergies;
  final int totalConsultations;
  final String? avatarUrl;
  final int completedConsultations;

  _PatientProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.birthDate,
    this.gender,
    this.bloodType,
    this.city,
    required this.allergies,
    required this.totalConsultations,
    required this.completedConsultations,
    this.avatarUrl,
  });

  double get completionRate {
    int filled = 0;
    if (firstName.isNotEmpty) filled++;
    if (lastName.isNotEmpty)  filled++;
    if (email.isNotEmpty)     filled++;
    if (birthDate != null)    filled++;
    if (gender != null)       filled++;
    if (bloodType != null)    filled++;
    if (city?.isNotEmpty == true) filled++;
    return filled / 7;
  }

  factory _PatientProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final allergiesRaw = json['allergies'] as List? ?? [];
    return _PatientProfile(
      firstName:             user['firstName']             as String? ?? '',
      lastName:              user['lastName']              as String? ?? '',
      phone:                 user['phone']                 as String? ?? '',
      email:                 user['email']                 as String? ?? '',
      birthDate:             json['birthDate']             as String?,
      gender:                json['gender']                as String?,
      bloodType:             json['bloodType']             as String?,
      city:                  json['city']                  as String?,
      allergies:             allergiesRaw.map((e) => e.toString()).toList(),
      totalConsultations:    json['totalConsultations']    as int? ?? 0,
      completedConsultations:json['completedConsultations']as int? ?? 0,
      avatarUrl:             user['avatarUrl']             as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty  ? lastName[0]  : '';
    return '$f$l'.toUpperCase();
  }
  String get allergiesDisplay =>
      allergies.isEmpty ? 'Aucune allergie connue' : allergies.join(', ');
  String get genderDisplay {
    switch (gender) {
      case 'MALE':   return 'Homme';
      case 'FEMALE': return 'Femme';
      case 'OTHER':  return 'Autre';
      default:       return 'Non renseigné';
    }
  }
  String get birthDateDisplay {
    if (birthDate == null) return 'Non renseignée';
    try {
      final dt = DateTime.parse(birthDate!);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) { return birthDate!; }
  }
  int? get age {
    if (birthDate == null) return null;
    try {
      final dt  = DateTime.parse(birthDate!);
      final now = DateTime.now();
      int a = now.year - dt.year;
      if (now.month < dt.month ||
          (now.month == dt.month && now.day < dt.day)) a--;
      return a;
    } catch (_) { return null; }
  }
}

// ─────────────────────────────────────────────────────────────────
// ÉCRAN PROFIL
// ─────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 2),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(
            color: AppColors.primary)),
        error: (_, __) => _ProfileBody(profile: null),
        data: (data) {
          final profile = data.isNotEmpty
              ? _PatientProfile.fromJson(data) : null;
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CORPS DU PROFIL
// ─────────────────────────────────────────────────────────────────
class _ProfileBody extends ConsumerWidget {
  final _PatientProfile? profile;
  const _ProfileBody({required this.profile});

  Future<void> _saveField(BuildContext context, WidgetRef ref,
      Map<String, dynamic> data, String successMsg) async {
    try {
      await ApiService().updatePatientProfile(data);
      ref.invalidate(patientProfileProvider);

      if (data.containsKey('firstName') || data.containsKey('lastName') ||
          data.containsKey('email')) {
        final user = ref.read(authProvider).user;
        if (user != null) {
          final updated = user.copyWith(
            firstName: data['firstName'] as String? ?? user.firstName,
            lastName:  data['lastName']  as String? ?? user.lastName,
            email:     data['email']     as String? ?? user.email,
          );
          await StorageService().saveUser(updated);
        }
      }
      if (context.mounted) FdSnackbar.show(context, successMsg);
    } catch (_) {
      if (context.mounted)
        FdSnackbar.show(context, 'Erreur de sauvegarde', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          // ✅ expandedHeight augmenté pour éviter overflow du header
          expandedHeight: 310,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => ref.invalidate(patientProfileProvider),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _ProfileHeader(
              profile: profile,
              onChangePhoto: () => _showPhotoOptions(context, ref),
            ),
          ),
          title: Text(profile?.fullName ?? 'Mon profil',
            style: const TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w600)),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              if (profile != null && profile!.completionRate < 1.0) ...[
                _CompletionCard(rate: profile!.completionRate),
                const SizedBox(height: 16),
              ],

              if (profile != null) ...[
                _StatsRow(profile: profile!),
                const SizedBox(height: 16),
              ],

              // ── Informations personnelles ──────────────────
              _SectionCard(
                title: 'Informations personnelles',
                subtitle: 'Champs obligatoires *',
                icon: Icons.person_rounded,
                color: AppColors.primary,
                children: [
                  _EditableField(
                    label: 'Prénom *', value: profile?.firstName ?? '',
                    icon: Icons.badge_outlined, placeholder: 'Entrez votre prénom',
                    isRequired: true, isEmpty: profile?.firstName.isEmpty ?? true,
                    onEdit: () => _showEditDialog(context: context, ref: ref,
                      title: 'Prénom', currentValue: profile?.firstName ?? '',
                      hint: 'Votre prénom', isRequired: true,
                      onSave: (v) => _saveField(context, ref, {'firstName': v}, 'Prénom mis à jour ✓')),
                  ),
                  _EditableField(
                    label: 'Nom *', value: profile?.lastName ?? '',
                    icon: Icons.person_outline, placeholder: 'Entrez votre nom',
                    isRequired: true, isEmpty: profile?.lastName.isEmpty ?? true,
                    onEdit: () => _showEditDialog(context: context, ref: ref,
                      title: 'Nom de famille', currentValue: profile?.lastName ?? '',
                      hint: 'Votre nom', isRequired: true,
                      onSave: (v) => _saveField(context, ref, {'lastName': v}, 'Nom mis à jour ✓')),
                  ),
                  _ReadOnlyField(label: 'Téléphone', value: profile?.phone ?? '',
                    icon: Icons.phone_outlined, info: 'Non modifiable'),
                  _EditableField(
                    label: 'Email *', value: profile?.email ?? '',
                    icon: Icons.email_outlined, placeholder: 'votre@email.com',
                    isRequired: true, isEmpty: profile?.email.isEmpty ?? true,
                    onEdit: () => _showEditDialog(context: context, ref: ref,
                      title: 'Adresse email', currentValue: profile?.email ?? '',
                      hint: 'votre@email.com', keyboardType: TextInputType.emailAddress,
                      isRequired: true,
                      validator: (v) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                          return 'Email invalide';
                        return null;
                      },
                      onSave: (v) => _saveField(context, ref, {'email': v}, 'Email mis à jour ✓')),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Informations médicales ─────────────────────
              _SectionCard(
                title: 'Informations médicales',
                subtitle: 'Importantes pour votre suivi',
                icon: Icons.medical_information_outlined,
                color: AppColors.secondary,
                children: [
                  _EditableField(
                    label: 'Date de naissance *', value: profile?.birthDateDisplay ?? '',
                    icon: Icons.cake_outlined, placeholder: 'JJ/MM/AAAA',
                    isRequired: true, isEmpty: profile?.birthDate == null,
                    onEdit: () => _showDatePicker(context, ref, profile?.birthDate)),
                  _EditableField(
                    label: 'Genre *', value: profile?.genderDisplay ?? '',
                    icon: Icons.wc_outlined, placeholder: 'Sélectionner',
                    isRequired: true, isEmpty: profile?.gender == null,
                    onEdit: () => _showGenderSelector(context, ref)),
                  _EditableField(
                    label: 'Groupe sanguin *', value: profile?.bloodType ?? '',
                    icon: Icons.bloodtype_outlined, placeholder: 'Ex : A+',
                    isRequired: true, isEmpty: profile?.bloodType == null,
                    onEdit: () => _showBloodTypeSelector(context, ref)),
                  _EditableField(
                    label: 'Ville', value: profile?.city ?? '',
                    icon: Icons.location_on_outlined, placeholder: 'Ex : Douala',
                    onEdit: () => _showEditDialog(context: context, ref: ref,
                      title: 'Votre ville', currentValue: profile?.city ?? '',
                      hint: 'Ex : Douala, Yaoundé...',
                      onSave: (v) => _saveField(context, ref, {'city': v}, 'Ville mise à jour ✓'))),
                  _EditableField(
                    label: 'Allergies', value: profile?.allergiesDisplay ?? '',
                    icon: Icons.warning_amber_outlined,
                    placeholder: 'Ex : Pénicilline, arachides...',
                    onEdit: () => _showEditDialog(context: context, ref: ref,
                      title: 'Allergies connues',
                      currentValue: profile?.allergies.join(', ') ?? '',
                      hint: 'Séparez par des virgules',
                      helperText: 'Ex : Pénicilline, Arachides, Lactose',
                      maxLines: 3,
                      onSave: (v) => _saveField(context, ref, {'allergies': v}, 'Allergies mises à jour ✓'))),
                ],
              ),
              const SizedBox(height: 16),

              // ── Activité ───────────────────────────────────
              _SectionCard(
                title: 'Mon activité',
                subtitle: 'Historique et documents',
                icon: Icons.history_rounded,
                color: AppColors.warning,
                children: [
                  _NavigationField(
                    label: 'Mes consultations', icon: Icons.medical_services_outlined,
                    badge: profile?.totalConsultations.toString(), badgeColor: AppColors.primary,
                    onTap: () => context.go('/patient/history')),
                  _NavigationField(
                    label: 'Consultations terminées', icon: Icons.check_circle_outline,
                    badge: profile?.completedConsultations.toString(), badgeColor: AppColors.success,
                    onTap: () => context.go('/patient/history')),
                  _NavigationField(label: 'Mes ordonnances',
                    icon: Icons.description_outlined, onTap: () => context.go('/patient/history')),
                ],
              ),
              const SizedBox(height: 16),

              // ── Paramètres ────────────────────────────────
              _SectionCard(
                title: 'Paramètres',
                subtitle: 'Sécurité et préférences',
                icon: Icons.settings_outlined,
                color: AppColors.textSecondary,
                children: [
                  _NavigationField(label: 'Changer le mot de passe',
                    icon: Icons.lock_outline,
                    onTap: () => _showPasswordDialog(context, ref)),
                  _NavigationField(
                    label: 'Notifications', icon: Icons.notifications_outlined,
                    trailing: Switch(value: true,
                      onChanged: (_) => FdSnackbar.show(context, 'Disponible prochainement'),
                      activeColor: AppColors.primary),
                    onTap: null),
                  _NavigationField(label: 'Support FlashDoc',
                    icon: Icons.support_agent_outlined, subtitle: 'support@flashdoc.cm',
                    onTap: () => FdSnackbar.show(context, '📧 support@flashdoc.cm')),
                  _NavigationField(label: "Conditions d'utilisation",
                    icon: Icons.article_outlined,
                    onTap: () => FdSnackbar.show(context, 'Disponible prochainement')),
                  _NavigationField(label: 'Politique de confidentialité',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => FdSnackbar.show(context, 'Disponible prochainement')),
                ],
              ),
              const SizedBox(height: 16),

              // ── Déconnexion ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20)),
                  title: const Text('Se déconnecter',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.error, size: 20),
                  onTap: () => _showLogoutConfirm(context, ref),
                ),
              ),
              const SizedBox(height: 24),

              const Center(child: Text(
                'FlashDoc v1.0.0 — Tchouk Head Corporation\nCameroun © 2024',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.6))),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _sheetHandle() => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)));

  void _showPhotoOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(), const SizedBox(height: 20),
          const Text('Photo de profil', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _sheetBtn(context, Icons.camera_alt_outlined, 'Prendre une photo',
              () => _pickAndUploadPhoto(context, ref, ImageSource.camera)),
          const SizedBox(height: 10),
          _sheetBtn(context, Icons.photo_library_outlined, 'Galerie photo',
              () => _pickAndUploadPhoto(context, ref, ImageSource.gallery)),
          const SizedBox(height: 16),
        ])));
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref, ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked == null) return;
      if (context.mounted) FdSnackbar.show(context, 'Upload en cours...');
      await ApiService().uploadProfilePhoto(picked.path);
      ref.invalidate(patientProfileProvider);
      if (context.mounted) FdSnackbar.show(context, 'Photo mise à jour ✓');
    } catch (e) {
      if (context.mounted) FdSnackbar.show(context, 'Erreur: $e', isError: true);
    }
  }

  Widget _sheetBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 22), const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ])));

  void _showEditDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String currentValue,
    required String hint,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    String? helperText,
    int maxLines = 1,
    String? Function(String)? validator,
  }) {
    final ctrl = TextEditingController(text: currentValue);
    String? error;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(), const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              if (isRequired) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Obligatoire', style: TextStyle(fontSize: 11,
                    color: AppColors.error, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl, keyboardType: keyboardType,
              maxLines: maxLines, autofocus: true,
              decoration: InputDecoration(
                hintText: hint, helperText: helperText, errorText: error,
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true, fillColor: AppColors.surfaceGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final val = ctrl.text.trim();
                  if (isRequired && val.isEmpty) { setS(() => error = 'Ce champ est obligatoire'); return; }
                  if (validator != null) { final err = validator(val); if (err != null) { setS(() => error = err); return; } }
                  Navigator.pop(ctx); onSave(val);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.w700)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref, String? currentDate) async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (currentDate != null) { try { initial = DateTime.parse(currentDate); } catch (_) {} }
    final picked = await showDatePicker(
      context: context, initialDate: initial,
      firstDate: DateTime(1920), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!));
    if (picked != null && context.mounted) {
      await _saveField(context, ref, {'birthDate': picked.toIso8601String()}, 'Date de naissance mise à jour ✓');
    }
  }

  void _showGenderSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(), const SizedBox(height: 20),
          const Text('Genre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          ...[
            {'id': 'MALE', 'label': 'Homme', 'emoji': '👨'},
            {'id': 'FEMALE', 'label': 'Femme', 'emoji': '👩'},
            {'id': 'OTHER', 'label': 'Autre', 'emoji': '🧑'},
          ].map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () { Navigator.pop(context); _saveField(context, ref, {'gender': g['id']!}, 'Genre mis à jour ✓'); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Text(g['emoji']!, style: const TextStyle(fontSize: 24)), const SizedBox(width: 16),
                  Text(g['label']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ]),
              ),
            ))),
          const SizedBox(height: 8),
        ])));
  }

  void _showBloodTypeSelector(BuildContext context, WidgetRef ref) {
    const types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    showModalBottomSheet(context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(), const SizedBox(height: 20),
          const Text('Groupe sanguin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text("Information cruciale en cas d'urgence", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: types.map((t) =>
            GestureDetector(
              onTap: () { Navigator.pop(context); _saveField(context, ref, {'bloodType': t}, 'Groupe sanguin : $t ✓'); },
              child: Container(width: 72, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                child: Center(child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)))),
            )).toList()),
          const SizedBox(height: 16),
        ])));
  }

  void _showPasswordDialog(BuildContext context, WidgetRef ref) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool showOld = false, showNew = false, showConf = false;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(), const SizedBox(height: 20),
            const Text('Changer le mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _PasswordField(ctrl: oldCtrl, label: 'Mot de passe actuel', show: showOld, onToggle: () => setS(() => showOld = !showOld)),
            const SizedBox(height: 12),
            _PasswordField(ctrl: newCtrl, label: 'Nouveau (8+ caractères)', show: showNew, onToggle: () => setS(() => showNew = !showNew)),
            const SizedBox(height: 12),
            _PasswordField(ctrl: confCtrl, label: 'Confirmer le nouveau', show: showConf, onToggle: () => setS(() => showConf = !showConf)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text.length < 8) { FdSnackbar.show(ctx, '8 caractères minimum', isError: true); return; }
                  if (newCtrl.text != confCtrl.text) { FdSnackbar.show(ctx, 'Les mots de passe ne correspondent pas', isError: true); return; }
                  Navigator.pop(ctx);
                  await _saveField(context, ref, {'password': newCtrl.text}, 'Mot de passe modifié ✓');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Modifier le mot de passe', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))),
          ]),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Se déconnecter ?'),
      content: const Text('Vous devrez vous reconnecter pour accéder à votre compte.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async { Navigator.pop(context); await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          child: const Text('Déconnecter')),
      ],
    ));
  }
}

// ─────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final _PatientProfile? profile;
  final VoidCallback onChangePhoto;
  const _ProfileHeader({required this.profile, required this.onChangePhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      // ✅ padding ajusté pour éviter overflow (top: 88, bottom: 12)
      padding: const EdgeInsets.only(top: 88, bottom: 12),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        GestureDetector(
          onTap: onChangePhoto,
          child: Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withOpacity(0.2),
              // ✅ Afficher la vraie photo si disponible, sinon les initiales
              backgroundImage: (profile?.avatarUrl != null &&
                      profile!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: (profile?.avatarUrl == null ||
                      profile!.avatarUrl!.isEmpty)
                  ? Text(profile?.initials ?? '?',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))
                  : null,
            ),
            Container(padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 14)),
          ]),
        ),
        const SizedBox(height: 8),
        Text(profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Mon profil',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(profile?.phone ?? '', style: const TextStyle(fontSize: 13, color: Colors.white70)),
        if (profile?.age != null) ...[
          const SizedBox(height: 2),
          Text('${profile!.age} ans · ${profile!.genderDisplay}',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, color: Colors.white, size: 15),
            SizedBox(width: 5),
            Text('Patient vérifié', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS COMMUNS
// ─────────────────────────────────────────────────────────────────
class _CompletionCard extends StatelessWidget {
  final double rate;
  const _CompletionCard({required this.rate});
  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Complétez votre profil ($pct%)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Text('$pct%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: rate, minHeight: 6, backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.warning))),
        const SizedBox(height: 8),
        const Text('Un profil complet améliore la qualité de vos consultations.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _PatientProfile profile;
  const _StatsRow({required this.profile});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _StatBox(value: profile.totalConsultations.toString(),
        label: 'Consultations', icon: Icons.medical_services_outlined, color: AppColors.primary)),
    const SizedBox(width: 12),
    Expanded(child: _StatBox(value: profile.completedConsultations.toString(),
        label: 'Terminées', icon: Icons.check_circle_outline, color: AppColors.success)),
    const SizedBox(width: 12),
    Expanded(child: _StatBox(value: profile.bloodType ?? '?',
        label: 'Groupe sang.', icon: Icons.bloodtype_outlined, color: AppColors.error)),
  ]);
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: [
      Icon(icon, color: color, size: 22), const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.subtitle,
      required this.icon, required this.color, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ])),
      const Divider(height: 1, color: AppColors.border),
      ...List.generate(children.length, (i) => Column(children: [
        children[i],
        if (i < children.length - 1) const Divider(height: 1, indent: 52, color: AppColors.border),
      ])),
    ]),
  );
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String placeholder;
  final bool isRequired;
  final bool isEmpty;
  final VoidCallback onEdit;
  const _EditableField({required this.label, required this.value,
      required this.icon, required this.placeholder, required this.onEdit,
      this.isRequired = false, this.isEmpty = false});
  @override
  Widget build(BuildContext context) {
    final isMissing = isRequired && isEmpty;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMissing ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isMissing ? AppColors.error : AppColors.primary, size: 18)),
      title: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
        if (isMissing) Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: const Text('Requis', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600))),
      ]),
      subtitle: Text(isEmpty ? placeholder : value,
        style: TextStyle(fontSize: 14,
          fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
          color: isEmpty ? AppColors.textHint : AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: isMissing ? AppColors.error : AppColors.textHint, size: 18),
      onTap: onEdit,
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? info;
  const _ReadOnlyField({required this.label, required this.value, required this.icon, this.info});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.textSecondary, size: 18)),
    title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
    subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    trailing: info != null ? Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
      Text(info!, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]) : null,
  );
}

class _NavigationField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _NavigationField({required this.label, required this.icon,
      this.badge, this.badgeColor, this.subtitle, this.trailing, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primary, size: 18)),
    title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
    trailing: trailing ?? Row(mainAxisSize: MainAxisSize.min, children: [
      if (badge != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: (badgeColor ?? AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(badge!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor ?? AppColors.primary))),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
    ]),
    onTap: onTap,
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  const _PasswordField({required this.ctrl, required this.label, required this.show, required this.onToggle});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, obscureText: !show,
    decoration: InputDecoration(
      labelText: label, filled: true, fillColor: AppColors.surfaceGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      suffixIcon: IconButton(
        icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: AppColors.textHint),
        onPressed: onToggle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
  );
}
