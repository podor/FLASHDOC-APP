// lib/features/consultation/screens/mode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/consultation_provider.dart';
import '../../../core/widgets/fd_button.dart';
import '../../../core/widgets/fd_snackbar.dart';

class ModeScreen extends ConsumerStatefulWidget {
  final String speciality;
  final String? symptomsText;
  final String? preSelectedMode; // ✅ Mode pré-sélectionné
  const ModeScreen({super.key, required this.speciality,
      this.symptomsText, this.preSelectedMode});

  @override
  ConsumerState<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends ConsumerState<ModeScreen> {
  late String _selectedMode;

  static const _modes = [
    {'id': 'CHAT',  'label': 'Chat texte',        'icon': Icons.chat_bubble_outline_rounded, 'desc': 'Échange par messages écrits',  'price': 5000},
    {'id': 'AUDIO', 'label': 'Appel audio',        'icon': Icons.mic_none_rounded,           'desc': 'Consultation par appel vocal', 'price': 8000},
    {'id': 'VIDEO', 'label': 'Vidéo consultation', 'icon': Icons.videocam_outlined,          'desc': 'Consultation face à face',    'price': 10000},
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Utiliser le mode pré-sélectionné si disponible
    _selectedMode = widget.preSelectedMode ?? 'VIDEO';
  }

  Future<void> _confirm() async {
    final consultation = await ref.read(consultationProvider.notifier)
        .createConsultation(
      mode:         _selectedMode,
      speciality:   widget.speciality,
      symptomsText: widget.symptomsText,
    );

    if (!mounted) return;

    if (consultation != null) {
      context.push('/patient/consult/payment', extra: {
        'consultationId': consultation.id,
        'amount':         consultation.totalAmount,
        'mode':           _selectedMode,
      });
    } else {
      FdSnackbar.show(context,
          ref.read(consultationProvider).error ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(consultationProvider).isLoading;
    final price = AppConstants.consultationPrices[_selectedMode] ?? 10000;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Mode de consultation',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepIndicator(current: 2),
          const SizedBox(height: 24),

          // Résumé spécialité + symptômes
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.local_hospital_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Spécialité : ${widget.speciality}',
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 13, color: AppColors.textPrimary)),
                if (widget.symptomsText != null)
                  Text(widget.symptomsText!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textSecondary)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          const Text('Choisir le mode',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
          const SizedBox(height: 14),

          Expanded(
            child: ListView.separated(
              itemCount: _modes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final m = _modes[i];
                final isSelected = _selectedMode == m['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMode = m['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(m['icon'] as IconData,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 26)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m['label'] as String,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(m['desc'] as String,
                          style: const TextStyle(fontSize: 12,
                              color: AppColors.textSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${(m['price'] as int) ~/ 1000} 000',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                        const Text('FCFA', style: TextStyle(fontSize: 11,
                            color: AppColors.textHint)),
                      ]),
                      const SizedBox(width: 8),
                      Icon(isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : AppColors.textHint,
                        size: 22),
                    ]),
                  ),
                );
              },
            ),
          ),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total à payer',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              Text('$price FCFA', style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
          ),
          const SizedBox(height: 16),

          FdButton(label: 'Continuer vers le paiement',
              onPressed: _confirm, isLoading: isLoading,
              icon: Icons.arrow_forward_rounded),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});
  @override
  Widget build(BuildContext context) {
    final steps = ['Symptômes', 'Mode', 'Paiement'];
    return Row(children: List.generate(steps.length * 2 - 1, (i) {
      if (i.isOdd) return Expanded(child: Container(height: 2,
          color: i ~/ 2 < current - 1 ? AppColors.primary : AppColors.border));
      final idx    = i ~/ 2;
      final done   = idx < current - 1;
      final active = idx == current - 1;
      return Column(children: [
        CircleAvatar(radius: 14,
          backgroundColor: done || active ? AppColors.primary : AppColors.border,
          child: done ? const Icon(Icons.check, size: 14, color: Colors.white)
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
