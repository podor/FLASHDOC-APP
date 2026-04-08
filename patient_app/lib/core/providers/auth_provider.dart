// lib/core/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user:            user            ?? this.user,
      isLoading:       isLoading       ?? this.isLoading,
      error:           error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService     _api     = ApiService();
  final StorageService _storage = StorageService();

  AuthNotifier() : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final loggedIn = await _storage.isLoggedIn;
      if (loggedIn) {
        final user = await _storage.getUser();
        if (user != null) {
          state = AuthState(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          // Socket en arrière-plan
          Future.delayed(const Duration(milliseconds: 500), () {
            SocketService().connect().catchError((_) {});
          });
          return;
        }
      }
    } catch (e) {
      print('Session check error: $e');
    }
    state = const AuthState(isLoading: false, isAuthenticated: false);
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.login(phone, password);

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        // ── Sauvegarder en attenant la confirmation ───────────────
        await _storage.saveTokens(
          access:  data['accessToken'] as String,
          refresh: data['refreshToken'] as String,
        );
        await _storage.saveUser(user);

        // ── Vérifier que la sauvegarde a bien marché ─────────────
        final savedToken = await _storage.getAccessToken();
        final savedUser  = await _storage.getUser();

        if (savedToken == null || savedUser == null) {
          // Sauvegarde échouée — réessayer
          await _storage.saveTokens(
            access:  data['accessToken'] as String,
            refresh: data['refreshToken'] as String,
          );
          await _storage.saveUser(user);
        }

        // ── Socket en arrière-plan ────────────────────────────────
        SocketService().disconnect();
        Future.delayed(const Duration(milliseconds: 300), () {
          SocketService().connect().catchError((_) {});
        });

        // ── Mettre à jour le state ────────────────────────────────
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );

        print('✅ Login OK — role: ${user.role}, auth: true');
        return true;
      }

      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        error: res['message'] as String? ?? 'Erreur de connexion',
      );
      return false;

    } catch (e) {
      print('❌ Login error: $e');
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.register(data);
      state = state.copyWith(isLoading: false);
      return res['success'] == true;
    } catch (e) {
      state = state.copyWith(error: _extractError(e), isLoading: false);
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.verifyOtp(phone, code);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _storage.saveTokens(
          access:  data['accessToken'] as String,
          refresh: data['refreshToken'] as String,
        );
        await _storage.saveUser(user);
        SocketService().connect().catchError((_) {});
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
        return true;
      }
      state = state.copyWith(
        error: res['message'] as String? ?? 'Code invalide',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: _extractError(e), isLoading: false);
      return false;
    }
  }

  /// Met à jour l'avatarUrl dans le state ET dans le storage
  Future<void> updateAvatarUrl(String newAvatarUrl) async {
    if (state.user == null) return;
    final updatedUser = state.user!.copyWith(avatarUrl: newAvatarUrl);
    await _storage.saveUser(updatedUser);
    state = state.copyWith(user: updatedUser);
  }

  Future<void> logout() async {
    SocketService().disconnect();
    await _storage.clearAll();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Connection timed out') ||
        msg.contains('Failed host lookup')) {
      return 'Serveur inaccessible. Vérifiez la connexion.';
    }
    if (msg.contains('401')) return 'Identifiants incorrects.';
    if (msg.contains('403')) return 'Compte suspendu ou non vérifié.';
    if (msg.contains('409')) return 'Numéro déjà utilisé.';
    return 'Erreur réseau. Réessayez.';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
