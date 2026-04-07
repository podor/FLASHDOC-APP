// lib/core/providers/doctor_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

// ── Modèle demande de consultation ───────────────────────────────
class ConsultationRequest {
  final String id;
  final String? speciality;
  final String mode;
  final String? symptomsText;
  final double amount;
  final DateTime receivedAt;
  // ✅ Infos patient (pour l'écran "Patient connecté")
  final String? patientFirstName;
  final String? patientLastName;

  const ConsultationRequest({
    required this.id,
    this.speciality,
    required this.mode,
    this.symptomsText,
    required this.amount,
    required this.receivedAt,
    this.patientFirstName,
    this.patientLastName,
  });

  String get modeLabel {
    switch (mode) {
      case 'CHAT':  return 'Chat';
      case 'AUDIO': return 'Audio';
      case 'VIDEO': return 'Vidéo';
      default:      return mode;
    }
  }

  factory ConsultationRequest.fromSocket(Map<String, dynamic> data) {
    return ConsultationRequest(
      id:           data['id']          as String,
      speciality:   data['speciality']  as String?,
      mode:         data['mode']        as String? ?? 'VIDEO',
      symptomsText: data['symptomsText']as String?,
      amount:       (data['amount'] as num?)?.toDouble() ?? 0,
      receivedAt:   DateTime.now(),
      patientFirstName: data['patientFirstName'] as String?,
      patientLastName:  data['patientLastName']  as String?,
    );
  }
}

// ── State ─────────────────────────────────────────────────────────
class DoctorState {
  final bool isAvailable;
  final List<ConsultationRequest> requests;
  final bool isLoading;
  final String? error;
  final String? activeConsultationId;
  // ✅ Stocker la demande acceptée pour afficher les infos patient
  final ConsultationRequest? activeRequest;

  const DoctorState({
    this.isAvailable = false,
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.activeConsultationId,
    this.activeRequest,
  });

  DoctorState copyWith({
    bool? isAvailable,
    List<ConsultationRequest>? requests,
    bool? isLoading,
    String? error,
    String? activeConsultationId,
    ConsultationRequest? activeRequest,
    bool clearActive = false,
  }) {
    return DoctorState(
      isAvailable:          isAvailable ?? this.isAvailable,
      requests:             requests    ?? this.requests,
      isLoading:            isLoading   ?? this.isLoading,
      error:                error,
      activeConsultationId: clearActive ? null : (activeConsultationId ?? this.activeConsultationId),
      activeRequest:        clearActive ? null : (activeRequest ?? this.activeRequest),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────
class DoctorNotifier extends StateNotifier<DoctorState> {
  final SocketService _socket = SocketService();

  DoctorNotifier() : super(const DoctorState()) {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socket.onNewConsultationRequest = (data) {
      final request = ConsultationRequest.fromSocket(data);
      state = state.copyWith(
        requests: [request, ...state.requests],
      );
    };

    _socket.onConsultationRequestTaken = (data) {
      final id = data['consultationId'] as String?;
      if (id == null) return;
      state = state.copyWith(
        requests: state.requests.where((r) => r.id != id).toList(),
      );
    };

    // ✅ Confirmation d'acceptation — stocker aussi la demande
    _socket.onConsultationAcceptedConfirmed = (data) {
      final id = data['consultationId'] as String?;
      if (id == null) return;
      // Trouver la demande acceptée dans la liste
      final accepted = state.requests
          .where((r) => r.id == id)
          .firstOrNull;
      state = state.copyWith(
        activeConsultationId: id,
        activeRequest: accepted,
        requests: state.requests.where((r) => r.id != id).toList(),
      );
    };
  }

  Future<void> setAvailable(bool available) async {
    state = state.copyWith(isAvailable: available);
    if (available) {
      _socket.emitDoctorAvailable();
    } else {
      _socket.emitDoctorUnavailable();
    }
  }

  Future<bool> acceptConsultation(String consultationId) async {
    state = state.copyWith(isLoading: true);
    try {
      _socket.acceptConsultation(consultationId);
      state = state.copyWith(
        requests: state.requests.where((r) => r.id != consultationId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void removeExpiredRequest(String consultationId) {
    state = state.copyWith(
      requests: state.requests.where((r) => r.id != consultationId).toList(),
    );
  }

  Future<bool> endConsultation(String consultationId, {String? notes}) async {
    try {
      await ApiService().endConsultation(consultationId, notes: notes);
      state = state.copyWith(clearActive: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _socket.onNewConsultationRequest        = null;
    _socket.onConsultationRequestTaken      = null;
    _socket.onConsultationAcceptedConfirmed = null;
    super.dispose();
  }
}

final doctorProvider =
    StateNotifierProvider<DoctorNotifier, DoctorState>((ref) => DoctorNotifier());
