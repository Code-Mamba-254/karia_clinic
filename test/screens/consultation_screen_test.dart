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

  group('delete patient', () {
    final patient = Patient(
      id: 'patient-1',
      clinicNumber: 'CLN-2026-000001',
      name: 'Original Name',
      ageInYears: 30,
      sex: Sex.female,
      residence: 'Original Residence',
      createdAt: DateTime(2026, 1, 1),
    );

    Future<void> openConsultation(
      WidgetTester tester,
      Future<void> Function(String patientId) deletePatient,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ConsultationScreen(
                      patient: patient,
                      consultationStream: (_) => Stream.value([]),
                      deletePatient: deletePatient,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete patient'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for confirmation naming the patient and does nothing on '
        'cancel', (tester) async {
      final deleted = <String>[];
      await openConsultation(tester, (id) async => deleted.add(id));

      expect(find.textContaining('Original Name'), findsWidgets);
      expect(find.textContaining('CLN-2026-000001'), findsWidgets);
      expect(find.textContaining('permanently'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isEmpty);
      expect(find.byType(ConsultationScreen), findsOneWidget);
    });

    testWidgets('confirming deletes the patient and returns to the previous '
        'screen', (tester) async {
      final deleted = <String>[];
      await openConsultation(tester, (id) async => deleted.add(id));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, ['patient-1']);
      expect(find.byType(ConsultationScreen), findsNothing);
      expect(find.text('Patient deleted'), findsOneWidget);
    });

    testWidgets('a failed delete stays on the screen with a safe error', (
      tester,
    ) async {
      await openConsultation(
        tester,
        (_) async => throw StateError('private details'),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(ConsultationScreen), findsOneWidget);
      expect(
        find.text('Unable to delete patient. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private details'), findsNothing);
    });
  });
}
