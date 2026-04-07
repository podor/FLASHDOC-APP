// lib/features/prescriptions/prescriptions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../features/home/home_screen.dart';

final prescriptionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiService().getPatientPrescriptions();
    if (res['success'] == true) {
      return (res['data']['prescriptions'] as List? ?? [])
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
    }
  } catch (_) {}
  return [];
});

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescAsync = ref.watch(prescriptionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Mes ordonnances',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () => ref.invalidate(prescriptionsProvider)),
        ],
      ),
      body: prescAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _EmptyState(),
        data: (list) => list.isEmpty ? _EmptyState() : _PrescriptionList(prescriptions: list),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 1),
    );
  }
}

class _PrescriptionList extends StatelessWidget {
  final List<Map<String, dynamic>> prescriptions;
  const _PrescriptionList({required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PrescriptionCard(prescription: prescriptions[i]),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'fr_FR');
    final hash = prescription['hash'] as String? ?? '';
    final issuedAt = prescription['issuedAt'] != null
        ? DateTime.tryParse(prescription['issuedAt'] as String) : null;
    final doctor = prescription['doctor'] as Map<String, dynamic>? ?? {};
    final meds = prescription['medications'] as List? ?? [];

    return GestureDetector(
      onTap: () => _showDetail(context, prescription),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.doctorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.description_rounded,
                  color: AppColors.doctorPrimary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dr. ${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
              Text(doctor['speciality'] as String? ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (issuedAt != null)
                Text(df.format(issuedAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Certifiée', style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: AppColors.success))),
            ]),
          ]),

          if (meds.isNotEmpty) ...[
            const Divider(height: 20),
            Wrap(spacing: 6, runSpacing: 6,
              children: meds.take(3).map((m) {
                final med = m as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(med['name'] as String? ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: AppColors.primary)));
              }).toList()),
            if (meds.length > 3)
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text('+${meds.length - 3} autre(s)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint))),
          ],

          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.qr_code_2, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(hash, style: const TextStyle(fontSize: 10, color: AppColors.textHint,
                fontFamily: 'monospace')),
            const Spacer(),
            const Text('Voir l\'ordonnance', style: TextStyle(fontSize: 12,
                color: AppColors.primary, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> prescription) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => _PrescriptionDetail(
            prescription: prescription, scrollController: ctrl),
      ),
    );
  }
}

class _PrescriptionDetail extends StatelessWidget {
  final Map<String, dynamic> prescription;
  final ScrollController scrollController;
  const _PrescriptionDetail({required this.prescription, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final df  = DateFormat('dd MMMM yyyy', 'fr_FR');
    final tf  = DateFormat('HH:mm');
    final hash     = prescription['hash']    as String? ?? '';
    final qrData   = prescription['qrData']  as String? ?? hash;
    final issuedAt = prescription['issuedAt'] != null
        ? DateTime.tryParse(prescription['issuedAt'] as String) : null;
    final doctor   = prescription['doctor']  as Map<String, dynamic>? ?? {};
    final meds     = prescription['medications'] as List? ?? [];
    final diagnosis    = prescription['diagnosis']    as String? ?? '';
    final instructions = prescription['instructions'] as String? ?? '';

    return ListView(controller: scrollController, padding: const EdgeInsets.all(20), children: [
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border,
              borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),

      // En-tête
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.doctorPrimary,
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('ORDONNANCE MÉDICALE', style: TextStyle(color: Colors.white,
              fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('FlashDoc — Télémédecine Cameroun',
            style: TextStyle(color: Colors.white70, fontSize: 11)),
          if (issuedAt != null) ...[
            const SizedBox(height: 8),
            Text('${df.format(issuedAt)} à ${tf.format(issuedAt)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ])),
      const SizedBox(height: 16),

      // Médecin
      Row(children: [
        Expanded(child: _DetailChip(icon: Icons.medical_services_outlined,
            color: AppColors.doctorPrimary, label: 'Médecin',
            value: 'Dr. ${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}')),
        const SizedBox(width: 10),
        Expanded(child: _DetailChip(icon: Icons.verified_outlined,
            color: AppColors.success, label: 'Certification', value: hash, mono: true)),
      ]),
      const SizedBox(height: 16),

      // Diagnostic
      if (diagnosis.isNotEmpty)
        _DetailSection(icon: Icons.biotech_outlined, color: AppColors.warning,
            title: 'Diagnostic', content: diagnosis),
      const SizedBox(height: 12),

      // Médicaments
      if (meds.isNotEmpty)
        _DetailSection(
          icon: Icons.medication_outlined, color: AppColors.doctorPrimary,
          title: 'Médicaments',
          content: '',
          child: Column(
            children: meds.asMap().entries.map((e) {
              final m = e.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 22, height: 22,
                    decoration: const BoxDecoration(
                        color: AppColors.doctorPrimary, shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${m['dosage']} — ${m['frequency']} — ${m['duration']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if ((m['instructions'] as String?)?.isNotEmpty == true)
                      Text(m['instructions'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint,
                            fontStyle: FontStyle.italic)),
                  ])),
                ]),
              );
            }).toList()),
        ),
      const SizedBox(height: 12),

      if (instructions.isNotEmpty)
        _DetailSection(icon: Icons.info_outline, color: AppColors.secondary,
            title: 'Instructions', content: instructions),
      const SizedBox(height: 20),

      // QR Code
      Center(child: Column(children: [
        const Text('QR Code de certification', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: QrImageView(
            data: qrData.isNotEmpty ? qrData : hash,
            version: QrVersions.auto, size: 160,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.doctorPrimary),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A2E))),
        ),
        const SizedBox(height: 8),
        Text(hash, style: const TextStyle(fontFamily: 'monospace', fontSize: 11,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        const Text('Scannez pour vérifier l\'authenticité',
          style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 24),
      ])),
    ]);
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool mono;
  const _DetailChip({required this.icon, required this.color, required this.label,
      required this.value, this.mono = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 13), const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, fontFamily: mono ? 'monospace' : null)),
    ]));
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  final Widget? child;
  const _DetailSection({required this.icon, required this.color, required this.title,
      required this.content, this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color))]),
      const Divider(height: 14),
      if (child != null) child!
      else Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
    ]));
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.description_outlined, size: 64, color: AppColors.textHint),
      const SizedBox(height: 16),
      const Text('Aucune ordonnance', style: TextStyle(fontSize: 18,
          fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Vos ordonnances apparaîtront ici\naprès vos consultations.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
    ]));
}
