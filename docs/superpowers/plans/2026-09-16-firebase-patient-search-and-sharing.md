# Firebase Patient Search and Shared Records Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Cloud Firestore patient lookup case-insensitive across every name component and allow authenticated Karia Clinic doctors to view and edit records created by other doctors without changing original consultation attribution.

**Architecture:** Store deterministic normalized name prefixes in each patient document and query them with Firestore `arrayContains`, ordered by the normalized full name. Keep the existing project-wide collections as the single-clinic boundary, enforce shared authenticated access and immutable consultation attribution in version-controlled Firestore rules, and backfill legacy patients with an idempotent Firebase Admin migration.

**Tech Stack:** Flutter/Dart 3.11, FlutterFire `cloud_firestore` 6, `fake_cloud_firestore` 4.2, Firebase Security Rules, Firebase Emulator Suite, Node.js built-in test runner, Firebase Admin SDK 14.4, Firebase JS SDK 12.19, `@firebase/rules-unit-testing` 5.0.2.

---

## File Structure

### Create

- `lib/utils/patient_search_index.dart` — canonical Dart name normalization and prefix generation.
- `test/fixtures/patient_search_cases.json` — shared cross-language normalization fixtures.
- `test/patient_search_index_test.dart` — unit tests for normalization and prefixes.
- `test/services/patient_service_test.dart` — Firestore query tests using an injected fake database.
- `test/screens/patient_lookup_screen_test.dart` — lookup UI input and error-state tests.
- `test/services/consultation_service_test.dart` — project-wide consultation history and immutable update tests.
- `test/screens/edit_consultation_screen_test.dart` — attribution and update-error widget tests.
- `firestore.rules` — authenticated clinical access and immutable attribution policy.
- `firestore.indexes.json` — patient search and consultation history indexes.
- `firebase/package.json` — isolated Node tooling for rules tests and migration.
- `firebase/test/firestore.rules.test.mjs` — emulator-backed authorization tests.
- `firebase/scripts/patient_search_index.mjs` — JavaScript equivalent of canonical prefix generation.
- `firebase/scripts/backfill_patient_search_prefixes.mjs` — dry-run-by-default migration CLI.
- `firebase/test/patient_search_index.test.mjs` — shared-fixture JavaScript tests.
- `firebase/test/backfill_patient_search_prefixes.test.mjs` — emulator-backed migration tests.

### Modify

- `pubspec.yaml:43-53` — add `fake_cloud_firestore` test dependency.
- `lib/models/patient.dart:95-120` — serialize canonical `nameLowercase` and `searchPrefixes`.
- `lib/services/patient_service.dart:5-90` — remove client migration and query `searchPrefixes`.
- `lib/screens/patient_lookup_screen.dart:10-145` — inject search behavior for widget tests.
- `test/patient_name_matcher_test.dart:1-23` — replace obsolete full-name-prefix expectations.
- `test/patient_biodata_regression_test.dart:85-90` — assert both derived search fields.
- `lib/models/consultation.dart:90-116` — add a mutable-fields-only update map.
- `lib/services/consultation_service.dart:5-56` — inject Firestore and preserve attribution on updates.
- `lib/screens/edit_consultation_screen.dart:6-205` — inject update behavior and handle failures without losing form state.
- `firebase.json:1` — register Firestore rules and index files.
- `pubspec.lock` and `firebase/package-lock.json` — dependency lock updates produced by package resolution.

## External References Confirmed

- FlutterFire query API supports `where(..., arrayContains:)`, `orderBy`, `limit`, and snapshot streams: <https://github.com/firebase/flutterfire/blob/main/packages/cloud_firestore/cloud_firestore/lib/src/query.dart>
- `fake_cloud_firestore` 4.2.0 supports `arrayContains` query tests: <https://pub.dev/packages/fake_cloud_firestore>
- Firebase Admin initializes with Application Default Credentials and exposes Firestore batch/BulkWriter APIs: <https://github.com/firebase/firebase-admin-node>
- Security Rules tests use `initializeTestEnvironment`, authenticated/unauthenticated contexts, and rule-bypassed seeding: <https://firebase.google.com/docs/rules/unit-tests>
- Firestore rules can compare `request.resource.data` with `resource.data` to keep fields immutable: <https://firebase.google.com/docs/firestore/security/rules-conditions>
- Firestore index definitions and deployment: <https://firebase.google.com/docs/firestore/query-data/indexing>

---

### Task 1: Canonical Patient Search Index

**Files:**
- Create: `test/fixtures/patient_search_cases.json`
- Create: `test/patient_search_index_test.dart`
- Create: `lib/utils/patient_search_index.dart`

- [ ] **Step 1: Add shared normalization fixtures**

Create `test/fixtures/patient_search_cases.json`:

```json
[
  {
    "name": "  Raymond   Kip Yegon  ",
    "normalized": "raymond kip yegon",
    "matches": ["r", "RAY", "kip", "Kip Y", "YEGo", "yegon"],
    "misses": ["mond", "ip", "ray y"]
  },
  {
    "name": "Mary O'Neil",
    "normalized": "mary o'neil",
    "matches": ["mary", "O'N", "o'neil"],
    "misses": ["neil"]
  },
  {
    "name": "Élodie Njeri",
    "normalized": "élodie njeri",
    "matches": ["ÉLO", "njer"],
    "misses": ["lodie"]
  },
  {
    "name": "   ",
    "normalized": "",
    "matches": [],
    "misses": ["a"]
  }
]
```

- [ ] **Step 2: Write failing Dart tests**

