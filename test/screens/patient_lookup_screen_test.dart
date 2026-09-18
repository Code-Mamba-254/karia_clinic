import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/screens/patient_lookup_screen.dart';
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

  testWidgets('passes mixed-case search text to the injected patient search', (
    tester,
  ) async {
    String? receivedSearchText;

    await tester.pumpWidget(
      MaterialApp(
        home: PatientLookupScreen(
          patientSearch: (searchText) {
            receivedSearchText = searchText;
            return Stream.value(const <Patient>[]);
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'YEGo');
    await tester.pumpAndSettle();

    expect(receivedSearchText, 'YEGo');
    expect(find.text('No patient found.'), findsOneWidget);
  });

  testWidgets('does not repeat search on unrelated parent rebuild', (
    tester,
  ) async {
    var searchCallCount = 0;
    late StateSetter rebuildParent;
    Stream<List<Patient>> patientSearch(String searchText) {
      searchCallCount++;
      return Stream.value(const <Patient>[]);
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuildParent = setState;
          return MaterialApp(
            home: PatientLookupScreen(patientSearch: patientSearch),
          );
        },
      ),
    );

    await tester.enterText(find.byType(TextField), 'YEGo');
    await tester.pumpAndSettle();

    expect(searchCallCount, 1);

    rebuildParent(() {});
    await tester.pumpAndSettle();

    expect(searchCallCount, 1);
  });

  testWidgets(
    'searches only when trimmed input changes and clears empty input',
    (tester) async {
      final receivedSearchTexts = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: PatientLookupScreen(
            patientSearch: (searchText) {
              receivedSearchTexts.add(searchText);
              return Stream.value(const <Patient>[]);
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  YEGo  ');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'YEGo');
      await tester.pumpAndSettle();

      expect(receivedSearchTexts, <String>['YEGo']);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      expect(receivedSearchTexts, <String>['YEGo']);
      expect(find.text('Start typing to search for a patient'), findsOneWidget);
    },
  );

  testWidgets('repeats a nonempty search when callback identity changes', (
    tester,
  ) async {
    var useReplacement = false;
    late StateSetter rebuildParent;
    final initialSearchTexts = <String>[];
    final replacementSearchTexts = <String>[];
    Stream<List<Patient>> initialSearch(String searchText) {
      initialSearchTexts.add(searchText);
      return Stream.value(const <Patient>[]);
    }

    Stream<List<Patient>> replacementSearch(String searchText) {
      replacementSearchTexts.add(searchText);
      return Stream.value(const <Patient>[]);
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuildParent = setState;
          return MaterialApp(
            home: PatientLookupScreen(
              patientSearch: useReplacement ? replacementSearch : initialSearch,
            ),
          );
        },
      ),
    );

    await tester.enterText(find.byType(TextField), 'Jane');
    await tester.pumpAndSettle();

    rebuildParent(() => useReplacement = true);
    await tester.pumpAndSettle();

    expect(initialSearchTexts, <String>['Jane']);
    expect(replacementSearchTexts, <String>['Jane']);
  });

  testWidgets('hides private backend details when patient search fails', (
    tester,
  ) async {
    const privateDetails = 'private backend collection: patients-prod';

    await tester.pumpWidget(
      MaterialApp(
        home: PatientLookupScreen(
          patientSearch: (_) => Stream<List<Patient>>.error(privateDetails),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Jane');
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to search patients. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining(privateDetails), findsNothing);
  });
}
