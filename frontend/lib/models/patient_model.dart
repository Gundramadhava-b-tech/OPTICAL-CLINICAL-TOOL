class PatientModel {
  final int id;
  final String patientId;
  final String fullName;
  final int age;
  final String gender;
  final String? contact;
  final String? email;
  final String? medicalHistory;
  final String? eyeCondition;
  final DateTime dateRegistered;
  final int scansCount;

  PatientModel({
    required this.id,
    required this.patientId,
    required this.fullName,
    required this.age,
    required this.gender,
    this.contact,
    this.email,
    this.medicalHistory,
    this.eyeCondition,
    required this.dateRegistered,
    this.scansCount = 0,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      patientId: json['patient_id'] as String,
      fullName: json['full_name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      contact: json['contact'] as String?,
      email: json['email'] as String?,
      medicalHistory: json['medical_history'] as String?,
      eyeCondition: json['eye_condition'] as String?,
      dateRegistered: DateTime.tryParse(json['date_registered'] ?? '') ?? DateTime.now(),
      scansCount: json['scans_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'contact': contact,
      'email': email,
      'medical_history': medicalHistory,
      'eye_condition': eyeCondition,
    };
  }
}