Create `test/patient_search_index_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:clinic_app/utils/patient_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures = (jsonDecode(
    File('test/fixtures/patient_search_cases.json').readAsStringSync(),
  ) as List<dynamic>).cast<Map<String, dynamic>>();

  test('normalizes patient names consistently', () {
    for (final fixture in fixtures) {
      expect(
        normalizePatientSearchText(fixture['name'] as String),
        fixture['normalized'],
        reason: fixture['name'] as String,
      );
    }
  });

  test('builds prefixes at every name-component boundary', () {
    for (final fixture in fixtures) {
      final prefixes = buildPatientSearchPrefixes(fixture['name'] as String);
      for (final query in (fixture['matches'] as List<dynamic>).cast<String>()) {
        expect(
          prefixes,
          contains(normalizePatientSearchText(query)),
          reason: '${fixture['name']} should match $query',
        );
      }
      for (final query in (fixture['misses'] as List<dynamic>).cast<String>()) {
        expect(
          prefixes,
          isNot(contains(normalizePatientSearchText(query))),
          reason: '${fixture['name']} should not match $query',
        );
      }
    }
  });

  test('does not emit duplicates or prefixes ending in whitespace', () {
    final prefixes = buildPatientSearchPrefixes('Ann Ann');

    expect(prefixes.toSet().length, prefixes.length);
    expect(prefixes.any((prefix) => prefix.endsWith(' ')), isFalse);
  });
}
```

- [ ] **Step 3: Run the tests and verify RED**

Run:

```bash
flutter test test/patient_search_index_test.dart
```

Expected: compilation fails because `lib/utils/patient_search_index.dart` does not exist.

- [ ] **Step 4: Implement the pure search-index utility**

Create `lib/utils/patient_search_index.dart`:

```dart
String normalizePatientSearchText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

List<String> buildPatientSearchPrefixes(String patientName) {
  final normalizedName = normalizePatientSearchText(patientName);
  if (normalizedName.isEmpty) return const [];

  final componentStarts = <int>[0];
  for (var index = 0; index < normalizedName.length; index++) {
    if (normalizedName[index] == ' ' && index + 1 < normalizedName.length) {
      componentStarts.add(index + 1);
    }
  }

  final prefixes = <String>{};
  for (final start in componentStarts) {
    for (var end = start + 1; end <= normalizedName.length; end++) {
      final prefix = normalizedName.substring(start, end);
      if (!prefix.endsWith(' ')) prefixes.add(prefix);
    }
  }
  return List.unmodifiable(prefixes);
}
```

- [ ] **Step 5: Run the unit tests and verify GREEN**

Run:

```bash
flutter test test/patient_search_index_test.dart
```

Expected: all three tests pass.

- [ ] **Step 6: Commit the isolated utility when commits are authorized**

```bash
git add lib/utils/patient_search_index.dart test/fixtures/patient_search_cases.json test/patient_search_index_test.dart
git commit -m "feat: add patient search prefix index"
```

---

### Task 2: Persist Search Prefixes on Every Patient Write

**Files:**
- Modify: `test/patient_biodata_regression_test.dart:85-90`
- Modify: `lib/models/patient.dart:3-4,95-120`

- [ ] **Step 1: Replace the serialization regression assertion**

Change the existing persistence test in `test/patient_biodata_regression_test.dart` to:

```dart
test('persistence maps include canonical patient search fields', () {
  final patient = buildPatient().copyWith(name: '  Jane   DOE  ');

  for (final map in [patient.toMap(), patient.toUpdateMap()]) {
    expect(map['nameLowercase'], 'jane doe');
    expect(map['searchPrefixes'], containsAll(['j', 'jane doe', 'd', 'doe']));
  }
});
```

- [ ] **Step 2: Run the regression test and verify RED**

Run:

```bash
flutter test test/patient_biodata_regression_test.dart
```

Expected: failure because `searchPrefixes` is absent and repeated whitespace remains in `nameLowercase`.

- [ ] **Step 3: Use the canonical utility in patient serialization**

Add this import to `lib/models/patient.dart`:

```dart
import '../utils/patient_search_index.dart';
```

In both `toUpdateMap()` and `toMap()`, replace the existing derived name field with:

```dart
'nameLowercase': normalizePatientSearchText(name),
'searchPrefixes': buildPatientSearchPrefixes(name),
```

Keep all other fields unchanged.

- [ ] **Step 4: Run model and index tests**

Run:

```bash
flutter test test/patient_biodata_regression_test.dart test/patient_search_index_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit patient serialization when commits are authorized**

```bash
git add lib/models/patient.dart test/patient_biodata_regression_test.dart
git commit -m "feat: persist patient search prefixes"
```

---

### Task 3: Query Firestore Case-Insensitively Without Client Migration

**Files:**
- Modify: `pubspec.yaml:43-53`
- Modify: `pubspec.lock`
- Create: `test/services/patient_service_test.dart`
- Modify: `test/patient_name_matcher_test.dart:1-23`
- Modify: `lib/services/patient_service.dart:5-90`

- [ ] **Step 1: Add the Firestore test double**

Run:

```bash
flutter pub add --dev fake_cloud_firestore:^4.2.0
```

Expected: `pubspec.yaml` and `pubspec.lock` add `fake_cloud_firestore` without changing production dependencies.

- [ ] **Step 2: Write failing Firestore query tests**

Create `test/services/patient_service_test.dart`:

```dart
import 'package:clinic_app/enums/sex.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/services/patient_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Patient patient(String id, String name) => Patient(
  id: id,
  clinicNumber: 'CLN-$id',
  name: name,
  ageInYears: 30,
  sex: Sex.female,
  residence: 'Karia',
  createdAt: DateTime(2026, 9, 16),
);

