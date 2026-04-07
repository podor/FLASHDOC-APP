// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/fd_text_field.dart';
import '../../../core/widgets/fd_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _localLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localLoading = true);

    final phone = '+237${_phoneCtrl.text.trim()}';
    final ok = await ref.read(authProvider.notifier)
        .login(phone, _passCtrl.text);

    if (!mounted) return;
    setState(() => _localLoading = false);

    if (ok) {
      // Petit délai pour laisser Riverpod propager le state
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final auth = ref.read(authProvider);
      print('Navigation après login — role: ${auth.user?.role}, isAuth: ${auth.isAuthenticated}');

      if (auth.isAuthenticated) {
        final role = auth.user?.role;
        if (role == 'DOCTOR') {
          context.go('/doctor/home');
        } else {
          context.go('/patient/home');
        }
      }
    } else {
      final err = ref.read(authProvider).error ?? 'Erreur de connexion';
      FdSnackbar.show(context, err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo_flashdoc.png',
                    height: 80,
                    errorBuilder: (_, __, ___) => RichText(
                      text: const TextSpan(children: [
                        TextSpan(text: 'Flash',
                            style: TextStyle(fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        TextSpan(text: 'Doc',
                            style: TextStyle(fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bon retour !',
                    style: TextStyle(fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Connectez-vous à votre compte FlashDoc',
                    style: TextStyle(fontSize: 14,
                        color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 32),

                // Téléphone
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(children: [
                      Text('🇨🇲', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 6),
                      Text('+237',
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FdTextField(
                      label: 'Numéro de téléphone',
                      hint: '6X XXX XXXX',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Numéro requis';
                        if (v.length < 9) return 'Numéro invalide';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                FdTextField(
                  label: 'Mot de passe',
                  controller: _passCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 24),

                // Bouton connexion
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _localLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _localLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Se connecter',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => context.go('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Créer un compte',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('FlashDoc — Cameroun © 2024',
                  style: TextStyle(fontSize: 12,
                      color: AppColors.textHint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
