// lib/features/doctor/prescription/prescription_screen.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/fd_snackbar.dart';

// ── Modèle médicament ────────────────────────────────────────────
class Medication {
  String name;
  String dosage;
  String frequency;
  String duration;
  String? instructions;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'dosage': dosage, 'frequency': frequency,
    'duration': duration, 'instructions': instructions,
  };
}

class PrescriptionScreen extends ConsumerStatefulWidget {
  final String consultationId;
  final String patientName;
  final String patientId;

  const PrescriptionScreen({
    super.key,
    required this.consultationId,
    required this.patientName,
    required this.patientId,
  });

  @override
  ConsumerState<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends ConsumerState<PrescriptionScreen> {
  final List<Medication> _medications = [];
  final _diagnosisCtrl    = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _showPreview  = false;

  // Identifiant unique de l'ordonnance
  late final String _prescriptionId;
  late final String _prescriptionHash;
  late final DateTime _issuedAt;

  @override
  void initState() {
    super.initState();
    _issuedAt       = DateTime.now();
    _prescriptionId = const Uuid().v4();
    _prescriptionHash = _generateHash();
    _medications.add(Medication(
      name: '', dosage: '', frequency: '', duration: ''));
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  // ✅ Hash SHA-256 unique basé sur l'ID + consultation + timestamp
  String _generateHash() {
    final data = '$_prescriptionId:${widget.consultationId}:${widget.patientId}:${_issuedAt.millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 16).toUpperCase();
  }

  // Données embarquées dans le QR code
  String get _qrData => jsonEncode({
    'id':             _prescriptionId,
    'hash':           _prescriptionHash,
    'consultationId': widget.consultationId,
    'patientId':      widget.patientId,
    'issuedAt':       _issuedAt.toIso8601String(),
    'verify':         'https://flashdoc.cm/verify/$_prescriptionHash',
  });

  Future<void> _submit() async {
    if (_diagnosisCtrl.text.trim().isEmpty) {
      FdSnackbar.show(context, 'Entrez un diagnostic', isError: true); return;
    }
    final valid = _medications.every((m) =>
        m.name.isNotEmpty && m.dosage.isNotEmpty && m.frequency.isNotEmpty);
    if (!valid) {
      FdSnackbar.show(context, 'Remplissez tous les médicaments', isError: true); return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService().submitPrescription(
        consultationId: widget.consultationId,
        prescriptionId: _prescriptionId,
        hash:           _prescriptionHash,
        diagnosis:      _diagnosisCtrl.text.trim(),
        medications:    _medications.map((m) => m.toJson()).toList(),
        instructions:   _instructionsCtrl.text.trim(),
        issuedAt:       _issuedAt.toIso8601String(),
      );
      if (mounted) {
        FdSnackbar.show(context, 'Ordonnance envoyée au patient ✓');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) FdSnackbar.show(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.doctorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Rédiger une ordonnance',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showPreview = !_showPreview),
            icon: Icon(_showPreview ? Icons.edit : Icons.visibility,
                color: Colors.white, size: 18),
            label: Text(_showPreview ? 'Modifier' : 'Aperçu',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _showPreview
          ? _buildPreview(user)
          : _buildEditor(),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : (_showPreview ? _submit : () => setState(() => _showPreview = true)),
              icon: Icon(_showPreview ? Icons.send_rounded : Icons.visibility),
              label: Text(_showPreview ? 'Envoyer au patient' : 'Prévisualiser',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Éditeur ───────────────────────────────────────────────────────
  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info patient
        _Card(child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.doctorPrimary,
                borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              widget.patientName.isNotEmpty ? widget.patientName[0] : 'P',
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.patientName, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('ID: ${_prescriptionHash}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
                  fontFamily: 'monospace')),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Certifiée', style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: AppColors.success))),
        ])),
        const SizedBox(height: 12),

        // Diagnostic
        _SectionTitle('Diagnostic'),
        _Card(child: TextField(
          controller: _diagnosisCtrl, maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Ex: Grippe saisonnière avec fièvre modérée...',
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero),
        )),
        const SizedBox(height: 12),

        // Médicaments
        _SectionTitle('Médicaments prescrits'),
        ..._medications.asMap().entries.map((e) =>
          _MedicationCard(
            index: e.key,
            medication: e.value,
            onDelete: _medications.length > 1
                ? () => setState(() => _medications.removeAt(e.key))
                : null,
            onChange: () => setState(() {}),
          )),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _medications.add(
            Medication(name: '', dosage: '', frequency: '', duration: ''))),
          icon: const Icon(Icons.add_circle_outline, color: AppColors.doctorPrimary),
          label: const Text('Ajouter un médicament',
            style: TextStyle(color: AppColors.doctorPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),

        // Instructions générales
        _SectionTitle('Instructions générales'),
        _Card(child: TextField(
          controller: _instructionsCtrl, maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Repos, hydratation, suivi dans 7 jours...',
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
            border: InputBorder.none, contentPadding: EdgeInsets.zero),
        )),
        const SizedBox(height: 80),
      ]),
    );
  }

  // ── Aperçu ordonnance certifiée ────────────────────────────────────
  Widget _buildPreview(dynamic user) {
    final df = DateFormat('dd MMMM yyyy', 'fr_FR');
    final tf = DateFormat('HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // ── En-tête officiel ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.doctorPrimary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Flash', style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w800, color: Colors.white)),
                TextSpan(text: 'Doc', style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w800, color: Colors.white70)),
              ])),
              const SizedBox(height: 2),
              const Text('Plateforme de Télémédecine — Cameroun',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 14),
              const Text('ORDONNANCE MÉDICALE', style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                letterSpacing: 2)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Médecin + Patient
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _PreviewBlock(
                  icon: Icons.medical_services_outlined,
                  color: AppColors.doctorPrimary,
                  title: 'Prescripteur',
                  content: 'Dr. ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                )),
                const SizedBox(width: 12),
                Expanded(child: _PreviewBlock(
                  icon: Icons.person_outline,
                  color: AppColors.primary,
                  title: 'Patient',
                  content: widget.patientName,
                )),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _PreviewBlock(
                  icon: Icons.calendar_today_outlined,
                  color: AppColors.secondary,
                  title: 'Date',
                  content: '${df.format(_issuedAt)} à ${tf.format(_issuedAt)}',
                )),
                const SizedBox(width: 12),
                Expanded(child: _PreviewBlock(
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                  title: 'Code certifié',
                  content: _prescriptionHash,
                  mono: true,
                )),
              ]),
              const SizedBox(height: 20),

              // Diagnostic
              if (_diagnosisCtrl.text.trim().isNotEmpty) ...[
                _PreviewSection(
                  icon: Icons.biotech_outlined,
                  title: 'Diagnostic',
                  color: AppColors.warning,
                  child: Text(_diagnosisCtrl.text.trim(),
                    style: const TextStyle(fontSize: 14, height: 1.5))),
                const SizedBox(height: 16),
              ],

              // Médicaments
              _PreviewSection(
                icon: Icons.medication_outlined,
                title: 'Médicaments prescrits',
                color: AppColors.doctorPrimary,
                child: Column(children: _medications
                    .where((m) => m.name.isNotEmpty)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => _MedPreviewRow(index: e.key + 1, med: e.value))
                    .toList())),
              const SizedBox(height: 16),

              // Instructions
              if (_instructionsCtrl.text.trim().isNotEmpty) ...[
                _PreviewSection(
                  icon: Icons.info_outline,
                  title: 'Instructions',
                  color: AppColors.secondary,
                  child: Text(_instructionsCtrl.text.trim(),
                    style: const TextStyle(fontSize: 14, height: 1.5))),
                const SizedBox(height: 20),
              ],

              // ✅ QR Code de certification
              Center(child: Column(children: [
                const Divider(),
                const SizedBox(height: 16),
                const Text('Certification de l\'ordonnance',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 140,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.doctorPrimary),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1A2E)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('ID: $_prescriptionHash',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11,
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                const Text('Scannez ce code pour vérifier l\'authenticité',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                const SizedBox(height: 16),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets helpers ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: AppColors.textSecondary)));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
    child: child);
}

