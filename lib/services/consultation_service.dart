import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/consultation.dart';

class ConsultationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get consultations =>
      _db.collection('consultations');

  Future<void> saveConsultation(
      Consultation consultation) async {
    await consultations.add(
      consultation.toMap(),
    );
  }

  Stream<List<Consultation>>
      getPatientConsultations(
    String patientId,
  ) {
    return consultations
        .where(
          'patientId',
          isEqualTo: patientId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Consultation.fromFirestore(doc),
              )
              .toList(),
        );
  }

  Future<void> updateConsultation(
      Consultation consultation) async {
    await consultations
        .doc(consultation.id)
        .update(
          consultation.toMap(),
        );
  }

  Future<void> deleteConsultation(
      String consultationId,
  ) async {
    await consultations
        .doc(consultationId)
        .delete();
  }
}