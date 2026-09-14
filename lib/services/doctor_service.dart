import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor.dart';

class DoctorService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Get all active doctors
Future<List<Doctor>> getDoctors() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('doctors')
      .get();

  print("Doctors found: ${snapshot.docs.length}");

  for (final doc in snapshot.docs) {
    print("Document ID: ${doc.id}");
    print(doc.data());
  }

  return snapshot.docs
      .map((doc) => Doctor.fromFirestore(
            doc.id,
            doc.data(),
          ))
      .toList();
}

  /// Get doctor's email using document id
  Future<String?> getDoctorEmail(String doctorId) async {
    final doc = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data()?['email'];
  }

  /// Get one doctor
  Future<Doctor?> getDoctor(String doctorId) async {
    final doc = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return Doctor.fromFirestore(
      doc.id,
      doc.data()!,
    );
  }
}