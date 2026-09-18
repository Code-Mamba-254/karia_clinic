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
