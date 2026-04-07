// lib/features/consultation/screens/consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/consultation_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  final String consultationId;
  const ConsultationScreen({super.key, required this.consultationId});

  @override
  ConsumerState<ConsultationScreen> createState() =>
      _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen>
    with WidgetsBindingObserver {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  ConsultationModel? _consultation;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String _mode = 'CHAT';
  // IDs des messages déjà affichés (depuis l'API au chargement)
  final Set<String> _loadedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _joinRoom();

    // ✅ On reçoit uniquement les messages des AUTRES (backend utilise socket.to())
    // Donc plus de doublons — on ajoute directement
    SocketService().onNewMessage = (msg) {
      if (!mounted) return;
      final msgId = msg['id'] as String? ?? '';
      // Vérifier que ce n'est pas un message déjà chargé depuis l'API
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

  void _joinRoom() {
    SocketService().joinConsultation(widget.consultationId);
  }

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
        // Mémoriser les IDs des messages chargés depuis l'API
        for (final m in msgs) {
          final id = m['id'] as String? ?? '';
          if (id.isNotEmpty) _loadedIds.add(id);
        }
        setState(() {
          _consultation = c;
          _messages = msgs;
          _mode = c.mode;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
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

    // ✅ Ajouter localement avec un ID temporaire
    // Le backend NE renvoie PAS le message à l'expéditeur → pas de doublon
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _loadedIds.add(tempId); // Bloquer si jamais on reçoit un echo

    setState(() => _messages.add({
      'id':        tempId,
      'sender':    'PATIENT',
      'content':   text,
      'createdAt': DateTime.now().toIso8601String(),
    }));

    SocketService().sendMessage(widget.consultationId, text);
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _endConsultation() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Terminer la consultation ?'),
      content: const Text('La consultation sera marquée comme terminée.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            SocketService().leaveConsultation();
            context.go('/patient/consult/rating',
                extra: {'consultationId': widget.consultationId});
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Terminer')),
      ],
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    SocketService().onNewMessage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(
          color: AppColors.primary)));
    }
    final doctor = _consultation?.doctor;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: _endConsultation),
        title: doctor != null
            ? Row(children: [
                CircleAvatar(radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    doctor.firstName.isNotEmpty ? doctor.firstName[0] : 'D',
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.primary))),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doctor.fullName, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text(doctor.speciality, style: const TextStyle(fontSize: 12,
                      color: AppColors.textSecondary)),
                ])),
              ])
            : const Text('Consultation',
                style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(_modeIcon, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text(_modeLabel, style: const TextStyle(fontSize: 11,
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
            ])),
          IconButton(icon: const Icon(Icons.call_end_rounded, color: AppColors.error),
              onPressed: _endConsultation),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 48,
                        color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('La consultation a débuté.',
                        style: TextStyle(fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(doctor != null
                        ? 'Dr. ${doctor.firstName} est disponible'
                        : 'Médecin connecté',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(message: _messages[i])),
        ),

        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(
                icon: const Icon(Icons.attach_file_outlined,
                    color: AppColors.textSecondary),
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
                    style: const TextStyle(fontSize: 14,
                        color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20))),
            ]),
          ),
        ),
      ]),
    );
  }

  IconData get _modeIcon {
    switch (_mode) {
      case 'AUDIO': return Icons.mic_rounded;
      case 'VIDEO': return Icons.videocam_rounded;
      default: return Icons.chat_bubble_rounded;
    }
  }
  String get _modeLabel {
    switch (_mode) {
      case 'AUDIO': return 'Audio';
      case 'VIDEO': return 'Vidéo';
      default: return 'Chat';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isPatient = message['sender'] == 'PATIENT';
    final isSystem  = message['sender'] == 'SYSTEM';
    final content   = message['content'] as String? ?? '';

    if (isSystem) {
      return Center(child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: AppColors.border,
            borderRadius: BorderRadius.circular(12)),
        child: Text(content, style: const TextStyle(fontSize: 12,
            color: AppColors.textSecondary))));
    }

    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPatient ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isPatient ? 16 : 4),
            bottomRight: Radius.circular(isPatient ? 4 : 16),
          ),
          border: isPatient ? null : Border.all(color: AppColors.border),
        ),
        child: Text(content, style: TextStyle(fontSize: 14,
            color: isPatient ? Colors.white : AppColors.textPrimary,
            height: 1.4)),
      ),
    );
  }
}