void main() {
  test('finds a patient by a mixed-case surname prefix', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('patients').doc('patient-1').set(
      patient('patient-1', 'Raymond Yegon').toMap(),
    );

    final results = await PatientService(
      firestore: firestore,
    ).searchPatients('  YEGo  ').first;

    expect(results.map((item) => item.id), ['patient-1']);
  });

  test('finds a patient using a middle-name phrase prefix', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('patients').doc('patient-1').set(
      patient('patient-1', 'Raymond Kip Yegon').toMap(),
    );

    final results = await PatientService(
      firestore: firestore,
    ).searchPatients('KIP Y').first;

    expect(results.single.name, 'Raymond Kip Yegon');
  });

  test('does not rewrite legacy patients during search', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('patients').doc('legacy').set({
      ...patient('legacy', 'Legacy Patient').toMap(),
      'searchPrefixes': null,
    });

    final results = await PatientService(
      firestore: firestore,
    ).searchPatients('legacy').first;
    final stored = await firestore.collection('patients').doc('legacy').get();

    expect(results, isEmpty);
    expect(stored.data()?['searchPrefixes'], isNull);
  });

  test('returns no patients for whitespace-only input', () async {
    final firestore = FakeFirebaseFirestore();

    final results = await PatientService(
      firestore: firestore,
    ).searchPatients('   ').first;

    expect(results, isEmpty);
  });
}
```

- [ ] **Step 3: Update the obsolete matcher tests to target current semantics**

Replace `test/patient_name_matcher_test.dart` with:

```dart
import 'package:clinic_app/services/patient_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('patientNameMatches', () {
    test('matches any name component without regard to case', () {
      expect(patientNameMatches('Jane Mary Doe', 'jAnE'), isTrue);
      expect(patientNameMatches('Jane Mary Doe', 'MARY D'), isTrue);
      expect(patientNameMatches('Jane Mary Doe', 'dOe'), isTrue);
    });

    test('normalizes repeated whitespace', () {
      expect(patientNameMatches('  Jane   Doe  ', ' jane d '), isTrue);
    });

    test('requires a name-component boundary', () {
      expect(patientNameMatches('Jane Doe', 'ane'), isFalse);
      expect(patientNameMatches('Jane Doe', 'oe'), isFalse);
    });

    test('does not match an empty trimmed search', () {
      expect(patientNameMatches('Jane Doe', '   '), isFalse);
    });
  });
}
```

- [ ] **Step 4: Run service and matcher tests and verify RED**

Run:

```bash
flutter test test/services/patient_service_test.dart test/patient_name_matcher_test.dart
```

Expected: surname and middle-name searches fail under the old `nameLowercase` range query; the legacy document may be rewritten by the old client backfill.

- [ ] **Step 5: Replace the query and remove the client migration**

Refactor `lib/services/patient_service.dart` to retain save/update methods and use this query logic:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import '../utils/patient_search_index.dart';

class PatientService {
  static const _searchResultLimit = 50;

  final FirebaseFirestore _db;

  PatientService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get patients =>
      _db.collection('patients');

  Future<Patient> savePatient(Patient patient) async {
    final document = await patients.add(patient.toMap());
    return patient.copyWith(id: document.id);
  }

  Stream<List<Patient>> searchPatients(String searchText) {
    final normalizedSearch = normalizePatientSearchText(searchText);
    if (normalizedSearch.isEmpty) return Stream.value(const []);

    return patients
        .where('searchPrefixes', arrayContains: normalizedSearch)
        .orderBy('nameLowercase')
        .limit(_searchResultLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Patient.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> updatePatient(Patient patient) async {
    if (patient.id.trim().isEmpty) {
      throw ArgumentError.value(patient.id, 'patient.id', 'ID is required.');
    }
    await patients.doc(patient.id).update(patient.toUpdateMap());
  }
}

bool patientNameMatches(String patientName, String searchText) {
  final normalizedSearch = normalizePatientSearchText(searchText);
  return normalizedSearch.isNotEmpty &&
      buildPatientSearchPrefixes(patientName).contains(normalizedSearch);
}
```

Delete `_migrationBatchSize`, `_searchIndexReady`, `_ensureSearchIndex`, and `_backfillLegacySearchNames` completely.

- [ ] **Step 6: Run focused Firestore tests and verify GREEN**

Run:

```bash
flutter test test/services/patient_service_test.dart test/patient_name_matcher_test.dart test/patient_biodata_regression_test.dart
```

Expected: all tests pass and no search writes to legacy documents.

- [ ] **Step 7: Commit query behavior when commits are authorized**

```bash
git add pubspec.yaml pubspec.lock lib/services/patient_service.dart test/services/patient_service_test.dart test/patient_name_matcher_test.dart
git commit -m "feat: search patients by case-insensitive name parts"
```

---

### Task 4: Make Patient Lookup Search Testable and Keep Safe Errors

**Files:**
- Create: `test/screens/patient_lookup_screen_test.dart`
- Modify: `lib/screens/patient_lookup_screen.dart:10-145`

- [ ] **Step 1: Write failing lookup widget tests**

Create `test/screens/patient_lookup_screen_test.dart`:

```dart
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/screens/patient_lookup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('passes mixed-case input to the Firebase search flow', (tester) async {
    String? receivedQuery;
    await tester.pumpWidget(
      MaterialApp(
        home: PatientLookupScreen(
          patientSearch: (query) {
            receivedQuery = query;
            return Stream<List<Patient>>.value(const []);
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'YEGo');
    await tester.pumpAndSettle();

    expect(receivedQuery, 'YEGo');
    expect(find.text('No patient found.'), findsOneWidget);
  });

  testWidgets('shows a safe message when Firebase search fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientLookupScreen(
          patientSearch: (_) => Stream<List<Patient>>.error(
            StateError('private backend details'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Jane');
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to search patients. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private backend details'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the widget test and verify RED**

Run:

```bash
flutter test test/screens/patient_lookup_screen_test.dart
```

Expected: compilation fails because `PatientLookupScreen` has no `patientSearch` parameter.

- [ ] **Step 3: Add a narrow injectable search boundary**

Add above `PatientLookupScreen`:

```dart
typedef PatientSearch = Stream<List<Patient>> Function(String searchText);
```

Change the widget constructor and field to:

```dart
class PatientLookupScreen extends StatefulWidget {
  final PatientSearch? patientSearch;

