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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(children: [
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'Flash', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
                    TextSpan(text: 'Doc', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: AppColors.secondary)),
                  ])),
                  const Spacer(),
                  // Notifications
                  Stack(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.textPrimary, size: 22)),
                    Positioned(top: 7, right: 7, child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.consultNow,
                            shape: BoxShape.circle))),
                  ]),
                  const SizedBox(width: 10),
                  // Avatar
                  GestureDetector(
                    onTap: () => context.go('/patient/profile'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary,
                            AppColors.primary.withBlue(220)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(child: Text(user?.initials ?? '?',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: Colors.white))),
                    ),
                  ),
                ]),
              ),

              // ── Salutation + Hero CTA ────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text('Bonjour ${user?.firstName ?? ''} ',
                      style: const TextStyle(fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                    const Text('👋', style: TextStyle(fontSize: 22)),
                  ]),
                  const SizedBox(height: 2),
                  const Text('Comment vous sentez-vous aujourd\'hui ?',
                    style: TextStyle(fontSize: 14,
                        color: AppColors.textSecondary)),
                  const SizedBox(height: 18),

                  // ── Bouton Consulter maintenant ──────────────────
                  GestureDetector(
                    onTap: () => context.push('/patient/consult/symptoms'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5A3C), Color(0xFFFF8A3C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFFFF5A3C).withOpacity(0.35),
                            blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Consulter maintenant',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Médecin disponible en < 2 min',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.white.withOpacity(0.9))),
                          ]),
                        ])),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Actions rapides ──────────────────────────────
                  Row(children: [
                    Expanded(child: _QuickAction(
                      icon: Icons.calendar_month_outlined,
                      label: 'Rendez-vous',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF4D94FF)]),
                      onTap: () => _showAppointmentDialog(context),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickAction(
                      icon: Icons.history_outlined,
                      label: 'Historique',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A878), Color(0xFF00C896)]),
                      onTap: () => context.go('/patient/history'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickAction(
                      icon: Icons.description_outlined,
                      label: 'Ordonnances',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                      onTap: () => context.go('/patient/prescriptions'),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),

              // ── Spécialités ──────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const Text('Spécialités',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                  GestureDetector(
                    onTap: () => context.push('/patient/consult/symptoms'),
                    child: const Text('Voir tout',
                      style: TextStyle(color: AppColors.primary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _SpecialityChip(name: 'Généraliste', emoji: '👨‍⚕️',
                          color: AppColors.primary,
                          onTap: () => context.push('/patient/consult/symptoms',
                              extra: {'preSelectedSpec': 'Généraliste'})),
                      _SpecialityChip(name: 'Pédiatre', emoji: '👶',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/patient/consult/symptoms',
                              extra: {'preSelectedSpec': 'Pédiatre'})),
                      _SpecialityChip(name: 'Cardiologue', emoji: '❤️',
                          color: AppColors.consultNow,
                          onTap: () => context.push('/patient/consult/symptoms',
                              extra: {'preSelectedSpec': 'Cardiologue'})),
                      _SpecialityChip(name: 'Dermatologue', emoji: '🔬',
                          color: AppColors.secondary,
                          onTap: () => context.push('/patient/consult/symptoms',
                              extra: {'preSelectedSpec': 'Dermatologue'})),
                      _SpecialityChip(name: 'ORL', emoji: '👂',
                          color: const Color(0xFFF59E0B),
                          onTap: () => context.push('/patient/consult/symptoms',
                              extra: {'preSelectedSpec': 'ORL'})),
                      _SpecialityChip(name: 'Gynécologue', emoji: '🩺',
                          color: const Color(0xFFEC4899),
                          onTap: () => context.push('/patient/consult/symptoms',
                              extra: {'preSelectedSpec': 'Gynécologue'})),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Modes de consultation ────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Mode de consultation',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  _ConsultModeCard(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Consultation Chat',
                    sublabel: 'Échangez par messages texte',
                    price: '5 000 FCFA',
                    color: AppColors.primary,
                    onTap: () => context.push('/patient/consult/symptoms',
                        extra: {'preSelectedMode': 'CHAT'}),
                  ),
                  const SizedBox(height: 10),
                  _ConsultModeCard(
                    icon: Icons.mic_rounded,
                    label: 'Consultation Audio',
                    sublabel: 'Appel vocal avec le médecin',
                    price: '8 000 FCFA',
                    color: AppColors.secondary,
                    onTap: () => context.push('/patient/consult/symptoms',
                        extra: {'preSelectedMode': 'AUDIO'}),
                  ),
                  const SizedBox(height: 10),
                  _ConsultModeCard(
                    icon: Icons.videocam_rounded,
                    label: 'Consultation Vidéo',
                    sublabel: 'Face à face en visioconférence',
                    price: '10 000 FCFA',
                    color: AppColors.consultNow,
                    isPopular: true,
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

  void _showAppointmentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_outlined,
                size: 36, color: AppColors.primary)),
          const SizedBox(height: 16),
          const Text('Rendez-vous physique',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Les rendez-vous physiques arrivent bientôt.\nEn attendant, consultez en ligne en moins de 2 minutes !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary,
                height: 1.6)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
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
        ]),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
      required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: gradient,
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 3))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _SpecialityChip extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _SpecialityChip({required this.name, required this.emoji,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, margin: const EdgeInsets.only(right: 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            ),
            child: Center(child: Text(emoji,
                style: const TextStyle(fontSize: 28)))),
          const SizedBox(height: 6),
          Text(name, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
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
  final String sublabel;
  final String price;
  final Color color;
  final bool isPopular;
  final VoidCallback onTap;
  const _ConsultModeCard({required this.icon, required this.label,
      required this.sublabel, required this.price, required this.color,
      this.isPopular = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isPopular ? color : AppColors.border,
                width: isPopular ? 1.5 : 1),
            boxShadow: [BoxShadow(
                color: isPopular
                    ? color.withOpacity(0.12) : Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Populaire',
                    style: TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w700, color: Colors.white))),
              ],
            ]),
            const SizedBox(height: 2),
            Text(sublabel, style: const TextStyle(fontSize: 12,
                color: AppColors.textSecondary)),
          ])),
          Text(price, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: color.withOpacity(0.6)),
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
      decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, -3))]),
      child: BottomNavigationBar(
        currentIndex: currentIndex, elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