class _MedicationCard extends StatelessWidget {
  final int index;
  final Medication medication;
  final VoidCallback? onDelete;
  final VoidCallback onChange;
  const _MedicationCard({required this.index, required this.medication,
      this.onDelete, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.doctorPrimary.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: AppColors.doctorPrimary, shape: BoxShape.circle),
            child: Center(child: Text('$index',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 8),
          const Text('Médicament', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          if (onDelete != null)
            GestureDetector(onTap: onDelete,
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18)),
        ]),
        const SizedBox(height: 10),
        _MedField('Nom du médicament *', (v) { medication.name = v; onChange(); }),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _MedField('Dosage *', (v) { medication.dosage = v; onChange(); })),
          const SizedBox(width: 8),
          Expanded(child: _MedField('Fréquence *', (v) { medication.frequency = v; onChange(); }, hint: 'Ex: 3x/jour')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _MedField('Durée *', (v) { medication.duration = v; onChange(); }, hint: 'Ex: 7 jours')),
          const SizedBox(width: 8),
          Expanded(child: _MedField('Instructions', (v) { medication.instructions = v; onChange(); }, hint: 'Avec repas...')),
        ]),
      ]),
    );
  }
}

class _MedField extends StatelessWidget {
  final String label;
  final Function(String) onChanged;
  final String? hint;
  const _MedField(this.label, this.onChanged, {this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint ?? label.replaceAll(' *', ''),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
          filled: true, fillColor: AppColors.surfaceGrey,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      ),
    ]);
  }
}

class _PreviewBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  final bool mono;
  const _PreviewBlock({required this.icon, required this.color, required this.title,
      required this.content, this.mono = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 14), const SizedBox(width: 5),
        Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      Text(content, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: mono ? 'monospace' : null)),
    ]));
}

class _PreviewSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;
  const _PreviewSection({required this.icon, required this.color,
      required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
      const Divider(height: 16),
      child,
    ]));
}

class _MedPreviewRow extends StatelessWidget {
  final int index;
  final Medication med;
  const _MedPreviewRow({required this.index, required this.med});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 22, height: 22,
        decoration: const BoxDecoration(color: AppColors.doctorPrimary, shape: BoxShape.circle),
        child: Center(child: Text('$index',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700,
            fontSize: 14, color: AppColors.textPrimary)),
        Text('${med.dosage} — ${med.frequency} — ${med.duration}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (med.instructions?.isNotEmpty == true)
          Text(med.instructions!, style: const TextStyle(fontSize: 11,
              color: AppColors.textHint, fontStyle: FontStyle.italic)),
      ])),
    ]));
}
