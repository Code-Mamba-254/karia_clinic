import 'dart:async';

import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/screens/patient_registration_screen.dart';
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

  testWidgets('shows a date of birth calendar field instead of numeric age', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PatientRegistrationScreen()),
    );

    final dateOfBirthField = find.text('Date of Birth');

    expect(dateOfBirthField, findsOneWidget);
    expect(find.text('Age'), findsNothing);

    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('shows the selected age and opens saved patient details', (
    tester,
  ) async {
    final asOf = DateTime(2026, 9, 15);
    Patient? submittedPatient;
    Patient? detailsPatient;
    var registrationControllers = <TextEditingController>[];
    var fieldsClearedBeforeNavigation = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegistrationScreen(
          now: () => asOf,
          pickDateOfBirth: (_, _) async => DateTime(2026, 3, 15),
          generateClinicNumber: () async => 'CLN-2026-000001',
          savePatient: (patient) async {
            submittedPatient = patient;
            return Patient(
              id: 'saved-patient-id',
              clinicNumber: patient.clinicNumber,
              name: patient.name,
              ageInYears: patient.ageInYears,
              dateOfBirth: patient.dateOfBirth,
              sex: patient.sex,
              residence: patient.residence,
              idNumber: patient.idNumber,
              phoneNumber: patient.phoneNumber,
              createdAt: patient.createdAt,
            );
          },
          patientDetailsBuilder: (_, patient) {
            detailsPatient = patient;
            fieldsClearedBeforeNavigation = registrationControllers.every(
              (controller) => controller.text.isEmpty,
            );
            return const Scaffold(body: Text('Patient details'));
          },
        ),
      ),
    );

    registrationControllers = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller!)
        .toList(growable: false);

    await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();

    final dateOfBirthInput = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(dateOfBirthInput.controller?.text, '03/15/2026');
    expect(find.text('Age: 6 months'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'Nairobi');
    await tester.ensureVisible(find.text('SAVE PATIENT'));
    await tester.pump();
    await tester.tap(find.text('SAVE PATIENT'));
    await tester.pumpAndSettle();

    expect(submittedPatient?.dateOfBirth, DateTime(2026, 3, 15));
    expect(detailsPatient?.id, 'saved-patient-id');
    expect(fieldsClearedBeforeNavigation, isTrue);
    expect(find.text('Patient details'), findsOneWidget);
  });

  testWidgets('requires a patient name before saving', (tester) async {
    var didSave = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegistrationScreen(
          now: () => DateTime(2026, 9, 15),
          pickDateOfBirth: (_, _) async => DateTime(2020, 9, 15),
          generateClinicNumber: () async => 'CLN-2026-000001',
          savePatient: (patient) async {
            didSave = true;
            return patient.copyWith(id: 'saved-patient-id');
          },
          patientDetailsBuilder: (_, _) =>
              const Scaffold(body: Text('Patient details')),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'Nairobi');
    await tester.ensureVisible(find.text('SAVE PATIENT'));
    await tester.pump();
    await tester.tap(find.text('SAVE PATIENT'));
    await tester.pump();

    expect(find.text('Enter patient name'), findsOneWidget);
    expect(didSave, isFalse);
  });

  testWidgets(
    'saves the validated form snapshot when clinic number is delayed',
    (tester) async {
      final clinicNumber = Completer<String>();
      Patient? submittedPatient;

      await tester.pumpWidget(
        MaterialApp(
          home: PatientRegistrationScreen(
            now: () => DateTime(2026, 9, 15),
            pickDateOfBirth: (_, _) async => DateTime(2000, 1, 1),
            generateClinicNumber: () => clinicNumber.future,
            savePatient: (patient) async {
              submittedPatient = patient;
              return patient.copyWith(id: 'saved-patient-id');
            },
            patientDetailsBuilder: (_, _) =>
                const Scaffold(body: Text('Patient details')),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Original Name');
      await tester.tap(find.byType(TextFormField).at(1));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'Nairobi');
      await tester.ensureVisible(find.text('SAVE PATIENT'));
      await tester.pump();
      await tester.tap(find.text('SAVE PATIENT'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'Changed Name');
      clinicNumber.complete('CLN-2026-000001');
      await tester.pumpAndSettle();

      expect(submittedPatient?.name, 'Original Name');
    },
  );

  testWidgets('keeps form values and hides backend details when saving fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegistrationScreen(
          now: () => DateTime(2026, 9, 15),
          pickDateOfBirth: (_, _) async => DateTime(2000, 1, 1),
          generateClinicNumber: () async => 'CLN-2026-000001',
          savePatient: (_) async => throw StateError('secret backend details'),
          patientDetailsBuilder: (_, _) =>
              const Scaffold(body: Text('Patient details')),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'Nairobi');
    await tester.ensureVisible(find.text('SAVE PATIENT'));
    await tester.pump();
    await tester.tap(find.text('SAVE PATIENT'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to register patient. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret backend details'), findsNothing);
    expect(find.text('Patient details'), findsNothing);
    expect(find.text('Jane Doe'), findsOneWidget);
  });
}
