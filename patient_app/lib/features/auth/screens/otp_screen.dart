// lib/features/auth/screens/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/fd_button.dart';
import '../../../core/widgets/fd_snackbar.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otp = '';
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) { _canResend = true; return; }
      });
      return _countdown > 0;
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      FdSnackbar.show(context, 'Entrez le code à 6 chiffres', isError: true);
      return;
    }
    final ok = await ref.read(authProvider.notifier).verifyOtp(widget.phone, _otp);
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      FdSnackbar.show(context, ref.read(authProvider).error ?? 'Code invalide', isError: true);
    }
  }

  Future<void> _resend() async {
    await ApiService().resendOtp(widget.phone);
    setState(() { _countdown = 60; _canResend = false; });
    _startCountdown();
    if (mounted) FdSnackbar.show(context, 'Code renvoyé !');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final display = widget.phone.replaceRange(5, widget.phone.length - 2, '•••••');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.sms_outlined, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Code de vérification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text('Entrez le code envoyé au\n$display',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 40),

            // Champ OTP
            PinCodeTextField(
              appContext: context,
              length: 6,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              onChanged: (v) => setState(() => _otp = v),
              onCompleted: (_) => _verify(),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 58,
                fieldWidth: 48,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                selectedColor: AppColors.primaryLight,
                activeFillColor: AppColors.surfaceVariant,
                inactiveFillColor: AppColors.surfaceVariant,
                selectedFillColor: AppColors.surfaceVariant,
              ),
              enableActiveFill: true,
              cursorColor: AppColors.primary,
            ),
            const SizedBox(height: 32),

            FdButton(label: 'Vérifier', onPressed: _verify, isLoading: isLoading),
            const SizedBox(height: 24),

            // Renvoi
            if (_canResend)
              TextButton(onPressed: _resend, child: const Text('Renvoyer le code'))
            else
              Text('Renvoyer dans $_countdown secondes',
                style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
