// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));

    _dio.interceptors.add(PrettyDioLogger(
      requestBody: true, responseBody: true, compact: false,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService().getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['ngrok-skip-browser-warning'] = 'true';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final opts  = error.requestOptions;
            final token = await StorageService().getAccessToken();
            opts.headers['Authorization'] = 'Bearer $token';
            opts.headers['ngrok-skip-browser-warning'] = 'true';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await StorageService().getRefreshToken();
      if (refreshToken == null) return false;
      final res = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'ngrok-skip-browser-warning': 'true'}),
      );
      if (res.data['success'] == true) {
        await StorageService().saveTokens(
          access:  res.data['data']['accessToken'],
          refresh: refreshToken,
        );
        return true;
      }
      return false;
    } catch (_) { return false; }
  }

  // ── AUTH ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'phone': phone, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await _dio.post('/auth/verify-otp',
        data: {'phone': phone, 'code': code});
    return res.data;
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    final res = await _dio.post('/auth/resend-otp', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  // ── CONSULTATIONS PATIENT ─────────────────────────────────────
  Future<Map<String, dynamic>> createConsultation(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/consultations', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getMyConsultations() async {
    final res = await _dio.get('/consultations');
    return res.data;
  }

  Future<Map<String, dynamic>> getConsultation(String id) async {
    final res = await _dio.get('/consultations/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> rateConsultation(
      String id, int score, String? comment) async {
    final res = await _dio.post('/consultations/$id/rate',
        data: {'score': score, 'comment': comment});
    return res.data;
  }

  Future<Map<String, dynamic>> simulatePayment(String consultationId) async {
    final res = await _dio.post('/payments/simulate',
        data: {'consultationId': consultationId});
    return res.data;
  }

  Future<Map<String, dynamic>> initiatePayment(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/payments/initiate', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final res = await _dio.get('/payments/status/$paymentId');
    return res.data;
  }

  // ── CONSULTATIONS DOCTOR ──────────────────────────────────────
  Future<Map<String, dynamic>> startConsultation(String id) async {
    final res = await _dio.post('/consultations/$id/start');
    return res.data;
  }

  Future<Map<String, dynamic>> endConsultation(String id,
      {String? notes}) async {
    final res = await _dio.post('/consultations/$id/end',
        data: {'notes': notes});
    return res.data;
  }

  Future<Map<String, dynamic>> getDoctorConsultations() async {
    final res = await _dio.get('/doctors/me/consultations');
    return res.data;
  }

  Future<Map<String, dynamic>> getDoctorProfile() async {
    final res = await _dio.get('/doctors/me/profile');
    return res.data;
  }

  Future<Map<String, dynamic>> getDoctorWallet() async {
    final res = await _dio.get('/doctors/me/wallet');
    return res.data;
  }

  // ── MÉDECINS ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDoctors({String? speciality}) async {
    final res = await _dio.get('/doctors', queryParameters: {
      if (speciality != null) 'speciality': speciality,
    });
    return res.data;
  }

  // ── PATIENT ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPatientProfile() async {
    final res = await _dio.get('/patients/me');
    return res.data;
  }

  Future<Map<String, dynamic>> updatePatientProfile(
      Map<String, dynamic> data) async {
    final res = await _dio.put('/patients/me', data: data);
    return res.data;
  }

  // ── RENDEZ-VOUS ────────────────────────────────────────────────
  Future<Map<String, dynamic>> createAppointment({
    required String speciality,
    required String scheduledAt,
    required String type,
    required String reason,
  }) async {
    final res = await _dio.post('/appointments', data: {
      'speciality':  speciality,
      'scheduledAt': scheduledAt,
      'type':        type,
      'reason':      reason,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMyAppointments() async {
    final res = await _dio.get('/appointments/me');
    return res.data;
  }

  // ── ORDONNANCES ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPatientPrescriptions() async {
    final res = await _dio.get('/prescriptions/me');
    return res.data;
  }

  Future<Map<String, dynamic>> submitPrescription({
    required String consultationId,
    required String prescriptionId,
    required String hash,
    required String diagnosis,
    required List<Map<String, dynamic>> medications,
    required String instructions,
    required String issuedAt,
  }) async {
    final res = await _dio.post('/prescriptions', data: {
      'consultationId': consultationId,
      'prescriptionId': prescriptionId,
      'hash':           hash,
      'diagnosis':      diagnosis,
      'medications':    medications,
      'instructions':   instructions,
      'issuedAt':       issuedAt,
    });
    return res.data;
  }

  // ── ENRÔLEMENT MÉDECIN ──────────────────────────────────────────
  Future<Map<String, dynamic>> submitDoctorApplication({
    required Map<String, dynamic> dossier,
  }) async {
    final res = await _dio.post('/doctors/apply', data: dossier);
    return res.data;
  }

  Future<Map<String, dynamic>> getDoctorApplicationStatus() async {
    final res = await _dio.get('/doctors/application/status');
    return res.data;
  }

  /// Upload des documents d'affiliation médecin
  /// [files] : map fieldName → chemin local du fichier
  /// Ex: {'diplome': '/path/diplome.jpg', 'onmc': '/path/carte.jpg'}
  Future<Map<String, dynamic>> uploadDoctorDocuments(
      Map<String, String> files) async {
    final formData = FormData();
    for (final entry in files.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final res = await _dio.post('/doctors/me/documents', data: formData);
    return res.data;
  }

  // ── PHOTO PROFIL ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/users/me/avatar', data: formData);
    return res.data;
  }
}
