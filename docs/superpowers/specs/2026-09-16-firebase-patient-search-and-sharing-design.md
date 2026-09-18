# Firebase Patient Search and Shared Records Design

**Date:** 2026-09-16
**Status:** Approved

## Objective

Ensure that patient lookup is case-insensitive and can match any part of a patient's name directly in Cloud Firestore. Ensure that every authenticated doctor using the Karia Clinic Firebase project can view and edit patient records and consultations regardless of which doctor originally recorded them.

## Scope

This design covers:

- case-insensitive patient-name search;
- matching prefixes of first, middle, and family names;
- migration of existing patient documents;
- clinic-wide patient and consultation visibility;
- cross-doctor consultation editing;
- preservation of the original recording doctor's attribution;
- version-controlled Firestore rules and indexes;
- unit, integration, widget, migration, and rules tests.

This Firebase project represents Karia Clinic only. Multi-clinic tenancy, fuzzy matching, typo correction, phonetic matching, and an external search service are outside this scope.

## Architecture

### Collection structure

Retain the existing top-level collections:

- `patients/{patientId}`
- `consultations/{consultationId}`
- `doctors/{doctorId}`
- `counters/patient_counter`

The Firebase project is the clinic boundary. Patient and consultation reads will not be filtered by the current doctor's ID.

### Authentication boundary

Any authenticated Firebase Authentication account can access Karia Clinic clinical records. Unauthenticated users cannot read or write patients, consultations, or the shared patient-number counter.

This policy intentionally does not require a matching active document in the `doctors` collection. Firestore rules must therefore use `request.auth != null` as the clinical-data authorization condition.

## Case-Insensitive Patient Search

### Canonical normalization

A single pure normalization utility will be used by patient creation, patient editing, search, migration, and tests. It will:

1. trim leading and trailing whitespace;
2. replace repeated internal whitespace with one space;
3. convert text to lowercase.

The original patient name remains unchanged for display.

### Search-prefix index

Each patient document will contain a `searchPrefixes` array generated at every name-component boundary. For each boundary, the index contains progressively longer prefixes through the rest of the normalized name.

For the name `Raymond Kip Yegon`, representative values include:

- `r`, `ra`, `ray`, through `raymond kip yegon`;
- `k`, `ki`, `kip`, through `kip yegon`;
- `y`, `ye`, through `yegon`.

Duplicates are removed before serialization. Prefix generation is deterministic so migration and normal application writes produce identical arrays.

The lookup service normalizes the complete user query and performs an `arrayContains` query against `searchPrefixes`. Consequently, `YEGo` finds `Raymond Yegon`, `Kip Y` finds `Raymond Kip Yegon`, and capitalization does not affect matching. A query must start at a name-component boundary; fuzzy, typo-tolerant, and non-contiguous matching remain outside scope.

Empty or whitespace-only input produces an empty result without issuing a Firestore query.

### Write consistency

Patient creation and editing write `searchPrefixes` atomically with the rest of the patient fields. The existing display `name` remains the source of truth; `searchPrefixes` is a derived index.

The older `nameLowercase` field may remain temporarily for backward compatibility during rollout, but patient lookup will use `searchPrefixes`. It can be removed in a later cleanup after deployment and migration have been verified.

## Shared Patient and Consultation Records

### Patients

Patient queries remain project-wide and contain no creator or doctor filter. Any authenticated doctor can find, view, and update any patient.

### Consultations

Consultation history remains filtered by `patientId`, not by the current doctor's ID. Any authenticated doctor can view and edit any consultation for the selected patient.

The fields `doctorId`, `doctorName`, and `doctorEmail` represent the original recording doctor. Editing a consultation must preserve these fields, including when another doctor performs the edit. Cross-doctor edits do not transfer authorship.

Any authenticated doctor may view or edit another doctor's consultation. Only the original recording doctor may delete that consultation; selecting “view and edit” does not grant cross-doctor deletion. Patient deletion is outside this feature's scope.

## Firestore Rules and Indexes

The repository will include Firestore rules and index configuration referenced by `firebase.json`.

Rules will enforce the following behavior:

