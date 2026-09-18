import 'package:clinic_app/models/consultation.dart';
import 'package:clinic_app/services/consultation_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsultationService', () {
    test(
      'patient history includes consultations recorded by another doctor',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ConsultationService(firestore: firestore);
        await firestore
            .collection('consultations')
            .doc('consultation-1')
            .set(_consultation(doctorId: 'doctor-a').toMap());
        await firestore
            .collection('consultations')
            .doc('other-patient-consultation')
            .set(_consultation(patientId: 'patient-2').toMap());

        final history = await service
            .getPatientConsultations('patient-1')
            .first;

        expect(history, hasLength(1));
        expect(history.single.id, 'consultation-1');
        expect(history.single.doctorId, 'doctor-a');
      },
    );

    test(
      'update changes clinical data without changing recording doctor',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ConsultationService(firestore: firestore);
        final document = firestore
            .collection('consultations')
            .doc('consultation-1');
        await document.set(
          _consultation(
            doctorId: 'doctor-a',
            doctorEmail: 'doctor-a@example.com',
            doctorName: 'Doctor A',
          ).toMap(),
        );

        await service.updateConsultation(
          _consultation(
            doctorId: 'doctor-b',
            doctorEmail: 'doctor-b@example.com',
            doctorName: 'Doctor B',
            diagnosis: 'Updated diagnosis',
          ),
        );

        final stored = (await document.get()).data()!;
        expect(stored['diagnosis'], 'Updated diagnosis');
        expect(stored['doctorId'], 'doctor-a');
        expect(stored['doctorEmail'], 'doctor-a@example.com');
        expect(stored['doctorName'], 'Doctor A');
      },
    );

    test('patient history is ordered newest first', () async {
      final firestore = FakeFirebaseFirestore();
      final service = ConsultationService(firestore: firestore);
      await firestore
          .collection('consultations')
          .doc('older')
          .set(
            _consultation(
              id: 'older',
              createdAt: DateTime.utc(2026, 9, 14),
            ).toMap(),
          );
      await firestore
          .collection('consultations')
          .doc('newer')
          .set(
            _consultation(
              id: 'newer',
              createdAt: DateTime.utc(2026, 9, 16),
            ).toMap(),
          );

      final history = await service.getPatientConsultations('patient-1').first;

      expect(history.map((consultation) => consultation.id), [
        'newer',
        'older',
      ]);
    });

    test('patient history rejects a blank patient id', () {
      final service = ConsultationService(firestore: FakeFirebaseFirestore());

      expect(() => service.getPatientConsultations('   '), throwsArgumentError);
    });

    test('update rejects a blank consultation id', () async {
      final service = ConsultationService(firestore: FakeFirebaseFirestore());

      await expectLater(
        service.updateConsultation(_consultation(id: '   ')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('save still creates a consultation with its complete map', () async {
      final firestore = FakeFirebaseFirestore();
      final service = ConsultationService(firestore: firestore);

      await service.saveConsultation(_consultation());

      final snapshot = await firestore.collection('consultations').get();
      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.data(), _consultation().toMap());
    });

    test('delete still removes the identified consultation', () async {
      final firestore = FakeFirebaseFirestore();
      final service = ConsultationService(firestore: firestore);
      final document = firestore.collection('consultations').doc('to-delete');
      await document.set(_consultation(id: 'to-delete').toMap());

      await service.deleteConsultation('to-delete');

      expect((await document.get()).exists, isFalse);
    });

    test('delete rejects a blank consultation id', () async {
      final service = ConsultationService(firestore: FakeFirebaseFirestore());

      await expectLater(service.deleteConsultation('   '), throwsArgumentError);
    });
  });
}

Consultation _consultation({
  String id = 'consultation-1',
  String patientId = 'patient-1',
  String doctorId = 'doctor-a',
  String doctorEmail = 'doctor-a@example.com',
  String doctorName = 'Doctor A',
  String diagnosis = 'Original diagnosis',
  DateTime? createdAt,
}) {
  return Consultation(
    id: id,
    patientId: patientId,
    doctorId: doctorId,
    doctorEmail: doctorEmail,
    doctorName: doctorName,
    chiefComplaint: 'Headache',
    temperature: '36.8',
    pulseRate: '72',
    respiratoryRate: '16',
    bloodPressure: '120/80',
    oxygenSaturation: '98',
    weight: '70',
    height: '170',
    bmi: 24.2,
    investigations: 'None',
    diagnosis: diagnosis,
    treatment: 'Rest',
    labFeedback: '',
    remarks: '',
    createdAt: createdAt ?? DateTime.utc(2026, 9, 15, 10, 30),
  );
}
