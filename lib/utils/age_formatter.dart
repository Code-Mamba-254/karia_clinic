int calculateAgeInYears(DateTime dateOfBirth, {DateTime? asOf}) {
  final referenceDate = _dateOnly(asOf ?? DateTime.now());
  final birthDate = _dateOnly(dateOfBirth);
  if (birthDate.isAfter(referenceDate)) {
    throw ArgumentError.value(
      dateOfBirth,
      'dateOfBirth',
      'Date of birth cannot be in the future.',
    );
  }
  return _completedYears(birthDate, referenceDate);
}

String formatPatientAge(DateTime dateOfBirth, {DateTime? asOf}) {
  final referenceDate = _dateOnly(asOf ?? DateTime.now());
  final birthDate = _dateOnly(dateOfBirth);

  if (birthDate.isAfter(referenceDate)) {
    throw ArgumentError.value(
      dateOfBirth,
      'dateOfBirth',
      'Date of birth cannot be in the future.',
    );
  }

  final years = _completedYears(birthDate, referenceDate);
  if (years > 0) {
    return _formatUnit(years, 'year');
  }

  final months = _completedMonths(birthDate, referenceDate);
  if (months > 0) {
    return _formatUnit(months, 'month');
  }

  final days = referenceDate.difference(birthDate).inDays;
  if (days < 7) {
    return _formatUnit(days, 'day');
  }

  return _formatUnit(days ~/ 7, 'week');
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _completedYears(DateTime birthDate, DateTime referenceDate) {
  final hadBirthday =
      referenceDate.month > birthDate.month ||
      (referenceDate.month == birthDate.month &&
          referenceDate.day >= birthDate.day);
  return referenceDate.year - birthDate.year - (hadBirthday ? 0 : 1);
}

int _completedMonths(DateTime birthDate, DateTime referenceDate) {
  var months =
      (referenceDate.year - birthDate.year) * 12 +
      referenceDate.month -
      birthDate.month;
  if (referenceDate.day < birthDate.day) {
    months--;
  }
  return months;
}

String _formatUnit(int value, String unit) {
  final suffix = value == 1 ? unit : '${unit}s';
  return '$value $suffix';
}
