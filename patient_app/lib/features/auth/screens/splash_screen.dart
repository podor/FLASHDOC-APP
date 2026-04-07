// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    // Navigation après 2.5s maximum — ne pas attendre indéfiniment
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_navigated) _navigate();
    });
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;

    final auth = ref.read(authProvider);

    if (!auth.isAuthenticated) {
      context.go('/onboarding');
      return;
    }

    final role = auth.user?.role;
    if (role == 'DOCTOR') {
      context.go('/doctor/home');
    } else {
      context.go('/patient/home');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Naviguer dès que l'auth est prêt (sans attendre 2.5s)
    ref.listen(authProvider, (prev, next) {
      if (!next.isLoading && !_navigated) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !_navigated) _navigate();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_flashdoc.png',
                  width: 180,
                  errorBuilder: (_, __, ___) => _FallbackLogo(),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Votre médecin en quelques minutes',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.local_hospital_rounded,
            color: Colors.white, size: 44),
      ),
      const SizedBox(height: 16),
      RichText(text: const TextSpan(children: [
        TextSpan(text: 'Flash',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        TextSpan(text: 'Doc',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                color: AppColors.secondary)),
      ])),
    ]);
  }
}
