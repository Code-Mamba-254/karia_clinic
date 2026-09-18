import 'package:clinic_app/services/patient_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('patientNameMatches', () {
    test('matches a prefix starting at any name component', () {
      expect(patientNameMatches('Mary Jane Doe', 'jane'), isTrue);
      expect(patientNameMatches('Mary Jane Doe', 'do'), isTrue);
    });

    test('normalizes case and repeated whitespace', () {
      expect(patientNameMatches('  Mary   Jane Doe  ', ' JANE   d '), isTrue);
    });

    test('only starts matches at component boundaries', () {
      expect(patientNameMatches('Mary Jane Doe', 'ary'), isFalse);
      expect(patientNameMatches('Mary Jane Doe', 'ane d'), isFalse);
    });

    test('does not match an empty normalized search', () {
      expect(patientNameMatches('Mary Jane Doe', ''), isFalse);
      expect(patientNameMatches('Mary Jane Doe', ' \t\n '), isFalse);
    });
  });
}
