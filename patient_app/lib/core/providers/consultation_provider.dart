// lib/core/providers/consultation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consultation_model.dart';
import '../services/api_service.dart';

class ConsultationState {
  final List<ConsultationModel> consultations;
  final ConsultationModel? active; // consultation en cours / en attente
  final bool isLoading;
  final String? error;

  const ConsultationState({
    this.consultations = const [],
    this.active,
    this.isLoading = false,
    this.error,
  });

  ConsultationState copyWith({
    List<ConsultationModel>? consultations,
    ConsultationModel? active,
    bool? isLoading,
    String? error,
    bool clearActive = false,
  }) {
    return ConsultationState(
      consultations: consultations ?? this.consultations,
      active:        clearActive ? null : (active ?? this.active),
      isLoading:     isLoading ?? this.isLoading,
      error:         error,
    );
  }
}

class ConsultationNotifier extends StateNotifier<ConsultationState> {
  final ApiService _api = ApiService();

  ConsultationNotifier() : super(const ConsultationState());

  Future<ConsultationModel?> createConsultation({
    required String mode,
    required String speciality,
    String? symptomsText,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.createConsultation({
        'mode': mode,
        'speciality': speciality,
        if (symptomsText != null) 'symptomsText': symptomsText,
      });
      if (res['success'] == true) {
        final consultation = ConsultationModel.fromJson(res['data']['consultation']);
        state = state.copyWith(active: consultation, isLoading: false);
        return consultation;
      }
      state = state.copyWith(error: res['message'], isLoading: false);
      return null;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getMyConsultations();
      if (res['success'] == true) {
        final list = (res['data']['consultations'] as List)
            .map((j) => ConsultationModel.fromJson(j))
            .toList();
        state = state.copyWith(consultations: list, isLoading: false);
      }
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setActive(ConsultationModel consultation) {
    state = state.copyWith(active: consultation);
  }

  void clearActive() {
    state = state.copyWith(clearActive: true);
  }

  Future<bool> rateConsultation(String id, int score, String? comment) async {
    try {
      final res = await _api.rateConsultation(id, score, comment);
      if (res['success'] == true) {
        await loadHistory();
        return true;
      }
      return false;
    } on Exception {
      return false;
    }
  }
}

final consultationProvider =
    StateNotifierProvider<ConsultationNotifier, ConsultationState>((ref) => ConsultationNotifier());
