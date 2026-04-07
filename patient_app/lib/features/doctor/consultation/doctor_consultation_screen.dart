// lib/features/doctor/consultation/doctor_consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/consultation_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/providers/doctor_provider.dart';

class DoctorConsultationScreen extends ConsumerStatefulWidget {
  final String consultationId;
  const DoctorConsultationScreen({super.key, required this.consultationId});

  @override
  ConsumerState<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState
    extends ConsumerState<DoctorConsultationScreen>
    with WidgetsBindingObserver {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _notesCtrl  = TextEditingController();
  ConsultationModel? _consultation;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  final Set<String> _loadedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startConsultation();
    _joinRoom();

    // ✅ Reçoit uniquement les messages des AUTRES (socket.to côté backend)
    SocketService().onNewMessage = (msg) {
      if (!mounted) return;
      final msgId = msg['id'] as String? ?? '';
      if (msgId.isNotEmpty && _loadedIds.contains(msgId)) return;
      if (msgId.isNotEmpty) _loadedIds.add(msgId);
      setState(() => _messages.add(msg));
      _scrollToBottom();
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _rejoinRoom();
  }

  void _joinRoom() => SocketService().joinConsultation(widget.consultationId);

  Future<void> _rejoinRoom() async {
    final socket = SocketService();
    if (!socket.isConnected) {
      await socket.reconnect();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    socket.joinConsultation(widget.consultationId);
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getConsultation(widget.consultationId);
      if (res['success'] == true) {
        final data = res['data']['consultation'] as Map<String, dynamic>;
        final c = ConsultationModel.fromJson(data);
        final msgs = (data['messages'] as List? ?? [])
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        for (final m in msgs) {
          final id = m['id'] as String? ?? '';
          if (id.isNotEmpty) _loadedIds.add(id);
        }
        setState(() {
          _consultation = c;
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startConsultation() async {
    try { await ApiService().startConsultation(widget.consultationId); } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // ✅ Ajouter localement — le backend ne renverra PAS le message à l'expéditeur
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _loadedIds.add(tempId);

    setState(() => _messages.add({
      'id':        tempId,
      'sender':    'DOCTOR',
      'content':   text,
      'createdAt': DateTime.now().toIso8601String(),
    }));

    SocketService().sendMessage(widget.consultationId, text);
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _showEndDialog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Terminer la consultation', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl, maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Notes, recommandations... (optionnel)',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              filled: true, fillColor: AppColors.surfaceGrey,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                SocketService().leaveConsultation();
                final ok = await ref.read(doctorProvider.notifier)
                    .endConsultation(widget.consultationId,
                        notes: _notesCtrl.text.trim().isEmpty
                            ? null : _notesCtrl.text.trim());
                if (ok && mounted) context.go('/doctor/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
              child: const Text('Confirmer la fin',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _notesCtrl.dispose();
    SocketService().onNewMessage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(
          color: AppColors.doctorPrimary)));
    }
    final patient = _consultation?.patient;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.doctorPrimary, foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _showEndDialog),
        title: patient != null
            ? Row(children: [
                CircleAvatar(radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(patient.firstName.isNotEmpty ? patient.firstName[0] : 'P',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(patient.fullName, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  Text(_consultation?.speciality ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                ])),
              ])
            : const Text('Consultation', style: TextStyle(color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_consultation?.modeLabel ?? 'Chat',
              style: const TextStyle(fontSize: 11, color: Colors.white,
                  fontWeight: FontWeight.w600))),
          IconButton(icon: const Icon(Icons.call_end_rounded, color: Colors.white),
              onPressed: _showEndDialog),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('Consultation démarrée', style: TextStyle(fontSize: 16,
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Patient : ${patient?.firstName ?? ''}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                      message: _messages[i], isDoctor: true)),
        ),

        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(
                icon: const Icon(Icons.description_outlined,
                    color: AppColors.doctorPrimary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null, minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Répondre au patient...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: AppColors.doctorPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isDoctor;
  const _MessageBubble({required this.message, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    final sender   = message['sender'] as String? ?? '';
    final content  = message['content'] as String? ?? '';
    final isMe     = isDoctor ? sender == 'DOCTOR' : sender == 'PATIENT';
    final isSystem = sender == 'SYSTEM';

    if (isSystem) {
      return Center(child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: AppColors.border,
            borderRadius: BorderRadius.circular(12)),
        child: Text(content, style: const TextStyle(fontSize: 12,
            color: AppColors.textSecondary))));
    }

    final bgColor   = isMe ? AppColors.doctorPrimary : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Text(content, style: TextStyle(fontSize: 14, color: textColor, height: 1.4)),
      ),
    );
  }
}
