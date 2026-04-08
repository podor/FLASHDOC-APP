// lib/features/doctor/screens/application_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

final applicationStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().getDoctorApplicationStatus();
  return res['data'] as Map<String, dynamic>;
});

class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(applicationStatusProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop()),
        title: const Text("Mon dossier d'affiliation",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00A878))),
        error: (_, __) => _buildNoApplication(context),
        data: (data) => _buildStatus(context, ref, data),
      ),
    );
  }

  Widget _buildNoApplication(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(color: const Color(0xFFE8F8F3), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.folder_outlined, size: 52, color: Color(0xFF00A878))),
        const SizedBox(height: 24),
        const Text("Aucun dossier soumis",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        const Text("Rejoignez FlashDoc et commencez à consulter des patients depuis votre smartphone.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6)),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/doctor/onboarding'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A878), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: const Text("Soumettre mon dossier",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ]),
    );
  }

  Widget _buildStatus(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'UNKNOWN';
    final message = data['message'] as String? ?? '';

    final configs = {
      'APPROVED':          {'color': const Color(0xFF10B981), 'icon': Icons.verified_rounded,    'label': 'Médecin certifié FlashDoc ✓'},
      'PENDING_INTERVIEW': {'color': const Color(0xFF0066FF), 'icon': Icons.videocam_outlined,   'label': "Interview à planifier"},
      'PENDING_REVIEW':    {'color': const Color(0xFFF59E0B), 'icon': Icons.hourglass_top_rounded,'label': "Dossier en cours d'examen"},
      'SUSPENDED':         {'color': const Color(0xFFEF4444), 'icon': Icons.pause_circle_outline, 'label': 'Compte suspendu'},
    };
    final cfg = configs[status] ?? {'color': const Color(0xFF6B7280), 'icon': Icons.info_outline, 'label': 'Statut inconnu'};
    final color = cfg['color'] as Color;

    final steps = ['Dossier soumis', 'Documents vérifiés', 'Validation ONMC', 'Interview vidéo', 'Compte activé !'];
    final icons = [Icons.send_outlined, Icons.fact_check_outlined, Icons.verified_outlined, Icons.videocam_outlined, Icons.check_circle_outline];
    final completedMap = {'APPROVED': 5, 'PENDING_INTERVIEW': 3, 'PENDING_REVIEW': 1, 'PENDING_DOCS': 0};
    final activeMap = {'PENDING_DOCS': 0, 'PENDING_REVIEW': 1, 'PENDING_INTERVIEW': 3, 'APPROVED': -1};
    final completed = completedMap[status] ?? 0;
    final active = activeMap[status] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Banner statut
        Container(width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3))),
          child: Column(children: [
            Icon(cfg['icon'] as IconData, color: color, size: 48),
            const SizedBox(height: 12),
            Text(cfg['label'] as String,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
          ])),
        const SizedBox(height: 24),

        // Timeline
        const Text("Processus d'affiliation",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            children: List.generate(steps.length, (i) {
              final isDone   = i < completed;
              final isActive = i == active;
              final isLast   = i == steps.length - 1;
              final stepColor = isDone ? const Color(0xFF10B981)
                  : isActive ? const Color(0xFF00A878) : const Color(0xFF6B7280);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(width: 32, height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: isDone ? const Color(0xFF10B981)
                          : isActive ? const Color(0xFF00A878) : const Color(0xFFF5F7FA),
                      border: Border.all(color: isDone ? const Color(0xFF10B981)
                          : isActive ? const Color(0xFF00A878)
                          : const Color(0xFFE5E7EB), width: 2)),
                    child: Center(child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Icon(icons[i], color: isActive ? Colors.white : const Color(0xFF6B7280), size: 15))),
                  if (!isLast) Container(width: 2, height: 32,
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFFE5E7EB)),
                ]),
                const SizedBox(width: 14),
                Expanded(child: Padding(
                  padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 28),
                  child: Row(children: [
                    Expanded(child: Text(steps[i],
                      style: TextStyle(fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: stepColor))),
                    if (isActive)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE8F8F3),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Text('EN COURS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF00A878)))),
                    if (isDone)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  ]),
                )),
              ]);
            }),
          )),
        const SizedBox(height: 24),

        // Info dossier
        if (data['submittedAt'] != null) ...[
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _infoRow('Soumis le', _fmt(data['submittedAt'])),
              const SizedBox(height: 8),
              _infoRow('Référence', ((data['doctorId'] ?? '') as String).isNotEmpty
                  ? (data['doctorId'] as String).substring(0, 8).toUpperCase() : '—'),
            ])),
          const SizedBox(height: 24),
        ],

        // Bouton refresh
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => ref.refresh(applicationStatusProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Actualiser le statut'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00A878),
              side: const BorderSide(color: Color(0xFF00A878)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),

        if (status == 'APPROVED') ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/doctor/home'),
              icon: const Icon(Icons.dashboard_outlined, size: 18),
              label: const Text('Accéder au tableau de bord', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
        ],

        const SizedBox(height: 24),

        // Support
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.15))),
          child: const Row(children: [
            Icon(Icons.support_agent_outlined, color: Color(0xFF0066FF), size: 24),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Besoin d\'aide ?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
              SizedBox(height: 2),
              Text('Contactez : support@flashdoc.cm', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
          ])),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
    ]);
  }

  String _fmt(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }
}
