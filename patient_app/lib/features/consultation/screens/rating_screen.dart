// lib/features/consultation/screens/rating_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/consultation_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/fd_button.dart';
import '../../../core/widgets/fd_snackbar.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String consultationId;
  const RatingScreen({super.key, required this.consultationId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen>
    with SingleTickerProviderStateMixin {
  double _rating   = 8.0;
  final _comment   = TextEditingController();
  bool  _sent      = false;
  String? _prescriptionUrl;
  late AnimationController _checkCtrl;
  late Animation<double>   _checkAnim;

  static const _labels = {
    1: '😞 Très mauvais', 2: '😕 Mauvais',
    3: '😐 Passable',     4: '😐 Passable',
    5: '🙂 Moyen',        6: '🙂 Bien',
    7: '😊 Bien',         8: '😊 Très bien',
    9: '😃 Excellent',    10: '🤩 Parfait !',
  };

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _checkAnim = CurvedAnimation(
        parent: _checkCtrl, curve: Curves.elasticOut);
    // Charger les détails de la consultation pour récupérer l'ordonnance
    _loadConsultation();
  }

  Future<void> _loadConsultation() async {
    try {
      final res = await ApiService().getConsultation(widget.consultationId);
      if (res['success'] == true) {
        final data = res['data']['consultation'] as Map<String, dynamic>;
        setState(() {
          _prescriptionUrl = data['prescriptionUrl'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(consultationProvider.notifier).rateConsultation(
      widget.consultationId,
      _rating.round(),
      _comment.text.trim().isEmpty ? null : _comment.text.trim(),
    );
    if (ok && mounted) {
      setState(() => _sent = true);
      _checkCtrl.forward();
    } else if (mounted) {
      FdSnackbar.show(context, 'Erreur lors de l\'envoi', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _sent ? _buildSuccess() : _buildRating(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _checkAnim,
          child: Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 56),
          ),
        ),
        const SizedBox(height: 32),
        const Text('Merci pour votre avis !',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text(
          'Votre évaluation aide à améliorer la qualité\ndes consultations FlashDoc.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary,
              height: 1.5)),
        const SizedBox(height: 48),

        // Retour à l'accueil — route corrigée
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/patient/home'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Retour à l\'accueil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Voir mes consultations — route corrigée
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/patient/history'),
            icon: const Icon(Icons.history_outlined),
            label: const Text('Mes consultations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Ordonnance — si disponible
        if (_prescriptionUrl != null) ...[
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                // Afficher l'URL de l'ordonnance
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Row(children: [
                      Icon(Icons.description_outlined,
                          color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Ordonnance'),
                    ]),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Votre ordonnance est disponible.',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_prescriptionUrl!,
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textPrimary)),
                      ),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer')),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.description_outlined),
              label: const Text('Voir mon ordonnance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
          // Pas d'ordonnance — bouton désactivé avec explication
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Aucune ordonnance',
                  style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textHint,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRating() {
    final isLoading = ref.watch(consultationProvider).isLoading;
    final label = _labels[_rating.round()] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star_rounded,
              color: AppColors.primary, size: 44),
        ),
        const SizedBox(height: 20),
        const Text('Évaluez votre consultation',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Votre avis est précieux pour améliorer\nle service FlashDoc',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary,
              height: 1.5)),
        const SizedBox(height: 36),

        Text(_rating.round().toString(),
          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700,
              color: AppColors.primary)),
        Text(label,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        RatingBar.builder(
          initialRating: _rating,
          minRating: 1, maxRating: 10, itemCount: 10, itemSize: 30,
          allowHalfRating: false,
          unratedColor: AppColors.border,
          itemBuilder: (_, __) =>
              const Icon(Icons.star_rounded, color: AppColors.primary),
          onRatingUpdate: (r) => setState(() => _rating = r),
        ),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          Text('Note sur 10',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          Text('10', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 28),

        TextField(
          controller: _comment, maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Laisser un commentaire (optionnel)...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true, fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const Spacer(),

        FdButton(label: 'Envoyer mon évaluation',
            onPressed: _submit, isLoading: isLoading),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/patient/home'),
          child: const Text('Passer',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