- unauthenticated users cannot read or write clinical records;
- authenticated users can read, create, and update patients;
- authenticated users can read, create, and update consultations;
- consultation deletion is allowed only when `resource.data.doctorId == request.auth.uid`;
- authenticated users can use the shared patient counter;
- the doctor directory remains publicly readable because the existing login dropdown loads it before authentication; doctor-directory writes require authentication.

The `searchPrefixes` query uses Firestore's array index. Required index configuration will be checked in rather than relying on undocumented console-only settings. Existing consultation query indexes will also be captured if required by the emulator or deployment tooling.

## Existing-Data Migration

A one-time administrative migration will backfill `searchPrefixes` for existing patient documents.

The migration will:

- use trusted administrative credentials rather than client permissions;
- process documents in bounded batches;
- support dry-run and apply modes;
- be idempotent and safe to rerun;
- skip documents that already contain the expected prefixes;
- report missing, empty, or invalid patient names;
- report scanned, unchanged, updated, and malformed counts;
- stop with a non-zero exit status on an unrecoverable error.

The current client-side lazy backfill will be removed. Patient search must not trigger a full collection read or hidden bulk updates from each doctor's device.

Deployment order:

1. add the normalization and prefix-generation tests;
2. update new and edited patient writes;
3. add and validate Firestore rules and indexes;
4. deploy write-path compatibility;
5. dry-run and apply the administrative migration;
6. verify that no valid patients lack `searchPrefixes`;
7. switch patient lookup to the new query;
8. run cross-doctor and rules verification;
9. remove the client-side backfill.

## Error Handling

- Search errors produce a user-friendly message while retaining enough state for retry.
- Permission-denied errors tell the user to sign in again or indicate that Firebase rules have not been deployed correctly.
- Missing search prefixes are reported as migration defects rather than repaired silently by the Flutter client.
- Patient and consultation update failures retain entered form data and present an actionable error.
- Migration failures include document context in logs without exposing credentials.
- No operation may silently replace the original consultation author's identity.

## Testing Strategy

Development follows test-driven development: add a failing test, verify the failure, implement the smallest change, then refactor and rerun the suite.

### Unit tests

- canonical lowercase and whitespace normalization;
- prefix generation for first, middle, and family names;
- duplicate-prefix removal;
- mixed capitalization;
- punctuation and non-ASCII names according to Dart lowercase behavior;
- empty and whitespace-only input;
- patient serialization for create and update;
- preservation of consultation attribution during edits.

### Service and integration tests

- `YEGo` finds `Raymond Yegon`;
- first-, middle-, and family-name prefixes return the patient;
- nonmatching prefixes return no patient;
- empty searches issue no query;
- Doctor A creates a patient and Doctor B can find and update it;
- Doctor A records a consultation and Doctor B can view and edit it;
- Doctor A remains the displayed author after Doctor B edits;
- migration dry-run makes no writes;
- migration apply mode is idempotent and handles multiple batches;
- malformed legacy patient documents are reported.

### Firestore rules tests

Using the Firestore emulator:

- unauthenticated access to patients and consultations is denied;
- two different authenticated accounts can access the same patient;
- two different authenticated accounts can access and update the same consultation;
- a different doctor cannot delete the original doctor's consultation;
- the original doctor can delete their own consultation;
- the shared counter remains available only after authentication;
- query shapes used by the Flutter services are accepted by the rules.

### Widget tests

- mixed-case input is passed through the search flow;
- search failures show a useful message;
- consultation cards retain the original doctor's display information after another doctor edits the record.

## Success Criteria

The work is complete when:

1. any capitalization of a first-, middle-, or family-name prefix returns the same matching patients from Firestore;
2. no patient search performs a full collection download or client-side bulk migration;
3. a patient created by one authenticated doctor is visible to another authenticated doctor;
4. a consultation created by one doctor is visible and editable by another authenticated doctor;
5. cross-doctor edits preserve original doctor attribution;
6. unauthenticated clinical-data access is denied;
7. all existing valid patient records have the new search index;
8. automated tests cover normalization, querying, migration, cross-doctor access, attribution, and Firestore rules;
9. the full Flutter test suite and relevant Firebase emulator tests pass.
