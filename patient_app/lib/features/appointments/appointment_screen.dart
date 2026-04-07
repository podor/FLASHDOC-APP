// lib/features/appointments/appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/fd_snackbar.dart';
import '../home/home_screen.dart';

class AppointmentScreen extends ConsumerStatefulWidget {
  const AppointmentScreen({super.key});

  @override
  ConsumerState<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends ConsumerState<AppointmentScreen> {
  DateTime _focusedDay   = DateTime.now();
  DateTime? _selectedDay = DateTime.now().add(const Duration(days: 1));
  CalendarFormat _format = CalendarFormat.month;

  String? _selectedSpeciality;
  String? _selectedTime;
  String _appointmentType = 'PHYSICAL';
  final _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;

  static const _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30',
  ];

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  bool _isWeekend(DateTime day) =>
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

  bool _isPast(DateTime day) =>
      day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _submit() async {
    if (_selectedDay == null) {
      FdSnackbar.show(context, 'Sélectionnez une date', isError: true); return;
    }
    if (_selectedTime == null) {
      FdSnackbar.show(context, 'Sélectionnez un créneau horaire', isError: true); return;
    }
    if (_selectedSpeciality == null) {
      FdSnackbar.show(context, 'Sélectionnez une spécialité', isError: true); return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      FdSnackbar.show(context, 'Décrivez le motif du rendez-vous', isError: true); return;
    }

    setState(() => _isSubmitting = true);
    try {
      final parts = _selectedTime!.split(':');
      final scheduledAt = DateTime(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );

      await ApiService().createAppointment(
        speciality:  _selectedSpeciality!,
        scheduledAt: scheduledAt.toIso8601String(),
        type:        _appointmentType,
        reason:      _reasonCtrl.text.trim(),
      );

      if (mounted) _showConfirmation(scheduledAt);
    } catch (e) {
      if (mounted) FdSnackbar.show(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showConfirmation(DateTime scheduledAt) {
    final df = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40)),
          const SizedBox(height: 16),
          const Text('Rendez-vous confirmé !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('${df.format(scheduledAt)}\nà $_selectedTime',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 4),
          Text(_selectedSpeciality!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.primary)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Retour à l\'accueil',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Prendre rendez-vous',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Type de consultation
          _SectionTitle('Type de consultation'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _TypeButton(
              icon: Icons.local_hospital_outlined,
              label: 'Consultation physique',
              selected: _appointmentType == 'PHYSICAL',
              onTap: () => setState(() => _appointmentType = 'PHYSICAL'))),
            const SizedBox(width: 10),
            Expanded(child: _TypeButton(
              icon: Icons.videocam_outlined,
              label: 'En ligne (vidéo)',
              selected: _appointmentType == 'ONLINE',
              onTap: () => setState(() => _appointmentType = 'ONLINE'))),
          ]),
          const SizedBox(height: 20),

          // Spécialité
          _SectionTitle('Spécialité *'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: AppConstants.specialities.map((s) => ChoiceChip(
              label: Text(s, style: TextStyle(fontSize: 12,
                  fontWeight: _selectedSpeciality == s ? FontWeight.w700 : FontWeight.w400,
                  color: _selectedSpeciality == s ? AppColors.primary : AppColors.textSecondary)),
              selected: _selectedSpeciality == s,
              onSelected: (_) => setState(() => _selectedSpeciality = s),
              selectedColor: AppColors.primary.withOpacity(0.12),
              checkmarkColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _selectedSpeciality == s
                      ? AppColors.primary : AppColors.border)),
            )).toList()),
          const SizedBox(height: 20),

          // Calendrier
          _SectionTitle('Date du rendez-vous *'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border)),
            child: TableCalendar(
              firstDay:  DateTime.now(),
              lastDay:   DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              calendarFormat: _format,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mois',
                CalendarFormat.twoWeeks: '2 semaines',
              },
              onFormatChanged: (f) => setState(() => _format = f),
              enabledDayPredicate: (d) => !_isWeekend(d) && !_isPast(d),
              onDaySelected: (selected, focused) {
                if (!_isWeekend(selected) && !_isPast(selected)) {
                  setState(() {
                    _selectedDay  = selected;
                    _focusedDay   = focused;
                    _selectedTime = null;
                  });
                }
              },
              onPageChanged: (f) => setState(() => _focusedDay = f),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
                weekendTextStyle: const TextStyle(color: AppColors.textHint),
                disabledTextStyle: const TextStyle(color: AppColors.border),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
              locale: 'fr_FR',
            ),
          ),
          const SizedBox(height: 20),

          // Créneaux horaires
          if (_selectedDay != null) ...[
            _SectionTitle('Créneau horaire *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _timeSlots.map((t) {
                final isSelected = _selectedTime == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border)),
                    child: Text(t, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Motif
          _SectionTitle('Motif du rendez-vous *'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: TextField(
              controller: _reasonCtrl, maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Décrivez brièvement le motif de votre consultation...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14)),
            ),
          ),
          const SizedBox(height: 24),

          // Récapitulatif
          if (_selectedDay != null && _selectedTime != null && _selectedSpeciality != null)
            _RecapCard(
              date:       _selectedDay!,
              time:       _selectedTime!,
              speciality: _selectedSpeciality!,
              type:       _appointmentType,
            ),
          const SizedBox(height: 16),

          // Bouton confirmer
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isSubmitting ? 'Confirmation...' : 'Confirmer le rendez-vous',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary));
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border, width: 1.5)),
        child: Column(children: [
          Icon(icon,
              color: selected ? Colors.white : AppColors.textSecondary, size: 24),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  final DateTime date;
  final String time;
  final String speciality;
  final String type;
  const _RecapCard({required this.date, required this.time,
      required this.speciality, required this.type});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.event_available_rounded, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Text('Récapitulatif', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const Divider(height: 16),
        _RecapRow(Icons.calendar_today_outlined, df.format(date)),
        _RecapRow(Icons.access_time_rounded, time),
        _RecapRow(Icons.local_hospital_outlined, speciality),
        _RecapRow(
          type == 'PHYSICAL' ? Icons.place_outlined : Icons.videocam_outlined,
          type == 'PHYSICAL' ? 'Consultation physique' : 'En ligne (vidéo)'),
      ]));
  }
}

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RecapRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13,
          color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
    ]));
}
