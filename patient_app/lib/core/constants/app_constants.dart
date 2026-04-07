// lib/core/constants/app_constants.dart
import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // ── URL API ──────────────────────────────────────────────────────
  // Les deux téléphones utilisent adb reverse tcp:3000 tcp:3000
  // ce qui redirige localhost:3000 du téléphone vers le PC via USB
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://localhost:3000/api';
  }

  static String get socketUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://localhost:3000';
  }

  // ── Timeouts ─────────────────────────────────────────────────────
  static const int connectTimeout  = 15000;
  static const int receiveTimeout  = 30000;
  static const int dispatchTimeout = 60;

  // ── Storage keys ─────────────────────────────────────────────────
  static const String keyAccessToken  = 'fd_access_token';
  static const String keyRefreshToken = 'fd_refresh_token';
  static const String keyUser         = 'fd_user_data';

  // ── Prix consultations (FCFA) ────────────────────────────────────
  static const Map<String, int> consultationPrices = {
    'CHAT':  5000,
    'AUDIO': 8000,
    'VIDEO': 10000,
  };

  // ── Spécialités ──────────────────────────────────────────────────
  static const List<String> specialities = [
    'Généraliste', 'Cardiologue', 'Dermatologue', 'Pédiatre',
    'Gynécologue', 'Ophtalmologue', 'ORL', 'Neurologue',
    'Psychiatre', 'Urologue', 'Gastro-entérologue', 'Orthopédiste',
  ];

  // ── Opérateurs Mobile Money ──────────────────────────────────────
  static const List<Map<String, String>> mobileOperators = [
    {'id': 'ORANGE_MONEY', 'name': 'Orange Money', 'prefix': '69,65,66'},
    {'id': 'MTN_MOMO',     'name': 'MTN MoMo',     'prefix': '67,68'},
  ];
}
