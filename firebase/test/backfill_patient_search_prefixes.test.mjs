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
