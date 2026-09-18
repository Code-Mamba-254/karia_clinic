import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorEmail;
  final String doctorName;
  final String chiefComplaint;

  /// VITALS
  final String temperature;
  final String pulseRate;
  final String respiratoryRate;
  final String bloodPressure;
  final String oxygenSaturation;
  final String weight;
  final String height;
  final double bmi;

  /// CONSULTATION
  final String investigations;
  final String diagnosis;
  final String treatment;
  final String labFeedback;
  final String remarks;

  final DateTime createdAt;

  Consultation({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorEmail,
    this.doctorName = '',
    required this.chiefComplaint,
    required this.temperature,
    required this.pulseRate,
    required this.respiratoryRate,
    required this.bloodPressure,
    required this.oxygenSaturation,
    required this.weight,
    required this.height,
    required this.bmi,

    required this.investigations,
    required this.diagnosis,
    required this.treatment,
    required this.labFeedback,
    required this.remarks,
    required this.createdAt,
  });

  factory Consultation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Consultation ${doc.id} has no data');
    }
    return Consultation.fromMap(doc.id, data);
  }

  factory Consultation.fromMap(String id, Map<String, dynamic> data) {
    return Consultation(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorEmail: data['doctorEmail'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      chiefComplaint: data['chiefComplaint'] as String? ?? '',
      temperature: data['temperature'] as String? ?? '',
      pulseRate: data['pulseRate'] as String? ?? '',
      respiratoryRate: data['respiratoryRate'] as String? ?? '',
      bloodPressure: data['bloodPressure'] as String? ?? '',
      oxygenSaturation: data['oxygenSaturation'] as String? ?? '',
      weight: data['weight'] as String? ?? '',
      height: data['height'] as String? ?? '',
      bmi: (data['bmi'] as num? ?? 0).toDouble(),
      investigations: data['investigations'] as String? ?? '',
      diagnosis: data['diagnosis'] as String? ?? '',
      treatment: data['treatment'] as String? ?? '',
      labFeedback: data['labFeedback'] as String? ?? '',
      remarks: data['remarks'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  String get recordingDoctorLabel {
    if (doctorName.trim().isNotEmpty) return doctorName.trim();
    if (doctorEmail.trim().isNotEmpty) return doctorEmail.trim();
    return 'Unknown doctor';
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorEmail': doctorEmail,
      'doctorName': doctorName,
      ...toUpdateMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'chiefComplaint': chiefComplaint,
      'temperature': temperature,
      'pulseRate': pulseRate,
      'respiratoryRate': respiratoryRate,
      'bloodPressure': bloodPressure,
      'oxygenSaturation': oxygenSaturation,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'investigations': investigations,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'labFeedback': labFeedback,
      'remarks': remarks,
    };
  }
}
