import 'package:clinic_app/enums/sex.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/screens/consultation_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('refreshes displayed biodata after a successful patient edit', (
    tester,
  ) async {
    final original = Patient(
      id: 'patient-1',
      clinicNumber: 'CLN-2026-000001',
      name: 'Original Name',
      ageInYears: 30,
      sex: Sex.female,
      residence: 'Original Residence',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationScreen(
          patient: original,
          consultationStream: (_) => Stream.value([]),
          editPatient: (_, patient) async => patient.copyWith(
            name: 'Updated Name',
            residence: 'Updated Residence',
          ),
        ),
      ),
    );

    expect(find.text('Original Name'), findsOneWidget);
    expect(find.text('Original Residence'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit patient biodata'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Name'), findsOneWidget);
    expect(find.text('Updated Residence'), findsOneWidget);
    expect(find.text('Original Name'), findsNothing);
  });
}
