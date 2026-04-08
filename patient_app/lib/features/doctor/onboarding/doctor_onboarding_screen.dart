// lib/features/doctor/onboarding/doctor_onboarding_screen.dart
// ═══════════════════════════════════════════════════════════════
// Onboarding médecin — 5 étapes
// 1. Informations personnelles
// 2. Informations professionnelles
// 3. Upload documents
// 4. Disponibilités
// 5. Récapitulatif + soumission
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/fd_snackbar.dart';

// ── Modèle dossier médecin ────────────────────────────────────
class _DoctorDossier {
  // Étape 1 — Perso
  String firstName   = '';
  String lastName    = '';
  String phone       = '';
  String email       = '';
  String city        = '';
  String birthDate   = '';
  String gender      = '';
  XFile? selfiePhoto;

  // Étape 2 — Pro
  String speciality  = '';
  String onmcNumber  = '';
  String hospital    = '';
  int    experience  = 0;
  List<String> languages = ['fr'];
  String bio         = '';

  // Étape 3 — Documents
  XFile? diplomeMedecine;
  XFile? carteOnmc;
  XFile? diplomeSpecialite;
  XFile? pieceIdentite;

  // Étape 4 — Disponibilités
  Map<String, bool> availableDays = {
    'Lundi': true, 'Mardi': true, 'Mercredi': true,
    'Jeudi': true,  'Vendredi': true, 'Samedi': false, 'Dimanche': false,
  };
  String startTime = '08:00';
  String endTime   = '18:00';
  int consultationsPerDay = 8;
}