  const PatientLookupScreen({super.key, this.patientSearch});
```

Replace the stream expression with:

```dart
stream: (widget.patientSearch ?? _patientService.searchPatients)(searchText),
```

Keep the existing safe error text unchanged.

- [ ] **Step 4: Run lookup tests and verify GREEN**

Run:

```bash
flutter test test/screens/patient_lookup_screen_test.dart
```

Expected: both widget tests pass.

- [ ] **Step 5: Commit the lookup seam when commits are authorized**

```bash
git add lib/screens/patient_lookup_screen.dart test/screens/patient_lookup_screen_test.dart
git commit -m "test: cover patient lookup search states"
```

---

### Task 5: Preserve Consultation Attribution in Service Updates

**Files:**
- Modify: `test/consultation_test.dart:34-75`
- Create: `test/services/consultation_service_test.dart`
- Modify: `lib/models/consultation.dart:90-116`
- Modify: `lib/services/consultation_service.dart:5-56`

- [ ] **Step 1: Add a failing immutable-update-map test**

Append to `test/consultation_test.dart`:

```dart
test('update map excludes immutable attribution and identity fields', () {
  final update = buildConsultation().toUpdateMap();

  expect(update, isNot(contains('patientId')));
  expect(update, isNot(contains('doctorId')));
  expect(update, isNot(contains('doctorEmail')));
  expect(update, isNot(contains('doctorName')));
  expect(update, isNot(contains('createdAt')));
  expect(update, containsPair('diagnosis', 'Migraine'));
});
```

- [ ] **Step 2: Write failing shared-history service tests**

Create `test/services/consultation_service_test.dart`:

```dart
import 'package:clinic_app/models/consultation.dart';
import 'package:clinic_app/services/consultation_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Consultation consultation({
  required String id,
  required String doctorId,
  required String diagnosis,
}) => Consultation(
  id: id,
  patientId: 'patient-1',
  doctorId: doctorId,
  doctorEmail: '$doctorId@example.com',
  doctorName: doctorId,
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
  createdAt: DateTime(2026, 9, 16, 10),
);

void main() {
  test('history is scoped by patient and not recording doctor', () async {
    final firestore = FakeFirebaseFirestore();
    final service = ConsultationService(firestore: firestore);
    await firestore.collection('consultations').doc('consultation-a').set(
      consultation(
        id: 'consultation-a',
        doctorId: 'doctor-a',
        diagnosis: 'Original',
      ).toMap(),
    );

    final results = await service.getPatientConsultations('patient-1').first;

    expect(results.single.doctorId, 'doctor-a');
  });

  test('updating clinical fields does not replace attribution', () async {
    final firestore = FakeFirebaseFirestore();
    final service = ConsultationService(firestore: firestore);
    final original = consultation(
      id: 'consultation-a',
      doctorId: 'doctor-a',
      diagnosis: 'Original',
    );
    await firestore.collection('consultations').doc(original.id).set(
      original.toMap(),
    );

    await service.updateConsultation(
      consultation(
        id: original.id,
        doctorId: 'doctor-b',
        diagnosis: 'Updated by B',
      ),
    );
    final stored = await firestore.collection('consultations').doc(original.id).get();

    expect(stored.data()?['diagnosis'], 'Updated by B');
    expect(stored.data()?['doctorId'], 'doctor-a');
    expect(stored.data()?['doctorEmail'], 'doctor-a@example.com');
    expect(stored.data()?['doctorName'], 'doctor-a');
  });
}
```

- [ ] **Step 3: Run focused tests and verify RED**

Run:

```bash
flutter test test/consultation_test.dart test/services/consultation_service_test.dart
```

Expected: compilation fails because `toUpdateMap` and the injectable service constructor do not exist.

- [ ] **Step 4: Add mutable-fields-only serialization**

Add to `Consultation` in `lib/models/consultation.dart`:

```dart
Map<String, dynamic> toUpdateMap() {
  return {
    'chiefComplaint': chiefComplaint,
    'temperature': temperature,
    'pulseRate': pulseRate,
    'respiratoryRate': respiratoryRate,
    'bloodPressure': bloodPressure,
    'oxygenSaturation': oxygenSaturation,
    'weight': weight,
    'height': height,
    'bmi': bmi,
    'investigations': investigations,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'labFeedback': labFeedback,
    'remarks': remarks,
  };
}
```

- [ ] **Step 5: Inject Firestore and use the update map**

Change `ConsultationService` to:

```dart
class ConsultationService {
  final FirebaseFirestore _db;

  ConsultationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get consultations =>
      _db.collection('consultations');
```

Change `updateConsultation` to:

```dart
Future<void> updateConsultation(Consultation consultation) async {
  if (consultation.id.trim().isEmpty) {
    throw ArgumentError.value(
      consultation.id,
      'consultation.id',
      'ID is required.',
    );
  }
  await consultations.doc(consultation.id).update(consultation.toUpdateMap());
}
```

Keep the patient-only history filter and all other service behavior unchanged.

- [ ] **Step 6: Run model and service tests and verify GREEN**

Run:

```bash
flutter test test/consultation_test.dart test/services/consultation_service_test.dart
```

Expected: all tests pass; updating diagnosis does not change original doctor fields.

- [ ] **Step 7: Commit consultation persistence when commits are authorized**

```bash
git add lib/models/consultation.dart lib/services/consultation_service.dart test/consultation_test.dart test/services/consultation_service_test.dart
git commit -m "fix: preserve consultation recording doctor"
```

---

### Task 6: Handle Cross-Doctor Edit Failures Without Losing Form State

**Files:**
- Create: `test/screens/edit_consultation_screen_test.dart`
- Modify: `lib/screens/edit_consultation_screen.dart:6-205`

- [ ] **Step 1: Write failing edit-screen tests**

Create `test/screens/edit_consultation_screen_test.dart` with a local consultation fixture and these tests:

```dart
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
  testWidgets('cross-doctor edit preserves original attribution', (tester) async {
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

  testWidgets('failed update retains text and shows a safe error', (tester) async {
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
```

- [ ] **Step 2: Run the widget tests and verify RED**

Run:

```bash
flutter test test/screens/edit_consultation_screen_test.dart
```

Expected: compilation fails because `updateConsultation` is not injectable; failure handling is also absent.

- [ ] **Step 3: Add the injected update boundary and saving state**

Add to `EditConsultationScreen`:

```dart
final Future<void> Function(Consultation consultation)? updateConsultation;

const EditConsultationScreen({
  super.key,
  required this.consultation,
  this.updateConsultation,
});
```

Add state:

```dart
bool isSaving = false;
```

Replace the service call, success handling, and button handler with guarded error handling:

```dart
Future<void> updateConsultation() async {
  if (isSaving) return;
  final updated = Consultation(
    id: widget.consultation.id,
    patientId: widget.consultation.patientId,
    doctorId: widget.consultation.doctorId,
    doctorEmail: widget.consultation.doctorEmail,
    doctorName: widget.consultation.doctorName,
    chiefComplaint: chiefComplaintController.text.trim(),
    temperature: temperatureController.text.trim(),
    pulseRate: pulseController.text.trim(),
    respiratoryRate: respiratoryController.text.trim(),
    bloodPressure: bpController.text.trim(),
    oxygenSaturation: oxygenController.text.trim(),
    weight: weightController.text.trim(),
    height: heightController.text.trim(),
    bmi: widget.consultation.bmi,
    investigations: investigationsController.text.trim(),
    diagnosis: diagnosisController.text.trim(),
    treatment: treatmentController.text.trim(),
    labFeedback: labController.text.trim(),
    remarks: remarksController.text.trim(),
    createdAt: widget.consultation.createdAt,
  );

  setState(() => isSaving = true);
  try {
    await (widget.updateConsultation?.call(updated) ??
        _consultationService.updateConsultation(updated));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultation Updated')),
    );
    Navigator.pop(context);
  } catch (error) {
    debugPrint('Consultation update failed: ${error.runtimeType}');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to update consultation. Please try again.'),
      ),
    );
  } finally {
    if (mounted) setState(() => isSaving = false);
  }
}
```

Set the button handler and label to:

```dart
onPressed: isSaving ? null : updateConsultation,
label: Text(isSaving ? 'Updating...' : 'Update Consultation'),
```

- [ ] **Step 4: Run the edit-screen tests and verify GREEN**

Run:

```bash
flutter test test/screens/edit_consultation_screen_test.dart
```

Expected: both tests pass; the failure leaves the screen and edited text intact.

- [ ] **Step 5: Run existing consultation UI regressions**

Run:

```bash
flutter test test/screens/consultation_screen_test.dart test/widgets/consultation_card_test.dart
```

Expected: all existing consultation tests pass.

- [ ] **Step 6: Commit safe edit handling when commits are authorized**

```bash
git add lib/screens/edit_consultation_screen.dart test/screens/edit_consultation_screen_test.dart
git commit -m "fix: handle shared consultation update failures"
```

---

### Task 7: Version and Test Firestore Access Rules

**Files:**
- Create: `firestore.rules`
- Create: `firestore.indexes.json`
- Modify: `firebase.json:1`
- Create: `firebase/package.json`
- Create: `firebase/test/firestore.rules.test.mjs`
- Create: `firebase/package-lock.json`

- [ ] **Step 1: Add isolated Firebase Node tooling**

Create `firebase/package.json`:

```json
{
  "name": "karia-clinic-firebase-tools",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=20"
  },
  "scripts": {
    "test": "node --test test/*.test.mjs",
    "test:rules": "node --test test/firestore.rules.test.mjs",
    "test:migration": "node --test test/patient_search_index.test.mjs test/backfill_patient_search_prefixes.test.mjs"
  },
  "dependencies": {
    "firebase-admin": "14.4.0"
  },
  "devDependencies": {
    "@firebase/rules-unit-testing": "5.0.2",
    "firebase": "12.19.0",
    "firebase-tools": "15.30.1"
  }
}
```

Run:

```bash
npm --prefix firebase install
```

Expected: `firebase/package-lock.json` is created with no audit failure.

- [ ] **Step 2: Write failing rules tests**

Create `firebase/test/firestore.rules.test.mjs`:

```javascript
import { readFileSync } from 'node:fs';
import { after, afterEach, before, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const projectId = 'demo-karia-clinic-rules';
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(
        new URL('../../firestore.rules', import.meta.url),
        'utf8',
      ),
    },
  });
});

afterEach(async () => environment.clearFirestore());
after(async () => environment.cleanup());

async function seedConsultation() {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'consultations/consultation-1'), {
      patientId: 'patient-1',
      doctorId: 'doctor-a',
      doctorEmail: 'doctor-a@example.com',
      doctorName: 'Doctor A',
      diagnosis: 'Original',
      createdAt: new Date('2026-09-16T10:00:00Z'),
    });
  });
}

