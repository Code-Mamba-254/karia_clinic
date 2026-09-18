import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor.dart';

class DoctorService {
  final FirebaseFirestore _firestore;

  DoctorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Doctor>> getDoctors() async {
    final snapshot = await _firestore.collection('doctors').get();
    return snapshot.docs
        .map((doc) => Doctor.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);
  }

  Future<String?> getDoctorEmail(String doctorId) async {
    final doctor = await getDoctor(doctorId);
    return doctor?.email;
  }

  Future<Doctor?> getDoctor(String doctorId) async {
    final doc = await _firestore.collection('doctors').doc(doctorId).get();
    if (!doc.exists) return null;
    return Doctor.fromFirestore(doc.id, doc.data()!);
  }

  Future<Doctor?> findDoctorForAuthUser({
    required String uid,
    required String? email,
  }) async {
    final doctorById = await getDoctor(uid);
    if (doctorById != null) return doctorById;

    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) return null;

    final snapshot = await _firestore
        .collection('doctors')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final document = snapshot.docs.first;
    return Doctor.fromFirestore(document.id, document.data());
  }
}
