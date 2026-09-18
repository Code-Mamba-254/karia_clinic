import 'package:clinic_app/enums/sex.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/screens/edit_patient_screen.dart';
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

  testWidgets('prepopulates biodata and pops the successful immutable update', (
    tester,
  ) async {
    final createdAt = DateTime(2025, 4, 3, 12, 30);
    final original = Patient(
      id: 'patient-1',
      clinicNumber: 'CLN-2025-000001',
      name: 'Original Name',
      ageInYears: 35,
      dateOfBirth: DateTime(1990, 1, 2),
      sex: Sex.female,
      residence: 'Original Residence',
      idNumber: '12345678',
      phoneNumber: '0700000000',
      createdAt: createdAt,
    );
    Patient? injectedUpdate;
    Patient? poppedPatient;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push<Patient>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPatientScreen(
                      patient: original,
                      now: () => DateTime(2026, 9, 15),
                      updatePatient: (patient) async {
                        injectedUpdate = patient;
                      },
                    ),
                  ),
                ).then((patient) => poppedPatient = patient);
              },
              child: const Text('Edit patient'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit patient'));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList(growable: false);
    expect(fields[0].controller?.text, 'Original Name');
    expect(fields[1].controller?.text, '01/02/1990');
    expect(fields[2].controller?.text, 'Original Residence');
    expect(fields[3].controller?.text, '12345678');
    expect(fields[4].controller?.text, '0700000000');
    expect(
      tester
          .widget<DropdownButtonFormField<Sex>>(
            find.byType(DropdownButtonFormField<Sex>),
          )
          .initialValue,
      Sex.female,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Name');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Updated Residence',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '');
    await tester.enterText(find.byType(TextFormField).at(4), '0711111111');
    await tester.ensureVisible(find.text('UPDATE PATIENT'));
    await tester.pump();
    await tester.tap(find.text('UPDATE PATIENT'));
    await tester.pumpAndSettle();

    expect(injectedUpdate, isNotNull);
    expect(poppedPatient, same(injectedUpdate));
    expect(poppedPatient, isNot(same(original)));
    expect(poppedPatient?.name, 'Updated Name');
    expect(poppedPatient?.residence, 'Updated Residence');
    expect(poppedPatient?.idNumber, isNull);
    expect(poppedPatient?.phoneNumber, '0711111111');
    expect(poppedPatient?.dateOfBirth, DateTime(1990, 1, 2));
    expect(poppedPatient?.sex, Sex.female);
    expect(poppedPatient?.id, original.id);
    expect(poppedPatient?.clinicNumber, original.clinicNumber);
    expect(poppedPatient?.createdAt, same(createdAt));

    expect(original.name, 'Original Name');
    expect(original.residence, 'Original Residence');
    expect(original.idNumber, '12345678');
    expect(original.phoneNumber, '0700000000');
  });

  testWidgets('keeps edited biodata and shows a safe error when update fails', (
    tester,
  ) async {
    final patient = Patient(
      id: 'patient-1',
      clinicNumber: 'CLN-2025-000001',
      name: 'Original Name',
      ageInYears: 35,
      sex: Sex.male,
      residence: 'Original Residence',
      createdAt: DateTime(2025, 4, 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditPatientScreen(
          patient: patient,
          updatePatient: (_) async => throw StateError('backend details'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Edited Name');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text('UPDATE PATIENT'));
    await tester.pump();
    await tester.tap(find.text('UPDATE PATIENT'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to update patient. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('backend details'), findsNothing);
    expect(find.text('Edited Name'), findsOneWidget);
  });
}
