import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import '../utils/patient_search_index.dart';

class PatientService {
  static const _searchResultLimit = 50;

  final FirebaseFirestore _db;

  PatientService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get patients =>
      _db.collection('patients');

  Future<Patient> savePatient(Patient patient) async {
    final document = await patients.add(patient.toMap());
    return patient.copyWith(id: document.id);
  }

  Stream<List<Patient>> searchPatients(String searchText) {
    final normalizedSearch = normalizePatientSearchText(searchText);
    if (normalizedSearch.isEmpty) {
      return Stream.value(const <Patient>[]);
    }

    return patients
        .where('searchPrefixes', arrayContains: normalizedSearch)
        .orderBy('nameLowercase')
        .limit(_searchResultLimit)
        .snapshots()
        .map(
          (snapshot) => List<Patient>.unmodifiable(
            snapshot.docs.map(Patient.fromFirestore),
          ),
        );
  }

  Future<void> updatePatient(Patient patient) async {
    if (patient.id.trim().isEmpty) {
      throw ArgumentError.value(patient.id, 'patient.id', 'ID is required.');
    }
    await patients.doc(patient.id).update(patient.toUpdateMap());
  }
}

bool patientNameMatches(String patientName, String searchText) {
  final normalizedSearch = normalizePatientSearchText(searchText);
  return buildPatientSearchPrefixes(patientName).contains(normalizedSearch);
}
