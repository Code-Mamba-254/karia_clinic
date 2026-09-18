import 'package:clinic_app/models/consultation.dart';
import 'package:clinic_app/screens/edit_consultation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Consultation originalConsultation() => Consultation(
  id: 'consultation-1',
  patientId: 'patient-1',
  doctorId: 'doctor-a',
  doctorEmail: 'doctor-a@example.com',
  doctorName: 'Doctor A',
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
  diagnosis: 'Original diagnosis',
  treatment: 'Rest',
  labFeedback: '',
  remarks: '',
  createdAt: DateTime(2026, 9, 16, 10),
);

void main() {
  testWidgets('cross-doctor edit preserves original attribution', (
    tester,
  ) async {
    Consultation? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: EditConsultationScreen(
          consultation: originalConsultation(),
          updateConsultation: (value) async => submitted = value,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Diagnosis'),
      'Updated by Doctor B',
    );
    await tester.ensureVisible(find.text('Update Consultation'));
    await tester.tap(find.text('Update Consultation'));
    await tester.pumpAndSettle();

    expect(submitted?.doctorId, 'doctor-a');
    expect(submitted?.doctorEmail, 'doctor-a@example.com');
    expect(submitted?.doctorName, 'Doctor A');
    expect(submitted?.diagnosis, 'Updated by Doctor B');
  });

  testWidgets('failed update retains text and shows a safe error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditConsultationScreen(
          consultation: originalConsultation(),
          updateConsultation: (_) async => throw StateError('private details'),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Diagnosis'),
      'Edited diagnosis',
    );
    await tester.ensureVisible(find.text('Update Consultation'));
    await tester.tap(find.text('Update Consultation'));
    await tester.pumpAndSettle();

    expect(find.text('Edited diagnosis'), findsOneWidget);
    expect(
      find.text('Unable to update consultation. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private details'), findsNothing);
  });
}
