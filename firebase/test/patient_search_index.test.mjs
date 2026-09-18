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
