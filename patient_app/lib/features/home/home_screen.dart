// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Image.asset('assets/images/logo_flashdoc.png', height: 36,
                    errorBuilder: (_, __, ___) => RichText(text: const TextSpan(children: [
                      TextSpan(text: 'Flash', style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, color: AppColors.primary)),
                      TextSpan(text: 'Doc', style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, color: AppColors.secondary)),
                    ]))),
                  const Spacer(),
                  Stack(children: [
                    Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.textPrimary, size: 22)),
                    Positioned(top: 6, right: 6, child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.consultNow, shape: BoxShape.circle))),
                  ]),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => context.go('/patient/profile'),
                    child: CircleAvatar(radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(user?.initials ?? '?',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ),
                ]),
              ),

              // ── Salutation ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Bonjour ${user?.firstName ?? 'Jean'} ',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                    const Text('👋', style: TextStyle(fontSize: 22)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Comment vous sentez-vous aujourd\'hui ?',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Bouton Consulter maintenant ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.push('/patient/consult/symptoms'),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppColors.consultGradient,
                        borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 18)),
                          const SizedBox(width: 10),
                          const Text('Consulter maintenant',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        ]),
                        const SizedBox(height: 8),
                        Text('Disponible en moins de 2 min.',
                          style: TextStyle(fontSize: 13,
                              color: Colors.white.withOpacity(0.85))),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 20),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Actions rapides ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  // ✅ "Prendre rendez-vous" → écran dédié
                  Expanded(child: _QuickAction(
                    icon: Icons.calendar_month_outlined,
                    label: 'Prendre rendez-vous',
                    color: AppColors.primary,
                    onTap: () => _showAppointmentDialog(context),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(
                    icon: Icons.assignment_outlined,
                    label: 'Mes consultations',
                    color: AppColors.secondary,
                    onTap: () => context.go('/patient/history'),
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Spécialités ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Spécialités',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => context.push('/patient/consult/symptoms'),
                    child: const Text('Voir tout',
                      style: TextStyle(color: AppColors.primary, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SpecialityItem(name: 'Généraliste', emoji: '👨‍⚕️', checked: true,
                      onTap: () => context.push('/patient/consult/symptoms',
                          extra: {'preSelectedSpec': 'Généraliste'})),
                    _SpecialityItem(name: 'Pédiatre', emoji: '👶', checked: true,
                      onTap: () => context.push('/patient/consult/symptoms',
                          extra: {'preSelectedSpec': 'Pédiatre'})),
                    _SpecialityItem(name: 'Dermatologue', emoji: '🔬', checked: false,
                      onTap: () => context.push('/patient/consult/symptoms',
                          extra: {'preSelectedSpec': 'Dermatologue'})),
                    _SpecialityItem(name: 'Cardiologue', emoji: '❤️', checked: false,
                      onTap: () => context.push('/patient/consult/symptoms',
                          extra: {'preSelectedSpec': 'Cardiologue'})),
                    _SpecialityItem(name: 'ORL', emoji: '👂', checked: false,
                      onTap: () => context.push('/patient/consult/symptoms',
                          extra: {'preSelectedSpec': 'ORL'})),
                    _SpecialityItem(name: 'Gynécologue', emoji: '🩺', checked: false,
                      onTap: () => context.push('/patient/consult/symptoms',
                          extra: {'preSelectedSpec': 'Gynécologue'})),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Modes de consultation ────────────────────────────
              // ✅ Chaque mode navigue vers symptoms avec le mode pré-sélectionné
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('Mode de consultation',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  _ConsultModeCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat', price: '5 000 FCFA',
                    color: AppColors.primary,
                    // ✅ Va directement au mode CHAT dans l'écran symptoms→mode
                    onTap: () => context.push('/patient/consult/symptoms',
                        extra: {'preSelectedMode': 'CHAT'}),
                  ),
                  const SizedBox(height: 10),
                  _ConsultModeCard(
                    icon: Icons.mic_none_rounded,
                    label: 'Audio', price: '8 000 FCFA',
                    color: AppColors.secondary,
                    onTap: () => context.push('/patient/consult/symptoms',
                        extra: {'preSelectedMode': 'AUDIO'}),
                  ),
                  const SizedBox(height: 10),
                  _ConsultModeCard(
                    icon: Icons.videocam_outlined,
                    label: 'Vidéo', price: '10 000 FCFA',
                    color: AppColors.consultNow,
                    onTap: () => context.push('/patient/consult/symptoms',
                        extra: {'preSelectedMode': 'VIDEO'}),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 0),
    );
  }

  // ✅ Dialog "Prendre rendez-vous" — fonctionnel
  void _showAppointmentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.calendar_month_outlined,
              size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text('Prendre rendez-vous',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Les rendez-vous physiques seront disponibles dans la prochaine version.\n\n'
            'Pour l\'instant, profitez de nos consultations en ligne immédiates !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/patient/consult/symptoms');
              },
              icon: const Icon(Icons.flash_on_rounded),
              label: const Text('Consulter maintenant',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.consultNow,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer',
                style: TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surfaceGrey,
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              maxLines: 2)),
        ]),
      ),
    );
  }
}

class _SpecialityItem extends StatelessWidget {
  final String name;
  final String emoji;
  final bool checked;
  final VoidCallback onTap;
  const _SpecialityItem({required this.name, required this.emoji,
      required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, margin: const EdgeInsets.only(right: 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(14),
                border: checked ? Border.all(color: AppColors.primary, width: 1.5) : null,
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26)))),
            if (checked) Positioned(right: 0, top: 0,
                child: Container(width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 12))),
          ]),
          const SizedBox(height: 6),
          Text(name, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _ConsultModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  final Color color;
  final VoidCallback onTap;
  const _ConsultModeCard({required this.icon, required this.label,
      required this.price, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Text(price, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

// ── Navigation Patient ────────────────────────────────────────────
class PatientBottomNav extends StatelessWidget {
  final int currentIndex;
  const PatientBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: BottomNavigationBar(
        currentIndex: currentIndex, elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
        onTap: (i) {
          if (i == 0) context.go('/patient/home');
          if (i == 1) context.go('/patient/history');
          if (i == 2) context.go('/patient/profile');
        },
      ),
    );
  }
}
