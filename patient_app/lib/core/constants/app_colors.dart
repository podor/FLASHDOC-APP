// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Couleurs PATIENT (bleu) ───────────────────────────────────
  static const Color primary        = Color(0xFF0066FF);
  static const Color primaryLight   = Color(0xFF4D94FF);
  static const Color primaryDark    = Color(0xFF0047B3);
  static const Color secondary      = Color(0xFF00C896);
  static const Color secondaryLight = Color(0xFF4DDDB8);
  static const Color consultNow     = Color(0xFFE84040); // Bouton rouge
  static const Color consultNowDark = Color(0xFFC42B2B);

  // ── Couleurs DOCTOR (vert foncé) — identité visuelle distincte ─
  static const Color doctorPrimary  = Color(0xFF00A878); // Vert médecin
  static const Color doctorDark     = Color(0xFF007A57);
  static const Color doctorLight    = Color(0xFFE0F7F2);

  // ── Mobile Money ─────────────────────────────────────────────
  static const Color orangeMoney    = Color(0xFFFF6600);
  static const Color mtnMomo        = Color(0xFF00A651);

  // ── Neutres ──────────────────────────────────────────────────
  static const Color background     = Color(0xFFFFFFFF);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceGrey    = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFF0F4FF);

  static const Color textPrimary    = Color(0xFF1A1A2E);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textHint       = Color(0xFFB0B8CC);

  static const Color border         = Color(0xFFE8ECF4);
  static const Color divider        = Color(0xFFF0F3FF);

  // ── Sémantiques ──────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFEF4444);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF0047B3)],
  );

  static const LinearGradient consultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE84040), Color(0xFFC42B2B)],
  );

  static const LinearGradient doctorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A878), Color(0xFF007A57)],
  );
}
