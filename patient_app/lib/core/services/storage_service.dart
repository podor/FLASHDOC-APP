// lib/core/services/storage_service.dart
// NOTE : utilise shared_preferences pour compatibilité Windows/Web en dev.
// Sur Android/iOS en production, migrer vers flutter_secure_storage.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Tokens ────────────────────────────────────────────────────────
  Future<void> saveTokens({required String access, required String refresh}) async {
    final p = await _prefs;
    await Future.wait([
      p.setString(AppConstants.keyAccessToken,  access),
      p.setString(AppConstants.keyRefreshToken, refresh),
    ]);
  }

  Future<String?> getAccessToken() async {
    final p = await _prefs;
    return p.getString(AppConstants.keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final p = await _prefs;
    return p.getString(AppConstants.keyRefreshToken);
  }

  Future<void> clearTokens() async {
    final p = await _prefs;
    await Future.wait([
      p.remove(AppConstants.keyAccessToken),
      p.remove(AppConstants.keyRefreshToken),
    ]);
  }

  // ── User ──────────────────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
    final p = await _prefs;
    await p.setString(AppConstants.keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final p = await _prefs;
    final raw = p.getString(AppConstants.keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final p = await _prefs;
    await p.remove(AppConstants.keyUser);
  }

  // ── Logout complet ────────────────────────────────────────────────
  Future<void> clearAll() async {
    final p = await _prefs;
    await p.clear();
  }

  // ── Session active ? ──────────────────────────────────────────────
  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
