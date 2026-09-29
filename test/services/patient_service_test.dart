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

  group('PatientService.deletePatient', () {
    Future<void> addConsultation(
      FakeFirebaseFirestore firestore,
      String patientId,
      String doctorId,
    ) {
      return firestore.collection('consultations').add({
        'patientId': patientId,
        'doctorId': doctorId,
        'diagnosis': 'x',
      });
    }

    test('deletes the patient and every consultation for that patient', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      final target = await service.savePatient(_patient(name: 'Jane Doe'));
      final other = await service.savePatient(_patient(name: 'John Roe'));
      await addConsultation(firestore, target.id, 'doctor-a');
      await addConsultation(firestore, target.id, 'doctor-b');
      await addConsultation(firestore, other.id, 'doctor-a');

      final deleted = await service.deletePatient(target.id);

      expect(deleted, 2);
      expect(
        (await firestore.collection('patients').doc(target.id).get()).exists,
        isFalse,
      );
      final remaining = await firestore.collection('consultations').get();
      expect(remaining.docs.map((doc) => doc.data()['patientId']), [other.id]);
      expect(
        (await firestore.collection('patients').doc(other.id).get()).exists,
        isTrue,
      );
    });

    test('deletes a patient that has no consultations', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      final target = await service.savePatient(_patient(name: 'Jane Doe'));

      expect(await service.deletePatient(target.id), 0);
      expect(
        (await firestore.collection('patients').doc(target.id).get()).exists,
        isFalse,
      );
    });

    test('rejects a blank patient id without touching data', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      await service.savePatient(_patient(name: 'Jane Doe'));

      await expectLater(service.deletePatient('  '), throwsArgumentError);
      expect((await firestore.collection('patients').get()).docs, hasLength(1));
    });

    test('refuses and deletes nothing when one batch cannot hold it', () async {
      final firestore = FakeFirebaseFirestore();
      final service = PatientService(firestore: firestore);
      final target = await service.savePatient(_patient(name: 'Jane Doe'));
      for (var i = 0; i < PatientService.maxConsultationsPerDelete + 1; i++) {
        await addConsultation(firestore, target.id, 'doctor-a');
      }

      await expectLater(service.deletePatient(target.id), throwsStateError);

      expect(
        (await firestore.collection('patients').doc(target.id).get()).exists,
        isTrue,
      );
      expect(
        (await firestore.collection('consultations').get()).docs,
        hasLength(PatientService.maxConsultationsPerDelete + 1),
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
