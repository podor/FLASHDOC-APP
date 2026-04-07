      GoRoute(path: '/patient/consult/symptoms',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SymptomsScreen(
            preSelectedSpec: extra['preSelectedSpec'] as String?,
          );
        }),