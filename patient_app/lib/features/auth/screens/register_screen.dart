// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/fd_button.dart';
import '../../../core/widgets/fd_text_field.dart';
import '../../../core/widgets/fd_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _firstCtrl  = TextEditingController();
  final _lastCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    for (final c in [_firstCtrl,_lastCtrl,_phoneCtrl,_emailCtrl,_passCtrl,_pass2Ctrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) { FdSnackbar.show(context, 'Acceptez les conditions d\'utilisation', isError: true); return; }

    final phone = '+237${_phoneCtrl.text.trim()}';
    final ok = await ref.read(authProvider.notifier).register({
      'firstName': _firstCtrl.text.trim(),
      'lastName':  _lastCtrl.text.trim(),
      'phone':     phone,
      'email':     _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'password':  _passCtrl.text,
      'role':      'PATIENT',
    });

    if (ok && mounted) {
      context.go('/otp?phone=${Uri.encodeComponent(phone)}');
    } else if (mounted) {
      FdSnackbar.show(context, ref.read(authProvider).error ?? 'Erreur inscription', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/login')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informations personnelles',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: FdTextField(label: 'Prénom', controller: _firstCtrl,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null)),
                const SizedBox(width: 12),
                Expanded(child: FdTextField(label: 'Nom', controller: _lastCtrl,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(children: [
                    Text('🇨🇲', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text('+237', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(child: FdTextField(
                  label: 'Téléphone',
                  hint: '6X XXX XXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 9) return 'Invalide';
                    return null;
                  },
                )),
              ]),
              const SizedBox(height: 16),
              FdTextField(label: 'Email (optionnel)', controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
              const SizedBox(height: 24),
              const Text('Sécurité',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FdTextField(
                label: 'Mot de passe',
                controller: _passCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (v == null || v.length < 8) return 'Minimum 8 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FdTextField(
                label: 'Confirmer le mot de passe',
                controller: _pass2Ctrl,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => v != _passCtrl.text ? 'Mots de passe différents' : null,
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              FdButton(label: 'Créer mon compte', onPressed: _register, isLoading: isLoading),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Déjà un compte ? ', style: TextStyle(color: AppColors.textSecondary)),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Se connecter')),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
