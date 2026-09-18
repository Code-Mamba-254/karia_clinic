import 'package:clinic_app/utils/age_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPatientAge', () {
    test('formats a two-week-old patient in weeks', () {
      expect(
        formatPatientAge(DateTime(2026, 9, 1), asOf: DateTime(2026, 9, 15)),
        '2 weeks',
      );
    });

    test('formats a six-month-old patient in months', () {
      expect(
        formatPatientAge(DateTime(2026, 3, 15), asOf: DateTime(2026, 9, 15)),
        '6 months',
      );
    });

    test('formats a forty-year-old patient in years', () {
      expect(
        formatPatientAge(DateTime(1986, 9, 15), asOf: DateTime(2026, 9, 15)),
        '40 years',
      );
    });

    test('uses singular units', () {
      expect(
        formatPatientAge(DateTime(2026, 9, 8), asOf: DateTime(2026, 9, 15)),
        '1 week',
      );
      expect(
        formatPatientAge(DateTime(2026, 8, 15), asOf: DateTime(2026, 9, 15)),
        '1 month',
      );
      expect(
        formatPatientAge(DateTime(2025, 9, 15), asOf: DateTime(2026, 9, 15)),
        '1 year',
      );
    });

    test('rejects a future date of birth', () {
      expect(
        () => formatPatientAge(
          DateTime(2026, 9, 16),
          asOf: DateTime(2026, 9, 15),
        ),
        throwsArgumentError,
      );
    });
  });
}
