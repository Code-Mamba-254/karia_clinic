import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorEmail;
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

  factory Consultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Consultation(
  id: doc.id,
  patientId: data['patientId'] ?? '',
  doctorId: data['doctorId'] ?? '',
  doctorEmail: data['doctorEmail'] ?? '',

  chiefComplaint: data['chiefComplaint'] ?? '',

  temperature: data['temperature'] ?? '',
  pulseRate: data['pulseRate'] ?? '',
  respiratoryRate: data['respiratoryRate'] ?? '',
  bloodPressure: data['bloodPressure'] ?? '',
  oxygenSaturation: data['oxygenSaturation'] ?? '',
  weight: data['weight'] ?? '',
  height: data['height'] ?? '',
  bmi: (data['bmi'] ?? 0).toDouble(),

  investigations: data['investigations'] ?? '',
  diagnosis: data['diagnosis'] ?? '',
  treatment: data['treatment'] ?? '',
  labFeedback: data['labFeedback'] ?? '',
  remarks: data['remarks'] ?? '',

  createdAt: (data['createdAt'] as Timestamp).toDate(),
);
  }

Map<String, dynamic> toMap() {
  return {
    'patientId': patientId,
    'doctorId': doctorId,
    'doctorEmail': doctorEmail,

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

    'createdAt': Timestamp.fromDate(createdAt),
  };
}
}