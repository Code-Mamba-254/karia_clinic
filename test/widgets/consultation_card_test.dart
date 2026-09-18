import 'package:clinic_app/models/consultation.dart';
import 'package:clinic_app/widgets/consultation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the original recording author independent of viewer', (
    tester,
  ) async {
    final consultation = Consultation(
      id: 'consultation-1',
      patientId: 'patient-1',
      doctorId: 'original-doctor-id',
      doctorEmail: 'original@example.com',
      doctorName: 'Dr Original Author',
      chiefComplaint: 'Headache',
      temperature: '',
      pulseRate: '',
      respiratoryRate: '',
      bloodPressure: '',
      oxygenSaturation: '',
      weight: '',
      height: '',
      bmi: 0,
      investigations: '',
      diagnosis: '',
      treatment: '',
      labFeedback: '',
      remarks: '',
      createdAt: DateTime(2026, 9, 15, 10, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Signed in as Dr Current Viewer'),
                ConsultationCard(consultation: consultation),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Signed in as Dr Current Viewer'), findsOneWidget);
    expect(find.text('Recorded by Dr Original Author'), findsOneWidget);
    expect(find.text('Recorded by Dr Current Viewer'), findsNothing);
  });
}
