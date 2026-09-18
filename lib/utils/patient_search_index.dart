String normalizePatientSearchText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

List<String> buildPatientSearchPrefixes(String patientName) {
  final normalizedName = normalizePatientSearchText(patientName);
  if (normalizedName.isEmpty) {
    return const <String>[];
  }

  const spaceRune = 0x20;
  final runes = normalizedName.runes.toList(growable: false);
  final componentStarts = <int>[0];
  for (var index = 0; index < runes.length; index++) {
    if (runes[index] == spaceRune) {
      componentStarts.add(index + 1);
    }
  }

  final prefixes = <String>{};
  for (final start in componentStarts) {
    for (var end = start + 1; end <= runes.length; end++) {
      if (runes[end - 1] != spaceRune) {
        prefixes.add(String.fromCharCodes(runes.sublist(start, end)));
      }
    }
  }

  return List<String>.unmodifiable(prefixes);
}
