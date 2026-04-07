// lib/features/doctor/onboarding/doctor_onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DoctorOnboardingScreen extends StatelessWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Affiliation médecin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      ),
      body: const Center(
        child: Text('Soumission dossier ONMC\n(Étape 2)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textHint, fontSize: 16)),
      ),
    );
  }
}
