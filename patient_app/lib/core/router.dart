// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';

import '../features/home/home_screen.dart';
import '../features/consultation/screens/symptoms_screen.dart';
import '../features/consultation/screens/mode_screen.dart';
import '../features/consultation/screens/payment_screen.dart';
import '../features/consultation/screens/waiting_screen.dart';
import '../features/consultation/screens/consultation_screen.dart';
import '../features/consultation/screens/rating_screen.dart';
import '../features/consultation/screens/doctor_found_screen.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/appointments/appointment_screen.dart';
import '../features/prescriptions/prescriptions_screen.dart';

import '../features/doctor/home/doctor_home_screen.dart';
import '../features/doctor/requests/doctor_requests_screen.dart';
import '../features/doctor/consultation/doctor_consultation_screen.dart';
import '../features/doctor/wallet/doctor_wallet_screen.dart';
import '../features/doctor/profile/doctor_profile_screen.dart';
import '../features/doctor/onboarding/doctor_onboarding_screen.dart';
import '../features/doctor/screens/patient_connected_screen.dart';
import '../features/doctor/prescription/prescription_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuth    = authState.isAuthenticated;
      final role      = authState.user?.role;
      final path      = state.matchedLocation;

      if (isLoading) {
        if (path == '/splash') return null;
        return '/splash';
      }

      const publicRoutes = ['/splash', '/onboarding', '/login', '/register'];
      final isPublic = publicRoutes.contains(path) || path.startsWith('/otp');

      if (!isAuth && !isPublic) return '/login';

      if (isAuth && isPublic && path != '/splash') {
        return role == 'DOCTOR' ? '/doctor/home' : '/patient/home';
      }

      if (isAuth && role == 'PATIENT' && path.startsWith('/doctor')) {
        return '/patient/home';
      }
      if (isAuth && role == 'DOCTOR' && path.startsWith('/patient')) {
        return '/doctor/home';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/splash',     builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/otp',
        builder: (_, state) => OtpScreen(
            phone: state.uri.queryParameters['phone'] ?? '')),

      // ════════ PATIENT ════════
      GoRoute(path: '/patient/home',         builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/patient/history',      builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/patient/profile',      builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/patient/appointments', builder: (_, __) => const AppointmentScreen()),
      GoRoute(path: '/patient/prescriptions',builder: (_, __) => const PrescriptionsScreen()),

      GoRoute(path: '/patient/consult/symptoms',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SymptomsScreen(
            preSelectedSpec: extra['preSelectedSpec'] as String?,
            preSelectedMode: extra['preSelectedMode'] as String?,
          );
        }),
      GoRoute(path: '/patient/consult/mode',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ModeScreen(
            speciality:      extra['speciality']      as String? ?? 'Généraliste',
            symptomsText:    extra['symptomsText']    as String?,
            preSelectedMode: extra['preSelectedMode'] as String?,
          );
        }),
      GoRoute(path: '/patient/consult/payment',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentScreen(
            consultationId: extra['consultationId'] as String? ?? '',
            amount: (extra['amount'] as num?)?.toDouble() ?? 0,
            mode:   extra['mode'] as String? ?? 'VIDEO',
          );
        }),
      GoRoute(path: '/patient/consult/waiting',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return WaitingScreen(consultationId: extra['consultationId'] as String? ?? '');
        }),
      GoRoute(path: '/patient/consult/doctor-found',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DoctorFoundScreen(
            consultationId:   extra['consultationId']   as String? ?? '',
            doctorFirstName:  extra['doctorFirstName']  as String? ?? '',
            doctorLastName:   extra['doctorLastName']   as String? ?? '',
            doctorSpeciality: extra['doctorSpeciality'] as String? ?? 'Généraliste',
            doctorRating:     (extra['doctorRating'] as num?)?.toDouble() ?? 0,
            doctorAvatarUrl:  extra['doctorAvatarUrl']  as String?,
            mode:             extra['mode']              as String? ?? 'CHAT',
          );
        }),
      GoRoute(path: '/patient/consult/session',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConsultationScreen(consultationId: extra['consultationId'] as String? ?? '');
        }),
      GoRoute(path: '/patient/consult/rating',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RatingScreen(consultationId: extra['consultationId'] as String? ?? '');
        }),

      // Aliases
      GoRoute(path: '/home',    redirect: (_, __) => '/patient/home'),
      GoRoute(path: '/history', redirect: (_, __) => '/patient/history'),
      GoRoute(path: '/profile', redirect: (_, __) => '/patient/profile'),
      GoRoute(path: '/consult/symptoms', redirect: (_, __) => '/patient/consult/symptoms'),

      // ════════ DOCTOR ════════
      GoRoute(path: '/doctor/home',     builder: (_, __) => const DoctorHomeScreen()),
      GoRoute(path: '/doctor/requests', builder: (_, __) => const DoctorRequestsScreen()),
      GoRoute(path: '/doctor/wallet',   builder: (_, __) => const DoctorWalletScreen()),
      GoRoute(path: '/doctor/profile',  builder: (_, __) => const DoctorProfileScreen()),
      GoRoute(path: '/doctor/onboarding', builder: (_, __) => const DoctorOnboardingScreen()),

      GoRoute(path: '/doctor/patient-connected',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PatientConnectedScreen(
            consultationId:   extra['consultationId']   as String? ?? '',
            patientFirstName: extra['patientFirstName'] as String? ?? '',
            patientLastName:  extra['patientLastName']  as String? ?? '',
            speciality:       extra['speciality']        as String? ?? 'Généraliste',
            mode:             extra['mode']              as String? ?? 'CHAT',
            symptomsText:     extra['symptomsText']      as String?,
          );
        }),
      GoRoute(path: '/doctor/consultation',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DoctorConsultationScreen(consultationId: extra['consultationId'] as String? ?? '');
        }),
      GoRoute(path: '/doctor/prescription',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PrescriptionScreen(
            consultationId: extra['consultationId'] as String? ?? '',
            patientName:    extra['patientName']    as String? ?? '',
            patientId:      extra['patientId']      as String? ?? '',
          );
        }),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        const Text('Page introuvable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(state.error?.toString() ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
      ])),
    ),
  );
});
