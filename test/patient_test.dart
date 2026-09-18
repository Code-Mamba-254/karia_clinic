import 'package:clinic_app/enums/sex.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/widgets/patient_summary_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Patient buildPatient({DateTime? dateOfBirth}) {
    return Patient(
      id: 'patient-1',
      clinicNumber: 'KC-001',
      name: 'Test Patient',
      ageInYears: 40,
      dateOfBirth: dateOfBirth,
      sex: Sex.female,
      residence: 'Nairobi',
      createdAt: DateTime(2026, 9, 15),
    );
  }

  test('derives the current age label from date of birth', () {
    final patient = buildPatient(dateOfBirth: DateTime(2026, 3, 15));

    expect(patient.ageLabel(asOf: DateTime(2026, 9, 15)), '6 months');
  });

  test('falls back to legacy age in years when date of birth is absent', () {
    final patient = buildPatient();

    expect(patient.ageLabel(asOf: DateTime(2026, 9, 15)), '40 years');
  });

  test('creates a new patient with the persisted id', () {
    final patient = buildPatient();

    final persistedPatient = patient.copyWith(id: 'saved-patient-id');

    expect(patient.id, 'patient-1');
    expect(persistedPatient.id, 'saved-patient-id');
  });

  test('reads pre-existing Firestore data without date of birth', () {
    final patient = Patient.fromMap('legacy-id', {
      'clinicNumber': 'CLN-2025-000001',
      'name': 'Legacy Patient',
      'ageInYears': 7,
      'sex': 'Male',
      'residence': 'Nakuru',
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
    });

    expect(patient.id, 'legacy-id');
    expect(patient.dateOfBirth, isNull);
    expect(patient.ageLabel(asOf: DateTime(2026, 9, 15)), '7 years');
  });

  test('serializes date of birth as a timezone-neutral calendar date', () {
    final map = buildPatient(dateOfBirth: DateTime(1986, 9, 15)).toMap();

    expect(map['dateOfBirth'], '1986-09-15');
  });

  test(
    'preserves local-midnight timestamp dates from earlier app versions',
    () {
      final patient = Patient.fromMap('timestamp-id', {
        'clinicNumber': 'CLN-2026-000002',
        'name': 'Timestamp Patient',
        'ageInYears': 40,
        'dateOfBirth': Timestamp.fromDate(DateTime(1986, 9, 15)),
        'sex': 'Female',
        'residence': 'Nairobi',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      expect(patient.dateOfBirth, DateTime(1986, 9, 15));
    },
  );

  testWidgets('patient summary safely renders a legacy empty name', (
    tester,
  ) async {
    final patient = Patient(
      id: 'legacy-empty-name',
      clinicNumber: 'CLN-2025-000003',
      name: '',
      ageInYears: 7,
      sex: Sex.male,
      residence: 'Nakuru',
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PatientSummaryCard(patient: patient)),
      ),
    );

    expect(find.text('?'), findsOneWidget);
  });
}
