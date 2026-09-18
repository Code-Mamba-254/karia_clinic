import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/sex.dart';
import '../utils/age_formatter.dart';
import '../utils/patient_search_index.dart';

const _unset = Object();

class Patient {
  final String id;
  final String clinicNumber;
  final String name;
  final int ageInYears;
  final DateTime? dateOfBirth;
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
    this.dateOfBirth,
    required this.sex,
    required this.residence,
    this.idNumber,
    this.phoneNumber,
    required this.createdAt,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient.fromMap(doc.id, data);
  }

  factory Patient.fromMap(String id, Map<String, dynamic> data) {
    return Patient(
      id: id,
      clinicNumber: data['clinicNumber'] as String? ?? '',
      name: data['name'] as String? ?? '',
      ageInYears: data['ageInYears'] as int? ?? 0,
      dateOfBirth: _parseDateOfBirth(data['dateOfBirth']),
      sex: data['sex'] == 'Female' ? Sex.female : Sex.male,
      residence: data['residence'] as String? ?? '',
      idNumber: data['idNumber'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Patient copyWith({
    String? id,
    String? clinicNumber,
    String? name,
    int? ageInYears,
    Object? dateOfBirth = _unset,
    Sex? sex,
    String? residence,
    Object? idNumber = _unset,
    Object? phoneNumber = _unset,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      clinicNumber: clinicNumber ?? this.clinicNumber,
      name: name ?? this.name,
      ageInYears: ageInYears ?? this.ageInYears,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      sex: sex ?? this.sex,
      residence: residence ?? this.residence,
      idNumber: identical(idNumber, _unset)
          ? this.idNumber
          : idNumber as String?,
      phoneNumber: identical(phoneNumber, _unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String ageLabel({DateTime? asOf}) {
    final birthDate = dateOfBirth;
    if (birthDate != null) {
      return formatPatientAge(birthDate, asOf: asOf);
    }

    final unit = ageInYears == 1 ? 'year' : 'years';
    return '$ageInYears $unit';
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'nameLowercase': normalizePatientSearchText(name),
      'searchPrefixes': buildPatientSearchPrefixes(name),
      'ageInYears': ageInYears,
      'dateOfBirth': dateOfBirth == null ? null : _formatDateOnly(dateOfBirth!),
      'sex': sex == Sex.male ? 'Male' : 'Female',
      'residence': residence,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicNumber': clinicNumber,
      'name': name,
      'nameLowercase': normalizePatientSearchText(name),
      'searchPrefixes': buildPatientSearchPrefixes(name),
      'ageInYears': ageInYears,
      if (dateOfBirth != null) 'dateOfBirth': _formatDateOnly(dateOfBirth!),
      'sex': sex == Sex.male ? 'Male' : 'Female',
      'residence': residence,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

DateTime? _parseDateOfBirth(Object? value) {
  if (value is String) {
    final parts = value.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  if (value is Timestamp) {
    final localDate = value.toDate();
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  return null;
}

String _formatDateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
