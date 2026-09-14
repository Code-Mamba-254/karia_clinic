import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/sex.dart';

class Patient {
  final String id;
  final String clinicNumber;
  final String name;
  final int ageInYears;
  final Sex sex;
  final String residence;
  final String? idNumber;
  final String? phoneNumber;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.clinicNumber,
    required this.name,
    required this.ageInYears,
    required this.sex,
    required this.residence,
    this.idNumber,
    this.phoneNumber,
    required this.createdAt,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Patient(
      id: doc.id,
      clinicNumber: data['clinicNumber'] ?? '',
      name: data['name'] ?? '',
      ageInYears: data['ageInYears'] ?? 0,
      sex: data['sex'] == 'Female' ? Sex.female : Sex.male,
      residence: data['residence'] ?? '',
      idNumber: data['idNumber'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicNumber': clinicNumber,
      'name': name,
      'ageInYears': ageInYears,
      'sex': sex == Sex.male ? 'Male' : 'Female',
      'residence': residence,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}