describe('clinical record access', () => {
  test('denies unauthenticated patient reads', async () => {
    const db = environment.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'patients/patient-1')));
  });

  test('allows one authenticated doctor to read another doctor record', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'patients/patient-1'), {
        name: 'Jane Doe',
      });
    });
    const db = environment.authenticatedContext('doctor-b').firestore();
    await assertSucceeds(getDoc(doc(db, 'patients/patient-1')));
  });

  test('allows another doctor to edit clinical fields only', async () => {
    await seedConsultation();
    const db = environment.authenticatedContext('doctor-b').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'consultations/consultation-1'), {
        diagnosis: 'Updated by Doctor B',
      }),
    );
  });

  test('rejects changing original attribution', async () => {
    await seedConsultation();
    const db = environment.authenticatedContext('doctor-b').firestore();
    await assertFails(
      updateDoc(doc(db, 'consultations/consultation-1'), {
        doctorId: 'doctor-b',
      }),
    );
  });

  test('allows only the original doctor to delete a consultation', async () => {
    await seedConsultation();
    const doctorB = environment.authenticatedContext('doctor-b').firestore();
    await assertFails(deleteDoc(doc(doctorB, 'consultations/consultation-1')));

    const doctorA = environment.authenticatedContext('doctor-a').firestore();
    await assertSucceeds(deleteDoc(doc(doctorA, 'consultations/consultation-1')));
  });

  test('allows public doctor directory reads but denies client writes', async () => {
    const publicDb = environment.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(publicDb, 'doctors/doctor-a')));

    const doctorDb = environment.authenticatedContext('doctor-a').firestore();
    await assertFails(setDoc(doc(doctorDb, 'doctors/doctor-a'), { active: true }));
  });

  test('requires authentication for the shared counter', async () => {
    const publicDb = environment.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(publicDb, 'counters/patient_counter')));

    const doctorDb = environment.authenticatedContext('doctor-a').firestore();
    await assertSucceeds(
      setDoc(doc(doctorDb, 'counters/patient_counter'), { count: 1 }),
    );
  });
});
```

Remove the unused `assert` import if the linter reports it; the test behavior must remain unchanged.

- [ ] **Step 3: Run rules tests and verify RED**

Run:

```bash
npm --prefix firebase exec firebase -- emulators:exec --project demo-karia-clinic-rules --only firestore "npm --prefix firebase run test:rules"
```

Expected: failure because `firestore.rules` does not exist.

- [ ] **Step 4: Add least-privilege single-clinic rules**

Create `firestore.rules`:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function consultationIdentityUnchanged() {
      return request.resource.data.patientId == resource.data.patientId
        && request.resource.data.doctorId == resource.data.doctorId
        && request.resource.data.doctorEmail == resource.data.doctorEmail
        && request.resource.data.doctorName == resource.data.doctorName
        && request.resource.data.createdAt == resource.data.createdAt;
    }

    match /patients/{patientId} {
      allow read, create, update: if signedIn();
      allow delete: if false;
    }

    match /consultations/{consultationId} {
      allow read: if signedIn();
      allow create: if signedIn()
        && request.resource.data.doctorId == request.auth.uid;
      allow update: if signedIn() && consultationIdentityUnchanged();
      allow delete: if signedIn()
        && resource.data.doctorId == request.auth.uid;
    }

    match /counters/{counterId} {
      allow read, create, update: if signedIn();
      allow delete: if false;
    }

    match /doctors/{doctorId} {
      allow read: if true;
      allow write: if false;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 5: Add reproducible indexes**

Create `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "patients",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "searchPrefixes", "arrayConfig": "CONTAINS" },
        { "fieldPath": "nameLowercase", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "consultations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "patientId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Rewrite `firebase.json` as formatted JSON while retaining current Flutter platform data and adding root-level Firestore configuration:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "clinic-app-b2569",
          "appId": "1:727243261368:android:f881fc8b61ded5550d7b4d",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "clinic-app-b2569",
          "configurations": {
            "ios": "1:727243261368:ios:c50bb655a7983d1b0d7b4d"
          }
        }
      },
      "ios": {
        "default": {
          "projectId": "clinic-app-b2569",
          "appId": "1:727243261368:ios:c50bb655a7983d1b0d7b4d",
          "uploadDebugSymbols": false,
          "fileOutput": "ios/Runner/GoogleService-Info.plist"
        }
      }
    }
  }
}
```

- [ ] **Step 6: Run rules tests and verify GREEN**

Run:

```bash
npm --prefix firebase exec firebase -- emulators:exec --project demo-karia-clinic-rules --only firestore "npm --prefix firebase run test:rules"
```

Expected: all rules tests pass and the emulator exits successfully.

- [ ] **Step 7: Commit rules and tests when commits are authorized**

```bash
git add firestore.rules firestore.indexes.json firebase.json firebase/package.json firebase/package-lock.json firebase/test/firestore.rules.test.mjs
git commit -m "feat: allow authenticated clinic-wide record access"
```

---

### Task 8: Backfill Existing Firebase Patients Safely

**Files:**
- Create: `firebase/scripts/patient_search_index.mjs`
- Create: `firebase/scripts/backfill_patient_search_prefixes.mjs`
- Create: `firebase/test/patient_search_index.test.mjs`
- Create: `firebase/test/backfill_patient_search_prefixes.test.mjs`

- [ ] **Step 1: Write the failing JavaScript fixture test**

Create `firebase/test/patient_search_index.test.mjs`:

```javascript
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  buildPatientSearchPrefixes,
  normalizePatientSearchText,
} from '../scripts/patient_search_index.mjs';

const fixtures = JSON.parse(
  readFileSync(
    new URL('../../test/fixtures/patient_search_cases.json', import.meta.url),
    'utf8',
  ),
);

test('matches the shared Dart normalization fixtures', () => {
  for (const fixture of fixtures) {
    assert.equal(normalizePatientSearchText(fixture.name), fixture.normalized);
    const prefixes = buildPatientSearchPrefixes(fixture.name);
    for (const query of fixture.matches) {
      assert.ok(prefixes.includes(normalizePatientSearchText(query)));
    }
    for (const query of fixture.misses) {
      assert.ok(!prefixes.includes(normalizePatientSearchText(query)));
    }
  }
});
```

- [ ] **Step 2: Run the JavaScript utility test and verify RED**

Run:

```bash
npm --prefix firebase run test:migration
```

Expected: module-not-found failure for `firebase/scripts/patient_search_index.mjs`.

- [ ] **Step 3: Implement matching JavaScript normalization**

Create `firebase/scripts/patient_search_index.mjs`:

```javascript
export function normalizePatientSearchText(value) {
  return value.trim().replace(/\s+/gu, ' ').toLowerCase();
}

export function buildPatientSearchPrefixes(patientName) {
  const normalizedName = normalizePatientSearchText(patientName);
  if (!normalizedName) return [];

  const componentStarts = [0];
  for (let index = 0; index < normalizedName.length; index += 1) {
    if (normalizedName[index] === ' ' && index + 1 < normalizedName.length) {
      componentStarts.push(index + 1);
    }
  }

  const prefixes = new Set();
  for (const start of componentStarts) {
    for (let end = start + 1; end <= normalizedName.length; end += 1) {
      const prefix = normalizedName.slice(start, end);
      if (!prefix.endsWith(' ')) prefixes.add(prefix);
    }
  }
  return [...prefixes];
}
```

- [ ] **Step 4: Run the shared fixture test and verify GREEN**

Run:

```bash
node --test firebase/test/patient_search_index.test.mjs
```

Expected: test passes.

- [ ] **Step 5: Write failing emulator-backed migration tests**

Create `firebase/test/backfill_patient_search_prefixes.test.mjs`:

```javascript
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { backfillPatientSearchPrefixes } from '../scripts/backfill_patient_search_prefixes.mjs';

