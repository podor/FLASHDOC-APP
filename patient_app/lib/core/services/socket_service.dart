// lib/core/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  String? _activeConsultationId;

  // ── Callbacks PATIENT ─────────────────────────────────────────
  Function(Map<String, dynamic>)? onConsultationMatched;
  Function(Map<String, dynamic>)? onConsultationExpired;
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onWebRtcSignal;
  // ✅ Nouveau : déclenché quand l'un des deux appuie sur "Démarrer"
  Function(Map<String, dynamic>)? onConsultationStarted;

  // ── Callbacks DOCTOR ──────────────────────────────────────────
  Function(Map<String, dynamic>)? onNewConsultationRequest;
  Function(Map<String, dynamic>)? onConsultationRequestTaken;
  Function(Map<String, dynamic>)? onConsultationAcceptedConfirmed;
  Function(Map<String, dynamic>)? onConsultationAlreadyTaken;
  Function(Map<String, dynamic>)? onDoctorStatus;

  Future<void> connect() async {
    if (isConnected) return;

    final token = await StorageService().getAccessToken();
    if (token == null) return;

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .setTimeout(10000)
          .build(),
    );

    _socket!.connect();
    _setupListeners();
  }

  void _setupListeners() {
    _socket!
      ..on('connect', (_) {
        print('🔌 Socket connecté : ${_socket!.id}');
        if (_activeConsultationId != null) {
          print('🔄 Rejoin room consultation : $_activeConsultationId');
          _socket!.emit('consultation:join',
              {'consultationId': _activeConsultationId});
        }
      })
      ..on('disconnect', (reason) {
        print('🔴 Socket déconnecté : $reason');
      })
      ..on('connect_error', (e) {
        print('❌ Socket erreur : $e');
      })

      // ── Événements PATIENT ──────────────────────────────────────
      ..on('consultation:matched', (data) {
        onConsultationMatched?.call(_toMap(data));
      })
      ..on('consultation:expired', (data) {
        onConsultationExpired?.call(_toMap(data));
      })
      ..on('message:new', (data) {
        onNewMessage?.call(_toMap(data));
      })
      ..on('webrtc:signal', (data) {
        onWebRtcSignal?.call(_toMap(data));
      })
      // ✅ Événement reçu par LES DEUX quand l'un appuie sur "Démarrer"
      ..on('consultation:started', (data) {
        print('🚀 consultation:started reçu');
        onConsultationStarted?.call(_toMap(data));
      })

      // ── Événements DOCTOR ───────────────────────────────────────
      ..on('consultation:new_request', (data) {
        print('🔔 Nouvelle demande');
        onNewConsultationRequest?.call(_toMap(data));
      })
      ..on('consultation:request_taken', (data) {
        onConsultationRequestTaken?.call(_toMap(data));
      })
      ..on('consultation:accepted_confirmed', (data) {
        print('✅ Acceptation confirmée');
        onConsultationAcceptedConfirmed?.call(_toMap(data));
      })
      ..on('consultation:already_taken', (data) {
        onConsultationAlreadyTaken?.call(_toMap(data));
      })
      ..on('doctor:status', (data) {
        onDoctorStatus?.call(_toMap(data));
      });
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  void joinConsultation(String consultationId) {
    _activeConsultationId = consultationId;
    _socket?.emit('consultation:join', {'consultationId': consultationId});
    print('📡 Joined room consultation:$consultationId');
  }

  void leaveConsultation() {
    if (_activeConsultationId != null) {
      _socket?.emit('consultation:leave',
          {'consultationId': _activeConsultationId});
    }
    _activeConsultationId = null;
  }

  // ✅ Émettre "Démarrer la consultation" — déclenche la navigation des deux
  void emitConsultationStart(String consultationId) {
    _socket?.emit('consultation:start', {'consultationId': consultationId});
    print('▶️ Émis consultation:start pour $consultationId');
  }

  void sendMessage(String consultationId, String content) {
    if (_activeConsultationId != consultationId) {
      joinConsultation(consultationId);
    }
    _socket?.emit('message:send', {
      'consultationId': consultationId,
      'content': content,
    });
  }

  void sendWebRtcSignal(String consultationId, dynamic signal) {
    _socket?.emit('webrtc:signal', {
      'consultationId': consultationId,
      'signal': signal,
    });
  }

  void emitDoctorAvailable() {
    _socket?.emit('doctor:available');
  }

  void emitDoctorUnavailable() {
    _socket?.emit('doctor:unavailable');
  }

  void acceptConsultation(String consultationId) {
    _socket?.emit('consultation:accept', {'consultationId': consultationId});
  }

  Future<void> reconnect() async {
    if (isConnected) return;
    final token = await StorageService().getAccessToken();
    if (token == null) return;
    _socket?.auth = {'token': token};
    _socket?.connect();
  }

  void disconnect() {
    _activeConsultationId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void clearAllCallbacks() {
    onConsultationMatched           = null;
    onConsultationExpired           = null;
    onNewMessage                    = null;
    onWebRtcSignal                  = null;
    onConsultationStarted           = null;
    onNewConsultationRequest        = null;
    onConsultationRequestTaken      = null;
    onConsultationAcceptedConfirmed = null;
    onConsultationAlreadyTaken      = null;
    onDoctorStatus                  = null;
  }
}
