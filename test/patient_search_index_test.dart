import 'dart:convert';
import 'dart:io';

import 'package:clinic_app/utils/patient_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> searchCases;

  setUpAll(() {
    final fixtureFile = File('test/fixtures/patient_search_cases.json');
    final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as List;
    searchCases = fixtureJson.cast<Map<String, dynamic>>();
  });

  group('normalizePatientSearchText', () {
    test('normalizes every fixture name', () {
      for (final searchCase in searchCases) {
        expect(
          normalizePatientSearchText(searchCase['name'] as String),
          searchCase['normalized'],
          reason: 'Failed to normalize "${searchCase['name']}"',
        );
      }
    });
  });

  group('buildPatientSearchPrefixes', () {
    test('contains normalized matches and excludes misses', () {
      for (final searchCase in searchCases) {
        final prefixes = buildPatientSearchPrefixes(
          searchCase['name'] as String,
        );

        for (final match in (searchCase['matches'] as List).cast<String>()) {
          expect(
            prefixes,
            contains(normalizePatientSearchText(match)),
            reason: 'Expected "${searchCase['name']}" to match "$match"',
          );
        }
        for (final miss in (searchCase['misses'] as List).cast<String>()) {
          expect(
            prefixes,
            isNot(contains(normalizePatientSearchText(miss))),
            reason: 'Expected "${searchCase['name']}" not to match "$miss"',
          );
        }
      }
    });

    test('returns exact prefixes in deterministic insertion order', () {
      expect(
        buildPatientSearchPrefixes('Al Bo'),
        <String>['a', 'al', 'al b', 'al bo', 'b', 'bo'],
      );
    });

    test('builds non-BMP prefixes only on Unicode scalar boundaries', () {
      expect(
        buildPatientSearchPrefixes('😀 A'),
        <String>['😀', '😀 a', 'a'],
      );
    });

    test('returns an immutable empty result for whitespace-only input', () {
      final prefixes = buildPatientSearchPrefixes(' \t\n ');

      expect(prefixes, isEmpty);
      expect(() => prefixes.add('a'), throwsUnsupportedError);
    });

    test('returns an immutable non-empty result', () {
      final prefixes = buildPatientSearchPrefixes('Al');

      expect(() => prefixes.add('ali'), throwsUnsupportedError);
    });

    test('has no duplicates or whitespace-ending prefixes', () {
      final prefixes = buildPatientSearchPrefixes('Ann Ann');

      expect(prefixes.toSet(), hasLength(prefixes.length));
      expect(prefixes.where((prefix) => prefix.endsWith(' ')), isEmpty);
    });
  });
}