let app;
let db;

before(() => {
  app = initializeApp({ projectId: 'demo-karia-migration' }, 'migration-tests');
  db = getFirestore(app);
});

beforeEach(async () => {
  const snapshot = await db.collection('patients').get();
  const batch = db.batch();
  for (const document of snapshot.docs) batch.delete(document.ref);
  await batch.commit();
});

after(async () => deleteApp(app));

test('dry-run reports changes without writing', async () => {
  await db.collection('patients').doc('patient-1').set({ name: 'Jane DOE' });

  const stats = await backfillPatientSearchPrefixes({
    db,
    dryRun: true,
    pageSize: 1,
    logger: { info() {}, error() {} },
  });
  const stored = await db.collection('patients').doc('patient-1').get();

  assert.deepEqual(stats, { scanned: 1, unchanged: 0, updated: 1, malformed: 0 });
  assert.equal(stored.data().searchPrefixes, undefined);
});

test('apply mode handles pages and is idempotent', async () => {
  await db.collection('patients').doc('patient-1').set({ name: 'Jane Doe' });
  await db.collection('patients').doc('patient-2').set({ name: 'Raymond Yegon' });
  await db.collection('patients').doc('malformed').set({ name: '' });

  const first = await backfillPatientSearchPrefixes({
    db,
    dryRun: false,
    pageSize: 1,
    logger: { info() {}, error() {} },
  });
  const second = await backfillPatientSearchPrefixes({
    db,
    dryRun: false,
    pageSize: 1,
    logger: { info() {}, error() {} },
  });
  const stored = await db.collection('patients').doc('patient-2').get();

  assert.deepEqual(first, { scanned: 3, unchanged: 0, updated: 2, malformed: 1 });
  assert.deepEqual(second, { scanned: 3, unchanged: 2, updated: 0, malformed: 1 });
  assert.ok(stored.data().searchPrefixes.includes('yeg'));
  assert.equal(stored.data().nameLowercase, 'raymond yegon');
});
```

- [ ] **Step 6: Run migration tests and verify RED**

Run:

```bash
npm --prefix firebase exec firebase -- emulators:exec --project demo-karia-migration --only firestore "npm --prefix firebase run test:migration"
```

Expected: module-not-found failure for `backfill_patient_search_prefixes.mjs`.

- [ ] **Step 7: Implement the idempotent backfill and CLI**

Create `firebase/scripts/backfill_patient_search_prefixes.mjs`:

```javascript
import { pathToFileURL } from 'node:url';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldPath, getFirestore } from 'firebase-admin/firestore';
import {
  buildPatientSearchPrefixes,
  normalizePatientSearchText,
} from './patient_search_index.mjs';

function arraysEqual(left, right) {
  return Array.isArray(left)
    && left.length === right.length
    && left.every((value, index) => value === right[index]);
}

export async function backfillPatientSearchPrefixes({
  db,
  dryRun = true,
  pageSize = 200,
  logger = console,
}) {
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 500) {
    throw new RangeError('pageSize must be an integer between 1 and 500.');
  }

  const stats = { scanned: 0, unchanged: 0, updated: 0, malformed: 0 };
  const writer = dryRun ? null : db.bulkWriter();
  let lastDocument;

  try {
    while (true) {
      let query = db
        .collection('patients')
        .orderBy(FieldPath.documentId())
        .limit(pageSize);
      if (lastDocument) query = query.startAfter(lastDocument);

      const snapshot = await query.get();
      if (snapshot.empty) break;

      for (const document of snapshot.docs) {
        stats.scanned += 1;
        const name = document.data().name;
        if (typeof name !== 'string' || !normalizePatientSearchText(name)) {
          stats.malformed += 1;
          logger.error(`Malformed patient name: ${document.id}`);
          continue;
        }

        const expectedName = normalizePatientSearchText(name);
        const expectedPrefixes = buildPatientSearchPrefixes(name);
        const data = document.data();
        if (
          data.nameLowercase === expectedName
          && arraysEqual(data.searchPrefixes, expectedPrefixes)
        ) {
          stats.unchanged += 1;
          continue;
        }

        stats.updated += 1;
        if (writer) {
          writer.update(document.ref, {
            nameLowercase: expectedName,
            searchPrefixes: expectedPrefixes,
          });
        }
      }

      lastDocument = snapshot.docs.at(-1);
      if (snapshot.size < pageSize) break;
    }
  } finally {
    if (writer) await writer.close();
  }

  logger.info(JSON.stringify({ mode: dryRun ? 'dry-run' : 'apply', ...stats }));
  return stats;
}

function parseArguments(argumentsList) {
  const apply = argumentsList.includes('--apply');
  const projectIndex = argumentsList.indexOf('--project');
  const projectId = projectIndex >= 0 ? argumentsList[projectIndex + 1] : undefined;
  if (!projectId) {
    throw new Error('Usage: node backfill_patient_search_prefixes.mjs --project <id> [--apply]');
  }
  return { apply, projectId };
}

