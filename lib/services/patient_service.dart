import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get patients =>
      _db.collection('patients');

  Future<void> savePatient(Patient patient) async {
    await patients.add(patient.toMap());
  }

Stream<List<Patient>> searchPatients(String searchText) {
  if (searchText.isEmpty) {
    return Stream.value([]);
  }

  return patients
      .orderBy('name')
      .startAt([searchText])
      .endAt(['$searchText\uf8ff'])
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList());
}
}