class DoctorOnboardingScreen extends ConsumerStatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  ConsumerState<DoctorOnboardingScreen> createState() =>
      _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState
    extends ConsumerState<DoctorOnboardingScreen> {
  final _pageCtrl  = PageController();
  final _dossier   = _DoctorDossier();
  final _picker    = ImagePicker();
  int   _currentStep = 0;
  bool  _isSubmitting = false;

  static const _steps = [
    'Informations\npersonnelles',
    'Informations\nprofessionnelles',
    'Documents\nrequis',
    'Disponibilités',
    'Récapitulatif',
  ];

  // ── Navigation ────────────────────────────────────────────────
  void _next() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < _steps.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  // ── Validation par étape ──────────────────────────────────────
  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_dossier.firstName.isEmpty || _dossier.lastName.isEmpty) {
          FdSnackbar.show(context, 'Prénom et nom obligatoires', isError: true);
          return false;
        }
        if (_dossier.phone.isEmpty) {
          FdSnackbar.show(context, 'Téléphone obligatoire', isError: true);
          return false;
        }
        return true;
      case 1:
        if (_dossier.speciality.isEmpty) {
          FdSnackbar.show(context, 'Sélectionnez une spécialité', isError: true);
          return false;
        }
        if (_dossier.onmcNumber.isEmpty) {
          FdSnackbar.show(context, 'Numéro ONMC obligatoire', isError: true);
          return false;
        }
        return true;
      case 2:
        if (_dossier.diplomeMedecine == null) {
          FdSnackbar.show(context, 'Diplôme de médecine obligatoire',
              isError: true);
          return false;
        }
        if (_dossier.carteOnmc == null) {
          FdSnackbar.show(context, 'Carte ONMC obligatoire', isError: true);
          return false;
        }
        if (_dossier.pieceIdentite == null) {
          FdSnackbar.show(context, 'Pièce d\'identité obligatoire',
              isError: true);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  // ── Upload photo ──────────────────────────────────────────────
  Future<XFile?> _pickFile({bool isPhoto = false}) async {
    try {
      if (isPhoto) {
        return await _picker.pickImage(
            source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      } else {
        // Pour les documents — utiliser galerie (supporte PDF via image_picker)
        return await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 90);
      }
    } catch (_) {
      return null;
    }
  }

  // ── Soumission finale ──────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      // ── 1. Soumettre les infos du dossier ──────────────────────
      await ApiService().submitDoctorApplication(dossier: {
        'firstName':           _dossier.firstName,
        'lastName':            _dossier.lastName,
        'phone':               _dossier.phone,
        'email':               _dossier.email,
        'city':                _dossier.city,
        'birthDate':           _dossier.birthDate,
        'gender':              _dossier.gender,
        'speciality':          _dossier.speciality,
        'onmcNumber':          _dossier.onmcNumber,
        'hospital':            _dossier.hospital,
        'experience':          _dossier.experience,
        'languages':           _dossier.languages,
        'bio':                 _dossier.bio,
        'consultationsPerDay': _dossier.consultationsPerDay,
        'availableDays':       _dossier.availableDays,
        'startTime':           _dossier.startTime,
        'endTime':             _dossier.endTime,
      });

      // ── 2. Uploader les documents si présents ──────────────────
      final filesToUpload = <String, String>{};
      if (_dossier.selfiePhoto       != null) filesToUpload['selfie']     = _dossier.selfiePhoto!.path;
      if (_dossier.diplomeMedecine   != null) filesToUpload['diplome']    = _dossier.diplomeMedecine!.path;
      if (_dossier.carteOnmc         != null) filesToUpload['onmc']       = _dossier.carteOnmc!.path;
      if (_dossier.diplomeSpecialite != null) filesToUpload['specialite'] = _dossier.diplomeSpecialite!.path;
      if (_dossier.pieceIdentite     != null) filesToUpload['cni']        = _dossier.pieceIdentite!.path;

      if (filesToUpload.isNotEmpty) {
        await ApiService().uploadDoctorDocuments(filesToUpload);
      }

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        FdSnackbar.show(context, 'Erreur lors de la soumission : $e',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 44)),
          const SizedBox(height: 20),
          const Text('Dossier soumis !',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Votre dossier est en cours de vérification.\n\n'
            'Notre équipe va :\n'
            '① Vérifier vos documents (24-48h)\n'
            '② Valider votre numéro ONMC\n'
            '③ Vous contacter pour l\'interview\n\n'
            'Vous serez notifié par SMS à chaque étape.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                height: 1.6)),
          const SizedBox(height: 20),
          const Text('Délai estimé : 3 à 5 jours ouvrés',
            style: TextStyle(fontSize: 12, color: AppColors.textHint,
                fontStyle: FontStyle.italic)),
        ]),
        actions: [
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/doctor/home');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.doctorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Compris',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.textPrimary),
                onPressed: _prev)
            : IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => context.go('/doctor/home')),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Étape ${_currentStep + 1} sur ${_steps.length}',
            style: const TextStyle(fontSize: 12,
                color: AppColors.textSecondary)),
          Text(_steps[_currentStep].replaceAll('\n', ' '),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: _StepProgressBar(
              current: _currentStep, total: _steps.length),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1Perso(dossier: _dossier, picker: _picker,
              onUpdate: () => setState(() {})),
          _Step2Pro(dossier: _dossier, onUpdate: () => setState(() {})),
          _Step3Docs(dossier: _dossier, onPickFile: _pickFile,
              onUpdate: () => setState(() {})),
          _Step4Disponibilites(dossier: _dossier,
              onUpdate: () => setState(() {})),
          _Step5Recap(dossier: _dossier),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _currentStep == _steps.length - 1
                          ? 'Soumettre mon dossier'
                          : 'Continuer',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 1 — Informations personnelles
// ═══════════════════════════════════════════════════════════════
class _Step1Perso extends StatefulWidget {
  final _DoctorDossier dossier;
  final ImagePicker picker;
  final VoidCallback onUpdate;
  const _Step1Perso(
      {required this.dossier, required this.picker, required this.onUpdate});

  @override
  State<_Step1Perso> createState() => _Step1PersoState();
}

class _Step1PersoState extends State<_Step1Perso> {
  final _firstCtrl  = TextEditingController();
  final _lastCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _cityCtrl   = TextEditingController();
  String _gender    = '';

  @override
  void initState() {
    super.initState();
    _firstCtrl.text = widget.dossier.firstName;
    _lastCtrl.text  = widget.dossier.lastName;
    _phoneCtrl.text = widget.dossier.phone;
    _emailCtrl.text = widget.dossier.email;
    _cityCtrl.text  = widget.dossier.city;
    _gender         = widget.dossier.gender;
  }

  void _save() {
    widget.dossier.firstName = _firstCtrl.text.trim();
    widget.dossier.lastName  = _lastCtrl.text.trim();
    widget.dossier.phone     = _phoneCtrl.text.trim();
    widget.dossier.email     = _emailCtrl.text.trim();
    widget.dossier.city      = _cityCtrl.text.trim();
    widget.dossier.gender    = _gender;
    widget.onUpdate();
  }

  Future<void> _pickSelfie() async {
    final img = await widget.picker.pickImage(
        source: ImageSource.camera, maxWidth: 600, imageQuality: 85);
    if (img != null) {
      widget.dossier.selfiePhoto = img;
      widget.onUpdate();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepHeader(
          icon: Icons.person_outline,
          title: 'Qui êtes-vous ?',
          subtitle: 'Ces informations seront visibles par les patients.',
        ),
        const SizedBox(height: 24),

        // Photo selfie
        Center(child: GestureDetector(
          onTap: _pickSelfie,
          child: Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.doctorLight,
              backgroundImage: widget.dossier.selfiePhoto != null
                  ? FileImage(File(widget.dossier.selfiePhoto!.path))
                  : null,
              child: widget.dossier.selfiePhoto == null
                  ? const Icon(Icons.person_rounded,
                      size: 50, color: AppColors.doctorPrimary)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: AppColors.doctorPrimary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ]),
        )),
        const SizedBox(height: 6),
        const Center(child: Text('Photo de profil (optionnel)',
          style: TextStyle(fontSize: 12, color: AppColors.textHint))),
        const SizedBox(height: 24),

        // Prénom / Nom
        Row(children: [
          Expanded(child: _Field(ctrl: _firstCtrl, label: 'Prénom *',
              hint: 'Jean', onChanged: (_) => _save())),
          const SizedBox(width: 12),
          Expanded(child: _Field(ctrl: _lastCtrl, label: 'Nom *',
              hint: 'Mballa', onChanged: (_) => _save())),
        ]),
        const SizedBox(height: 14),

        _Field(ctrl: _phoneCtrl, label: 'Téléphone *',
            hint: '+237 6XX XXX XXX',
            keyboardType: TextInputType.phone,
            onChanged: (_) => _save()),
        const SizedBox(height: 14),

        _Field(ctrl: _emailCtrl, label: 'Email professionnel *',
            hint: 'dr.jean@exemple.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _save()),
        const SizedBox(height: 14),

        _Field(ctrl: _cityCtrl, label: 'Ville d\'exercice *',
            hint: 'Douala', onChanged: (_) => _save()),
        const SizedBox(height: 16),

        // Genre
        const Text('Genre', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          _GenderChip(label: 'Homme', value: 'MALE',
              selected: _gender == 'MALE',
              onTap: () { setState(() => _gender = 'MALE'); _save(); }),
          const SizedBox(width: 10),
          _GenderChip(label: 'Femme', value: 'FEMALE',
              selected: _gender == 'FEMALE',
              onTap: () { setState(() => _gender = 'FEMALE'); _save(); }),
        ]),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 2 — Informations professionnelles
// ═══════════════════════════════════════════════════════════════
class _Step2Pro extends StatefulWidget {
  final _DoctorDossier dossier;
  final VoidCallback onUpdate;
  const _Step2Pro({required this.dossier, required this.onUpdate});

  @override
  State<_Step2Pro> createState() => _Step2ProState();
}

class _Step2ProState extends State<_Step2Pro> {
  final _onmcCtrl     = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  String _speciality  = '';
  int    _experience  = 0;
  List<String> _languages = ['fr'];

  @override
  void initState() {
    super.initState();
    _onmcCtrl.text     = widget.dossier.onmcNumber;
    _hospitalCtrl.text = widget.dossier.hospital;
    _bioCtrl.text      = widget.dossier.bio;
    _speciality        = widget.dossier.speciality;
    _experience        = widget.dossier.experience;
    _languages         = List.from(widget.dossier.languages);
  }

  void _save() {
    widget.dossier.onmcNumber  = _onmcCtrl.text.trim();
    widget.dossier.hospital    = _hospitalCtrl.text.trim();
    widget.dossier.bio         = _bioCtrl.text.trim();
    widget.dossier.speciality  = _speciality;
    widget.dossier.experience  = _experience;
    widget.dossier.languages   = _languages;
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepHeader(
          icon: Icons.medical_services_outlined,
          title: 'Votre parcours médical',
          subtitle: 'Informations professionnelles vérifiées par FlashDoc.',
        ),
        const SizedBox(height: 24),

        // Spécialité
        const Text('Spécialité *', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8,
          children: AppConstants.specialities.map((s) => ChoiceChip(
            label: Text(s, style: TextStyle(fontSize: 12,
                fontWeight: _speciality == s
                    ? FontWeight.w700 : FontWeight.w400,
                color: _speciality == s
                    ? AppColors.doctorPrimary : AppColors.textSecondary)),
            selected: _speciality == s,
            onSelected: (_) => setState(() { _speciality = s; _save(); }),
            selectedColor: AppColors.doctorLight,
            checkmarkColor: AppColors.doctorPrimary,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _speciality == s
                    ? AppColors.doctorPrimary : AppColors.border)),
          )).toList()),
        const SizedBox(height: 16),

        // Numéro ONMC
        _Field(ctrl: _onmcCtrl,
            label: 'Numéro ONMC *',
            hint: 'Ex: CM-001234',
            onChanged: (_) => _save(),
            suffixIcon: const Icon(Icons.verified_outlined,
                color: AppColors.textHint, size: 18)),
        const SizedBox(height: 6),
        const Row(children: [
          Icon(Icons.info_outline, size: 13, color: AppColors.textHint),
          SizedBox(width: 4),
          Text('Ce numéro sera vérifié auprès de l\'ONMC',
            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 14),

        _Field(ctrl: _hospitalCtrl,
            label: 'Établissement / Cabinet',
            hint: 'Hôpital Général de Douala',
            onChanged: (_) => _save()),
        const SizedBox(height: 14),

        // Années d'expérience
        const Text("Années d'expérience", style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          IconButton(
            onPressed: () { if (_experience > 0) setState(() { _experience--; _save(); }); },
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.doctorPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$_experience ans',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          IconButton(
            onPressed: () => setState(() { _experience++; _save(); }),
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.doctorPrimary)),
        ]),
        const SizedBox(height: 14),

        // Langues
        const Text('Langues parlées', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: ['fr', 'en', 'de', 'ar'].map((lang) {
          final labels = {'fr': 'Français', 'en': 'Anglais',
              'de': 'Allemand', 'ar': 'Arabe'};
          final selected = _languages.contains(lang);
          return FilterChip(
            label: Text(labels[lang] ?? lang),
            selected: selected,
            onSelected: (_) {
              setState(() {
                if (selected && _languages.length > 1) {
                  _languages.remove(lang);
                } else if (!selected) {
                  _languages.add(lang);
                }
                _save();
              });
            },
            selectedColor: AppColors.doctorLight,
            checkmarkColor: AppColors.doctorPrimary,
            labelStyle: TextStyle(fontSize: 12,
                color: selected ? AppColors.doctorPrimary
                    : AppColors.textSecondary),
          );
        }).toList()),
        const SizedBox(height: 14),

        // Bio
        const Text('Présentation (optionnel)', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: TextField(
            controller: _bioCtrl, maxLines: 4,
            onChanged: (_) => _save(),
            decoration: const InputDecoration(
              hintText: 'Décrivez brièvement votre parcours et vos domaines de compétence...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
              border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 3 — Documents requis
// ═══════════════════════════════════════════════════════════════
class _Step3Docs extends StatefulWidget {
  final _DoctorDossier dossier;
  final Future<XFile?> Function({bool isPhoto}) onPickFile;
  final VoidCallback onUpdate;
  const _Step3Docs(
      {required this.dossier, required this.onPickFile, required this.onUpdate});

  @override
  State<_Step3Docs> createState() => _Step3DocsState();
}

class _Step3DocsState extends State<_Step3Docs> {
  Future<void> _pick(String docType) async {
    final file = await widget.onPickFile();
    if (file == null) return;
    setState(() {
      switch (docType) {
        case 'diplome':   widget.dossier.diplomeMedecine    = file; break;
        case 'onmc':      widget.dossier.carteOnmc          = file; break;
        case 'specialite':widget.dossier.diplomeSpecialite  = file; break;
        case 'cni':       widget.dossier.pieceIdentite      = file; break;
      }
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepHeader(
          icon: Icons.folder_outlined,
          title: 'Documents à fournir',
          subtitle: 'Les documents seront vérifiés par notre équipe '
              'sous 24-48h. Formats acceptés : JPG, PNG, PDF.',
        ),
        const SizedBox(height: 8),

        // Avertissement
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.3))),
          child: const Row(children: [
            Icon(Icons.lock_outline, color: AppColors.warning, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Vos documents sont chiffrés et ne seront jamais partagés '
              'avec des tiers. Ils servent uniquement à la vérification.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary,
                  height: 1.4))),
          ]),
        ),
        const SizedBox(height: 20),

        _DocCard(
          icon: Icons.school_outlined,
          title: 'Diplôme de Docteur en Médecine',
          subtitle: 'Obligatoire *',
          file: widget.dossier.diplomeMedecine,
          required: true,
          onPick: () => _pick('diplome'),
        ),
        const SizedBox(height: 12),

        _DocCard(
          icon: Icons.badge_outlined,
          title: 'Carte membre ONMC en cours de validité',
          subtitle: 'Obligatoire *',
          file: widget.dossier.carteOnmc,
          required: true,
          onPick: () => _pick('onmc'),
        ),
        const SizedBox(height: 12),

        _DocCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Diplôme de spécialité',
          subtitle: 'Optionnel — si spécialiste',
          file: widget.dossier.diplomeSpecialite,
          required: false,
          onPick: () => _pick('specialite'),
        ),
        const SizedBox(height: 12),

        _DocCard(
          icon: Icons.credit_card_outlined,
          title: 'Pièce d\'identité (CNI ou Passeport)',
          subtitle: 'Obligatoire *',
          file: widget.dossier.pieceIdentite,
          required: true,
          onPick: () => _pick('cni'),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 4 — Disponibilités
// ═══════════════════════════════════════════════════════════════
class _Step4Disponibilites extends StatefulWidget {
  final _DoctorDossier dossier;
  final VoidCallback onUpdate;
  const _Step4Disponibilites(
      {required this.dossier, required this.onUpdate});

  @override
  State<_Step4Disponibilites> createState() => _Step4DisponibilitesState();
}

class _Step4DisponibilitesState extends State<_Step4Disponibilites> {
  static const _timeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
    '19:00', '20:00',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepHeader(
          icon: Icons.schedule_outlined,
          title: 'Vos disponibilités',
          subtitle: 'Définissez vos horaires de consultation en ligne. '
              'Vous pourrez les modifier à tout moment.',
        ),
        const SizedBox(height: 24),

        // Jours disponibles
        const Text('Jours de disponibilité', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: widget.dossier.availableDays.entries.map((e) {
            return FilterChip(
              label: Text(e.key.substring(0, 3),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: e.value
                        ? AppColors.doctorPrimary : AppColors.textHint)),
              selected: e.value,
              onSelected: (v) => setState(() {
                widget.dossier.availableDays[e.key] = v;
                widget.onUpdate();
              }),
              selectedColor: AppColors.doctorLight,
              checkmarkColor: AppColors.doctorPrimary,
            );
          }).toList()),
        const SizedBox(height: 20),

        // Heure début
        const Text('Heure de début', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        _TimeSelector(
          value: widget.dossier.startTime,
          slots: _timeSlots,
          onChanged: (v) => setState(() {
            widget.dossier.startTime = v;
            widget.onUpdate();
          }),
        ),
        const SizedBox(height: 16),

        // Heure fin
        const Text('Heure de fin', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        _TimeSelector(
          value: widget.dossier.endTime,
          slots: _timeSlots,
          onChanged: (v) => setState(() {
            widget.dossier.endTime = v;
            widget.onUpdate();
          }),
        ),
        const SizedBox(height: 20),

        // Consultations par jour
        const Text('Consultations maximum / jour', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          IconButton(
            onPressed: () {
              if (widget.dossier.consultationsPerDay > 1) {
                setState(() {
                  widget.dossier.consultationsPerDay--;
                  widget.onUpdate();
                });
              }
            },
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.doctorPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${widget.dossier.consultationsPerDay}',
              style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700))),
          IconButton(
            onPressed: () => setState(() {
              widget.dossier.consultationsPerDay++;
              widget.onUpdate();
            }),
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.doctorPrimary)),
          const SizedBox(width: 8),
          Text('≈ ${widget.dossier.consultationsPerDay * 20} min / consultation',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 20),

        // Estimation revenus
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.doctorLight,
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            const Row(children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.doctorPrimary, size: 18),
              SizedBox(width: 8),
              Text('Estimation de revenus',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.doctorPrimary)),
            ]),
            const SizedBox(height: 12),
            _RevenueRow(
                label: '${widget.dossier.consultationsPerDay} consultations/jour',
                value: '${widget.dossier.consultationsPerDay * 7500} FCFA/jour'),
            _RevenueRow(
                label: 'Estimation mensuelle (22 jours)',
                value: '${widget.dossier.consultationsPerDay * 7500 * 22} FCFA/mois'),
            const SizedBox(height: 8),
            const Text('* Après commission FlashDoc (25%)',
              style: TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 5 — Récapitulatif
// ═══════════════════════════════════════════════════════════════
class _Step5Recap extends StatelessWidget {
  final _DoctorDossier dossier;
  const _Step5Recap({required this.dossier});

  @override
  Widget build(BuildContext context) {
    final joursDispos = dossier.availableDays.entries
        .where((e) => e.value).map((e) => e.key).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepHeader(
          icon: Icons.checklist_outlined,
          title: 'Vérifiez votre dossier',
          subtitle: 'Relisez vos informations avant de soumettre. '
              'Votre dossier sera traité sous 3 à 5 jours ouvrés.',
        ),
        const SizedBox(height: 16),

        // Étapes du processus
        _ProcessTimeline(),
        const SizedBox(height: 20),

        // Récap perso
        _RecapSection(title: 'Informations personnelles',
            icon: Icons.person_outline, items: [
          _RecapItem('Nom', '${dossier.firstName} ${dossier.lastName}'),
          _RecapItem('Téléphone', dossier.phone),
          _RecapItem('Email', dossier.email),
          _RecapItem('Ville', dossier.city),
        ]),
        const SizedBox(height: 12),

        // Récap pro
        _RecapSection(title: 'Informations professionnelles',
            icon: Icons.medical_services_outlined, items: [
          _RecapItem('Spécialité', dossier.speciality),
          _RecapItem('Numéro ONMC', dossier.onmcNumber),
          _RecapItem('Établissement', dossier.hospital),
          _RecapItem('Expérience', '${dossier.experience} ans'),
          _RecapItem('Langues', dossier.languages.join(', ')),
        ]),
        const SizedBox(height: 12),

        // Récap documents
        _RecapSection(title: 'Documents fournis',
            icon: Icons.folder_outlined, items: [
          _RecapItem('Diplôme médecine',
              dossier.diplomeMedecine != null ? '✅ Fourni' : '❌ Manquant'),
          _RecapItem('Carte ONMC',
              dossier.carteOnmc != null ? '✅ Fourni' : '❌ Manquant'),
          _RecapItem('Diplôme spécialité',
              dossier.diplomeSpecialite != null ? '✅ Fourni' : 'Non fourni'),
          _RecapItem('Pièce d\'identité',
              dossier.pieceIdentite != null ? '✅ Fourni' : '❌ Manquant'),
        ]),
        const SizedBox(height: 12),

        // Récap disponibilités
        _RecapSection(title: 'Disponibilités',
            icon: Icons.schedule_outlined, items: [
          _RecapItem('Jours', joursDispos.isEmpty ? 'Non défini' : joursDispos),
          _RecapItem('Horaires', '${dossier.startTime} — ${dossier.endTime}'),
          _RecapItem('Consultations/jour',
              '${dossier.consultationsPerDay} max'),
        ]),
        const SizedBox(height: 20),

        // Accord
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: const Text(
            'En soumettant ce dossier, je certifie sur l\'honneur '
            'que toutes les informations fournies sont exactes et que '
            'je suis bien inscrit à l\'Ordre National des Médecins du Cameroun (ONMC). '
            'Je m\'engage à respecter le code de déontologie médicale dans '
            'le cadre de mes consultations FlashDoc.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary,
                height: 1.6, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════

class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _StepProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: (current + 1) / total,
      minHeight: 4,
      backgroundColor: AppColors.border,
      valueColor: const AlwaysStoppedAnimation(AppColors.doctorPrimary),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.doctorLight,
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.doctorPrimary, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(title, style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 13,
            color: AppColors.textSecondary, height: 1.4)),
      ])),
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final Function(String) onChanged;
  final Widget? suffixIcon;
  const _Field({
    required this.ctrl, required this.label, required this.hint,
    required this.onChanged, this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: keyboardType, onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          suffixIcon: suffixIcon,
          filled: true, fillColor: AppColors.surfaceGrey,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.doctorPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _GenderChip({required this.label, required this.value,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.doctorLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected
              ? AppColors.doctorPrimary : AppColors.border, width: 1.5)),
        child: Text(label, style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.doctorPrimary : AppColors.textHint)),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final XFile? file;
  final bool required;
  final VoidCallback onPick;
  const _DocCard({required this.icon, required this.title,
      required this.subtitle, this.file, required this.required,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.success.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? AppColors.success
                : (required ? AppColors.border : AppColors.border.withOpacity(0.5)),
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasFile
                  ? AppColors.success.withOpacity(0.1) : AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(10)),
            child: Icon(hasFile ? Icons.check_circle_outline : icon,
                color: hasFile ? AppColors.success : AppColors.textSecondary,
                size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(
              hasFile
                  ? '✓ ${file!.name}'
                  : subtitle,
              style: TextStyle(fontSize: 11,
                  color: hasFile ? AppColors.success : AppColors.textHint),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Icon(hasFile ? Icons.edit_outlined : Icons.upload_outlined,
              color: hasFile ? AppColors.success : AppColors.doctorPrimary,
              size: 18),
        ]),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String value;
  final List<String> slots;
  final Function(String) onChanged;
  const _TimeSelector(
      {required this.value, required this.slots, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        itemBuilder: (_, i) {
          final selected = slots[i] == value;
          return GestureDetector(
            onTap: () => onChanged(slots[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.doctorPrimary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected
                    ? AppColors.doctorPrimary : AppColors.border)),
              child: Center(child: Text(slots[i], style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary))),
            ),
          );
        },
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final String value;
  const _RevenueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary))),
        Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.doctorPrimary)),
      ]),
    );
  }
}

