// lib/features/consultation/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/fd_snackbar.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String consultationId;
  final double amount;
  final String mode;
  const PaymentScreen({super.key, required this.consultationId,
      required this.amount, required this.mode});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedOtm = '';
  final _phoneCtrl = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  String get _modeLabel {
    switch (widget.mode) {
      case 'CHAT':  return 'Chat texte';
      case 'AUDIO': return 'Appel audio';
      case 'VIDEO': return 'Vidéo consultation';
      default:      return widget.mode;
    }
  }

  Future<void> _confirmPayment() async {
    if (_selectedOtm.isEmpty) {
      FdSnackbar.show(context, 'Choisissez un opérateur', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().simulatePayment(widget.consultationId);
      if (mounted) {
        context.go('/patient/consult/waiting',
            extra: {'consultationId': widget.consultationId});
      }
    } catch (e) {
      if (mounted) FdSnackbar.show(context, 'Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ resizeToAvoidBottomInset évite l'overflow quand le clavier s'ouvre
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/patient/home');
          },
        ),
        title: const Text('Payer avec :',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      ),
      // ✅ SingleChildScrollView pour que tout soit scrollable quand clavier ouvert
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            // ✅ Ajouter padding bas = hauteur clavier pour éviter l'overflow
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_modeLabel, style: const TextStyle(fontSize: 15,
                        color: AppColors.textSecondary)),
                    Text('${widget.amount.toInt()} FCFA',
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Orange Money
              _OtmButton(
                label: 'Orange Money',
                color: AppColors.orangeMoney,
                isSelected: _selectedOtm == 'ORANGE_MONEY',
                onTap: () => setState(() => _selectedOtm = 'ORANGE_MONEY'),
              ),
              const SizedBox(height: 16),

              // MTN MoMo
              _OtmButton(
                label: 'MTN MoMo',
                color: AppColors.mtnMomo,
                isSelected: _selectedOtm == 'MTN_MOMO',
                onTap: () => setState(() => _selectedOtm = 'MTN_MOMO'),
              ),
              const SizedBox(height: 24),

              // Numéro de téléphone
              if (_selectedOtm.isNotEmpty) ...[
                const Text('Numéro Mobile Money',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Text('🇨🇲 +237 ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '6X XXX XXXX',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppColors.textHint),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
              ],

              // Bouton confirmer
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Confirmer paiement',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),

              // Sécurité
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
                SizedBox(width: 6),
                Text('Paiement sécurisé Mobile Money',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtmButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _OtmButton({required this.label, required this.color,
      required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 62,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4),
              blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Center(child: Text(label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 0.5))),
      ),
    );
  }
}
