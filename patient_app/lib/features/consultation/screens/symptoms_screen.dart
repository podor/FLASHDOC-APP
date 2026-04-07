// lib/features/consultation/screens/symptoms_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/fd_button.dart';
import '../../../core/widgets/fd_snackbar.dart';

class SymptomsScreen extends StatefulWidget {
  final String? preSelectedSpec;
  final String? preSelectedMode; // ✅ Mode pré-sélectionné depuis l'accueil
  const SymptomsScreen({super.key, this.preSelectedSpec, this.preSelectedMode});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final _textCtrl = TextEditingController();
  late String _selectedSpec;
  String? _preMode; // Mode pré-sélectionné à transmettre

  @override
  void initState() {
    super.initState();
    _selectedSpec = widget.preSelectedSpec ?? 'Généraliste';
    _preMode      = widget.preSelectedMode;
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  void _next() {
    if (_textCtrl.text.trim().isEmpty) {
      FdSnackbar.show(context, 'Décrivez vos symptômes pour continuer',
          isError: true);
      return;
    }
    context.push('/patient/consult/mode', extra: {
      'speciality':   _selectedSpec,
      'symptomsText': _textCtrl.text.trim(),
      // ✅ Transmettre le mode pré-sélectionné au ModeScreen
      if (_preMode != null) 'preSelectedMode': _preMode,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Décrire mes symptômes',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/patient/home');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepIndicator(current: 1),
          const SizedBox(height: 24),

          // ✅ Bandeau mode pré-sélectionné
          if (_preMode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(_modeIcon(_preMode!), color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Mode sélectionné : ${_modeLabel(_preMode!)} — ${_modePrice(_preMode!)}',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppColors.primary),
                )),
                GestureDetector(
                  onTap: () => setState(() => _preMode = null),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Spécialité
          const Text('Quelle spécialité ?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.specialities.map((s) => ChoiceChip(
              label: Text(s),
              selected: _selectedSpec == s,
              onSelected: (_) => setState(() => _selectedSpec = s),
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _selectedSpec == s ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _selectedSpec == s ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            )).toList(),
          ),
          const SizedBox(height: 28),

          // Zone symptômes
          const Text('Décrivez vos symptômes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: TextField(
              controller: _textCtrl,
              maxLines: 6,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ex : J\'ai une douleur à la poitrine depuis ce matin...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exemples rapides
          const Text('Exemples rapides :',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              'Fièvre et maux de tête', 'Douleur abdominale',
              'Toux persistante', 'Éruption cutanée', 'Difficulté à respirer',
            ].map((e) => GestureDetector(
              onTap: () => setState(() => _textCtrl.text = e),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border)),
                child: Text(e, style: const TextStyle(fontSize: 12,
                    color: AppColors.textSecondary))),
            )).toList(),
          ),
          const SizedBox(height: 32),

          FdButton(label: 'Choisir le mode de consultation',
              onPressed: _next, icon: Icons.arrow_forward_rounded),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'AUDIO': return Icons.mic_rounded;
      case 'VIDEO': return Icons.videocam_rounded;
      default:      return Icons.chat_bubble_rounded;
    }
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'AUDIO': return 'Audio';
      case 'VIDEO': return 'Vidéo';
      default:      return 'Chat';
    }
  }

  String _modePrice(String mode) {
    switch (mode) {
      case 'AUDIO': return '8 000 FCFA';
      case 'VIDEO': return '10 000 FCFA';
      default:      return '5 000 FCFA';
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['Symptômes', 'Mode', 'Paiement'];
    return Row(children: List.generate(steps.length * 2 - 1, (i) {
      if (i.isOdd) {
        return Expanded(child: Container(height: 2,
            color: i ~/ 2 < current - 1 ? AppColors.primary : AppColors.border));
      }
      final idx    = i ~/ 2;
      final done   = idx < current - 1;
      final active = idx == current - 1;
      return Column(children: [
        CircleAvatar(radius: 14,
          backgroundColor: done || active ? AppColors.primary : AppColors.border,
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${idx + 1}', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textHint))),
        const SizedBox(height: 4),
        Text(steps[idx], style: TextStyle(fontSize: 10,
          color: active ? AppColors.primary : AppColors.textHint,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ]);
    }));
  }
}
