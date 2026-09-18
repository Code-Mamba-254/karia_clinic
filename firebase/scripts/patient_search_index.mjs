export function normalizePatientSearchText(value) {
  return value.trim().replace(/\s+/gu, ' ').toLowerCase();
}

export function buildPatientSearchPrefixes(patientName) {
  const normalizedName = normalizePatientSearchText(patientName);
  if (!normalizedName) return [];

  const codePoints = [...normalizedName];
  const componentStarts = [0];
  for (let index = 0; index < codePoints.length; index += 1) {
    if (codePoints[index] === ' ') {
      componentStarts.push(index + 1);
    }
  }

  const prefixes = new Set();
  for (const start of componentStarts) {
    for (let end = start + 1; end <= codePoints.length; end += 1) {
      if (codePoints[end - 1] !== ' ') {
        prefixes.add(codePoints.slice(start, end).join(''));
      }
    }
  }
  return [...prefixes];
}
