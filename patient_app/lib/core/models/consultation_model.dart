// lib/core/models/consultation_model.dart

class ConsultationModel {
  final String id;
  final String patientId;
  final String? doctorId;
  final String status;
  final String mode;
  final String type;
  final String? speciality;
  final String? symptomsText;
  final double totalAmount;
  final double? platformFee;
  final double? doctorAmount;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final String? prescriptionUrl;
  final String? notes;
  final DoctorSummary? doctor;
  final PatientSummary? patient;
  final RatingSummary? rating;
  final DateTime createdAt;

  const ConsultationModel({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.status,
    required this.mode,
    required this.type,
    this.speciality,
    this.symptomsText,
    required this.totalAmount,
    this.platformFee,
    this.doctorAmount,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.prescriptionUrl,
    this.notes,
    this.doctor,
    this.patient,
    this.rating,
    required this.createdAt,
  });

  bool get isCompleted   => status == 'COMPLETED';
  bool get isInProgress  => status == 'IN_PROGRESS';
  bool get isWaiting     => status == 'WAITING_DOCTOR';
  bool get isMatched     => status == 'MATCHED';
  bool get isCancelled   => status == 'CANCELLED';
  bool get canRate       => isCompleted && rating == null;

  String get modeLabel {
    switch (mode) {
      case 'CHAT':  return 'Chat texte';
      case 'AUDIO': return 'Appel audio';
      case 'VIDEO': return 'Vidéo';
      default:      return mode;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING_PAYMENT': return 'En attente de paiement';
      case 'WAITING_DOCTOR':  return 'Recherche médecin...';
      case 'MATCHED':         return 'Médecin trouvé';
      case 'IN_PROGRESS':     return 'En cours';
      case 'COMPLETED':       return 'Terminée';
      case 'CANCELLED':       return 'Annulée';
      case 'EXPIRED':         return 'Expirée';
      default:                return status;
    }
  }

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id:              json['id'] as String,
      patientId:       json['patientId'] as String,
      doctorId:        json['doctorId'] as String?,
      status:          json['status'] as String,
      mode:            json['mode'] as String,
      type:            json['type'] as String? ?? 'IMMEDIATE',
      speciality:      json['speciality'] as String?,
      symptomsText:    json['symptomsText'] as String?,
      totalAmount:     (json['totalAmount'] as num).toDouble(),
      platformFee:     json['platformFee'] != null
          ? (json['platformFee'] as num).toDouble() : null,
      doctorAmount:    json['doctorAmount'] != null
          ? (json['doctorAmount'] as num).toDouble() : null,
      startedAt:       json['startedAt'] != null
          ? DateTime.parse(json['startedAt']) : null,
      endedAt:         json['endedAt'] != null
          ? DateTime.parse(json['endedAt']) : null,
      durationMinutes: json['durationMinutes'] as int?,
      prescriptionUrl: json['prescriptionUrl'] as String?,
      notes:           json['notes'] as String?,
      doctor:          json['doctor'] != null
          ? DoctorSummary.fromJson(json['doctor']) : null,
      patient:         json['patient'] != null
          ? PatientSummary.fromJson(json['patient']) : null,
      rating:          json['rating'] != null
          ? RatingSummary.fromJson(json['rating']) : null,
      createdAt:       DateTime.parse(json['createdAt']),
    );
  }
}

class DoctorSummary {
  final String id;
  final String speciality;
  final double averageRating;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const DoctorSummary({
    required this.id,
    required this.speciality,
    required this.averageRating,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => 'Dr. $firstName $lastName';

  factory DoctorSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return DoctorSummary(
      id:            json['id'] as String,
      speciality:    json['speciality'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      firstName:     user['firstName'] as String?
          ?? json['firstName'] as String? ?? '',
      lastName:      user['lastName'] as String?
          ?? json['lastName'] as String? ?? '',
      avatarUrl:     user['avatarUrl'] as String?
          ?? json['avatarUrl'] as String?,
    );
  }
}

class PatientSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const PatientSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PatientSummary(
      id:        json['id'] as String,
      firstName: user['firstName'] as String?
          ?? json['firstName'] as String? ?? '',
      lastName:  user['lastName'] as String?
          ?? json['lastName'] as String? ?? '',
      avatarUrl: user['avatarUrl'] as String?,
    );
  }
}

class RatingSummary {
  final int score;
  final String? comment;

  const RatingSummary({required this.score, this.comment});

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      score:   json['score'] as int,
      comment: json['comment'] as String?,
    );
  }
}
