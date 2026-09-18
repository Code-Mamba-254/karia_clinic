import 'package:clinic_app/enums/sex.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:flutter_test/flutter_test.dart';

const _defaultBirthDate = Object();

void main() {
  Patient buildPatient({Object? dateOfBirth = _defaultBirthDate}) {
    return Patient(
      id: 'patient-1',
      clinicNumber: 'CLN-2025-000001',
      name: 'Original Name',
      ageInYears: 35,
      dateOfBirth: identical(dateOfBirth, _defaultBirthDate)
          ? DateTime(1990, 1, 2)
          : dateOfBirth as DateTime?,
      sex: Sex.male,
      residence: 'Original Residence',
      idNumber: '12345678',
      phoneNumber: '0700000000',
      createdAt: DateTime(2025, 4, 3, 12, 30),
    );
  }

  test('copyWith returns an immutable biodata update', () {
    final original = buildPatient();

    final updated = original.copyWith(
      name: 'Updated Name',
      ageInYears: 24,
      dateOfBirth: DateTime(2001, 5, 6),
      sex: Sex.female,
      residence: 'Updated Residence',
      idNumber: '87654321',
      phoneNumber: '0711111111',
    );

    expect(updated, isNot(same(original)));
    expect(
      [
        updated.name,
        updated.ageInYears,
        updated.dateOfBirth,
        updated.sex,
        updated.residence,
        updated.idNumber,
        updated.phoneNumber,
      ],
      [
        'Updated Name',
        24,
        DateTime(2001, 5, 6),
        Sex.female,
        'Updated Residence',
        '87654321',
        '0711111111',
      ],
    );
    expect(original.name, 'Original Name');
    expect(original.ageInYears, 35);
    expect(original.dateOfBirth, DateTime(1990, 1, 2));
    expect(original.sex, Sex.male);
    expect(original.residence, 'Original Residence');
    expect(original.idNumber, '12345678');
    expect(original.phoneNumber, '0700000000');
  });

  test('copyWith can explicitly clear nullable biodata fields', () {
    final original = buildPatient();

    final cleared = original.copyWith(
      dateOfBirth: null,
      idNumber: null,
      phoneNumber: null,
    );

    expect(cleared.dateOfBirth, isNull);
    expect(cleared.idNumber, isNull);
    expect(cleared.phoneNumber, isNull);
    expect(original.dateOfBirth, DateTime(1990, 1, 2));
    expect(original.idNumber, '12345678');
    expect(original.phoneNumber, '0700000000');
  });

  test('persistence maps include canonical patient search fields', () {
    final patient = buildPatient().copyWith(name: '  Jane   DOE  ');

    final persistenceMaps = [patient.toMap(), patient.toUpdateMap()];
    for (final persistenceMap in persistenceMaps) {
      expect(
        persistenceMap['searchPrefixes'],
        containsAll(<String>['j', 'jane doe', 'd', 'doe']),
      );
      expect(persistenceMap['nameLowercase'], 'jane doe');
    }
  });

  test('toUpdateMap retains legacy age and an explicit null DOB', () {
    final legacyPatient = buildPatient(
      dateOfBirth: null,
    ).copyWith(ageInYears: 7);

    final update = legacyPatient.toUpdateMap();

    expect(update['ageInYears'], 7);
    expect(update, containsPair('dateOfBirth', null));
  });

  test('fromMap reads the canonical DOB emitted by toMap', () {
    final original = buildPatient(dateOfBirth: DateTime(1990, 1, 2));
    final persistenceMap = original.toMap();

    final restored = Patient.fromMap('restored-patient', persistenceMap);

    expect(persistenceMap['dateOfBirth'], '1990-01-02');
    expect(restored.dateOfBirth, DateTime(1990, 1, 2));
  });

  test('fromMap reads the canonical DOB emitted by toUpdateMap', () {
    final original = buildPatient(dateOfBirth: DateTime(2001, 11, 9));
    final completeUpdateMap = {...original.toMap(), ...original.toUpdateMap()};

    final restored = Patient.fromMap('restored-patient', completeUpdateMap);

    expect(completeUpdateMap['dateOfBirth'], '2001-11-09');
    expect(restored.dateOfBirth, DateTime(2001, 11, 9));
  });

  test('fromMap rejects an impossible DOB and retains legacy age', () {
    final persistenceMap = {
      ...buildPatient(dateOfBirth: null).toMap(),
      'ageInYears': 7,
      'dateOfBirth': '2025-02-30',
    };

    final restored = Patient.fromMap('restored-patient', persistenceMap);

    expect(restored.dateOfBirth, isNull);
    expect(restored.ageInYears, 7);
  });
}
