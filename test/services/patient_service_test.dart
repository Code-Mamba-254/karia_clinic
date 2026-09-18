import 'package:clinic_app/enums/sex.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/services/patient_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatientService.searchPatients', () {
    test('finds a mixed-case surname prefix', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      await service.savePatient(_patient(name: 'Jane Doe'));

      final results = await service.searchPatients('dO').first;

      expect(results.map((patient) => patient.name), <String>['Jane Doe']);
      expect(() => results[0] = results[0], throwsUnsupportedError);
    });

    test('finds a prefix spanning a middle-name phrase', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      await service.savePatient(_patient(name: 'Mary Jane Watson'));

      final results = await service.searchPatients('  JANE   W  ').first;

      expect(results.map((patient) => patient.name), <String>[
        'Mary Jane Watson',
      ]);
    });

    test('does not rewrite a legacy document while searching', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      final legacy = firestore.collection('patients').doc('legacy');
      await legacy.set({
        ..._patient(name: 'Legacy Person').toMap(),
        'nameLowercase': 'stale legacy value',
        'searchPrefixes': null,
      });
      await service.savePatient(_patient(name: 'Indexed Patient'));

      final results = await PatientService(
        firestore: firestore,
      ).searchPatients('legacy').first;

      expect(results, isEmpty);
      final stored = await legacy.get();
      expect(stored.data()?['nameLowercase'], 'stale legacy value');
      expect(stored.data()?['searchPrefixes'], isNull);
    });

    test('returns an empty immutable list for whitespace-only input', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      await service.savePatient(_patient(name: 'Jane Doe'));

      final results = await service.searchPatients(' \t\n ').first;

      expect(results, isEmpty);
      expect(
        () => results.add(_patient(name: 'Other')),
        throwsUnsupportedError,
      );
    });
  });
}

Patient _patient({required String name}) {
  return Patient(
    id: '',
    clinicNumber: 'KARIA-001',
    name: name,
    ageInYears: 30,
    sex: Sex.female,
    residence: 'Nairobi',
    createdAt: DateTime.utc(2026),
  );
}
