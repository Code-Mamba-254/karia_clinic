import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/consultation.dart';

class ConsultationService {
  ConsultationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get consultations =>
      _db.collection('consultations');

  Future<void> saveConsultation(Consultation consultation) async {
    await consultations.add(consultation.toMap());
  }

  Stream<List<Consultation>> getPatientConsultations(String patientId) {
    _validateNonBlankId(patientId, 'patientId');

    return consultations
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Consultation.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> updateConsultation(Consultation consultation) async {
    _validateNonBlankId(consultation.id, 'consultation.id');

    await consultations.doc(consultation.id).update(consultation.toUpdateMap());
  }

  Future<void> deleteConsultation(String consultationId) async {
    _validateNonBlankId(consultationId, 'consultationId');

    await consultations.doc(consultationId).delete();
  }

  static void _validateNonBlankId(String id, String name) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, name, 'must not be blank');
    }
  }
}