class _ProcessTimeline extends StatelessWidget {
  const _ProcessTimeline();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Soumission', 'Votre dossier est envoyé', Icons.send_outlined),
      ('Vérification docs', 'Notre équipe vérifie vos documents (24-48h)',
          Icons.fact_check_outlined),
      ('Validation ONMC', 'Vérification de votre numéro ONMC',
          Icons.verified_outlined),
      ('Interview', 'Entretien vidéo avec notre comité (30 min)',
          Icons.videocam_outlined),
      ('Activation', 'Accès complet à FlashDoc !',
          Icons.check_circle_outline),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.15))),
      child: Column(
        children: steps.asMap().entries.map((e) {
          final isLast = e.key == steps.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Center(child: Icon(e.value.$3,
                    color: AppColors.primary, size: 14))),
              if (!isLast) Container(
                width: 1, height: 28,
                color: AppColors.primary.withOpacity(0.2)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(e.value.$1, style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(e.value.$2, style: const TextStyle(fontSize: 11,
                    color: AppColors.textSecondary, height: 1.3)),
              ]),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

class _RecapSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_RecapItem> items;
  const _RecapSection(
      {required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.doctorPrimary, size: 16),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.doctorPrimary)),
        ]),
        const Divider(height: 14),
        ...items,
      ]),
    );
  }
}

class _RecapItem extends StatelessWidget {
  final String label;
  final String value;
  const _RecapItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: value.contains('❌')
                  ? AppColors.error : AppColors.textPrimary),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
