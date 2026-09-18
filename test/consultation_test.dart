import 'package:clinic_app/models/consultation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Consultation buildConsultation({
    String doctorName = 'Dr Original Author',
    String doctorEmail = 'original@example.com',
  }) {
    return Consultation(
      id: 'consultation-1',
      patientId: 'patient-1',
      doctorId: 'doctor-1',
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
      diagnosis: 'Migraine',
      treatment: 'Rest',
      labFeedback: '',
      remarks: '',
      createdAt: DateTime(2026, 9, 15, 10, 30),
    );
  }

  test('serializes the recording doctor name', () {
    final map = buildConsultation().toMap();

    expect(map['doctorName'], 'Dr Original Author');
  });

  test('update map includes diagnosis but excludes immutable metadata', () {
    final map = buildConsultation().toUpdateMap();

    expect(map['diagnosis'], 'Migraine');
    expect(
      map.keys,
      unorderedEquals(<String>[
        'chiefComplaint',
        'temperature',
        'pulseRate',
        'respiratoryRate',
        'bloodPressure',
        'oxygenSaturation',
        'weight',
        'height',
        'bmi',
        'investigations',
        'diagnosis',
        'treatment',
        'labFeedback',
        'remarks',
      ]),
    );
  });

  test('uses a trimmed doctor name as the recording label', () {
    final consultation = buildConsultation(doctorName: '  Dr Jane Doe  ');

    expect(consultation.recordingDoctorLabel, 'Dr Jane Doe');
  });

  test('reads legacy records without a doctor name', () {
    final consultation = Consultation.fromMap('legacy-consultation', {
      'patientId': 'patient-1',
      'doctorId': 'doctor-1',
      'doctorEmail': 'legacy@example.com',
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
    });

    expect(consultation.doctorName, isEmpty);
    expect(consultation.recordingDoctorLabel, 'legacy@example.com');
  });

  test('falls back to the recording doctor email when name is blank', () {
    final consultation = buildConsultation(
      doctorName: '   ',
      doctorEmail: '  original@example.com  ',
    );

    expect(consultation.recordingDoctorLabel, 'original@example.com');
  });

  test('falls back to Unknown doctor when author details are blank', () {
    final consultation = buildConsultation(
      doctorName: '   ',
      doctorEmail: '   ',
    );

    expect(consultation.recordingDoctorLabel, 'Unknown doctor');
  });
}