async function main() {
  const { apply, projectId } = parseArguments(process.argv.slice(2));
  const options = process.env.FIRESTORE_EMULATOR_HOST
    ? { projectId }
    : { credential: applicationDefault(), projectId };
  const app = initializeApp(options, 'patient-search-migration');
  await backfillPatientSearchPrefixes({
    db: getFirestore(app),
    dryRun: !apply,
  });
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
```

- [ ] **Step 8: Run all migration tests and verify GREEN**

Run:

```bash
npm --prefix firebase exec firebase -- emulators:exec --project demo-karia-migration --only firestore "npm --prefix firebase run test:migration"
```

Expected: shared fixture, dry-run, pagination, malformed-record, and idempotency tests all pass.

- [ ] **Step 9: Commit migration tooling when commits are authorized**

```bash
git add firebase/scripts firebase/test/patient_search_index.test.mjs firebase/test/backfill_patient_search_prefixes.test.mjs
git commit -m "chore: add patient search index migration"
```

---

### Task 9: Full Verification, Migration, Deployment, and Real-App E2E

**Files:**
- Verify all files above; no new production code is planned in this task.

- [ ] **Step 1: Format all Dart files**

Run:

```bash
dart format lib test
```

Expected: formatter exits successfully.

- [ ] **Step 2: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run the complete Flutter suite with coverage**

Run:

```bash
flutter test --coverage
python3 - <<'PY'
from pathlib import Path
lines_found = 0
lines_hit = 0
for line in Path('coverage/lcov.info').read_text().splitlines():
    if line.startswith('LF:'):
        lines_found += int(line[3:])
    elif line.startswith('LH:'):
        lines_hit += int(line[3:])
coverage = 100 if lines_found == 0 else (lines_hit / lines_found * 100)
print(f'Line coverage: {coverage:.2f}%')
raise SystemExit(0 if coverage >= 80 else 1)
PY
```

Expected: all Flutter tests pass and repository-wide line coverage is at least 80%. If the current baseline is lower, do not weaken or remove tests; add focused tests for uncovered behavior until the 80% threshold passes before marking implementation complete.

- [ ] **Step 4: Run all Firebase emulator tests**

Run:

```bash
npm --prefix firebase exec firebase -- emulators:exec --project demo-karia-clinic --only firestore "npm --prefix firebase test"
```

Expected: rules, shared-fixture, and migration tests pass.

- [ ] **Step 5: Run mandatory code reviews**

Dispatch the `code-reviewer`, `flutter-reviewer`, and `security-reviewer` agents in parallel over the final diff. Address every CRITICAL and HIGH finding, and all actionable MEDIUM findings, then rerun Steps 1–4.

- [ ] **Step 6: Review migration dry-run against production**

This is read-only but accesses production metadata. Use Application Default Credentials without storing credentials in the repository:

```bash
node firebase/scripts/backfill_patient_search_prefixes.mjs --project clinic-app-b2569
```

Expected: JSON reports `mode: "dry-run"` with scanned, unchanged, updated, and malformed counts. Review every malformed document ID before applying changes.

- [ ] **Step 7: Apply the approved production migration**

Only after the dry-run counts are reviewed and the user explicitly approves the production write:

```bash
node firebase/scripts/backfill_patient_search_prefixes.mjs --project clinic-app-b2569 --apply
node firebase/scripts/backfill_patient_search_prefixes.mjs --project clinic-app-b2569
```

Expected: the apply run completes successfully; the second dry-run reports `updated: 0` and `malformed: 0` for all valid records.

- [ ] **Step 8: Deploy indexes and rules**

Deployment is outward-facing and requires explicit user approval immediately before execution:

```bash
npm --prefix firebase exec firebase -- deploy --project clinic-app-b2569 --only firestore:indexes,firestore:rules
```

Expected: rules deploy successfully and indexes reach a ready state. Do not switch production search before the patient index is ready.

- [ ] **Step 9: Run the real application and verify the critical flow**

Invoke the `run` skill and launch the actual Flutter app. Verify this E2E journey against Firebase:

1. Sign in as Doctor A.
2. Register `Raymond Kip Yegon`.
3. Record a consultation and note Doctor A attribution.
4. Sign out.
5. Sign in as Doctor B.
6. Search `yEgO` and confirm the patient appears.
7. Search `KIP Y` and confirm the same patient appears.
8. Open consultation history and confirm Doctor A remains displayed.
9. Edit the diagnosis as Doctor B and save.
10. Reopen the consultation and confirm the edit is visible while Doctor A remains the recording doctor.
11. Confirm an unauthenticated session cannot query clinical records through emulator rules tests.

Expected: all steps succeed with no permission error, missing record, attribution change, or client-side full-collection migration.

- [ ] **Step 10: Inspect the final diff and status**

Run:

```bash
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors; only intended source, test, Firebase, lock, spec, and plan files are changed. Preserve all unrelated pre-existing working-tree changes.

- [ ] **Step 11: Commit final review fixes when commits are authorized**

Stage only files from this plan, never all pre-existing modifications blindly:

```bash
git add lib/utils/patient_search_index.dart lib/models/patient.dart lib/models/consultation.dart lib/services/patient_service.dart lib/services/consultation_service.dart lib/screens/patient_lookup_screen.dart lib/screens/edit_consultation_screen.dart test/fixtures/patient_search_cases.json test/patient_search_index_test.dart test/patient_name_matcher_test.dart test/patient_biodata_regression_test.dart test/services test/screens/patient_lookup_screen_test.dart test/screens/edit_consultation_screen_test.dart pubspec.yaml pubspec.lock firestore.rules firestore.indexes.json firebase.json firebase/package.json firebase/package-lock.json firebase/scripts firebase/test docs/superpowers/specs/2026-09-16-firebase-patient-search-and-sharing-design.md docs/superpowers/plans/2026-09-16-firebase-patient-search-and-sharing.md
git commit -m "feat: share searchable patient records across doctors"
```

Expected: commit succeeds only if the user has authorized committing. Do not push unless separately requested.

---

## Plan Self-Review

- **Spec coverage:** Tasks 1–4 cover canonical any-name-part search and safe lookup errors; Tasks 5–6 preserve original attribution during shared editing; Task 7 covers authenticated shared access, owner-only consultation deletion, public pre-auth doctor lookup, counters, indexes, and rules tests; Task 8 covers dry-run, batching, malformed records, and idempotent migration; Task 9 covers coverage, reviews, production gates, deployment, and E2E verification.
- **Placeholder scan:** No TBD, TODO, deferred implementation, or undefined helper remains. Production migration and deployment are explicit approval gates, not placeholders.
- **Type consistency:** Dart uses `normalizePatientSearchText`, `buildPatientSearchPrefixes`, `searchPrefixes`, `nameLowercase`, `toUpdateMap`, and injected callback signatures consistently. JavaScript uses the same field names and shared fixtures.
- **Scope:** The plan stays within the approved single-clinic architecture. It does not add multi-clinic tenancy, fuzzy search, external search infrastructure, or unrelated authentication redesign.
