      GoRoute(
        path: '/patient/consult/symptoms',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SymptomsScreen(
            preSelectedSpec: extra['preSelectedSpec'] as String?,
            preSelectedMode: extra['preSelectedMode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/patient/consult/mode',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ModeScreen(
            speciality:      extra['speciality'] as String? ?? 'Généraliste',
            symptomsText:    extra['symptomsText'] as String?,
            preSelectedMode: extra['preSelectedMode'] as String?,
          );
        },
      ),