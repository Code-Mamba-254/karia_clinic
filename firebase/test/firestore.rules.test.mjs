import { readFileSync } from 'node:fs';
import { after, afterEach, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const projectId = 'demo-karia-clinic-rules';
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(
        new URL('../../firestore.rules', import.meta.url),
        'utf8',
      ),
    },
  });
});

afterEach(async () => environment.clearFirestore());
after(async () => environment.cleanup());

async function seedConsultation() {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'consultations/consultation-1'), {
      patientId: 'patient-1',
      doctorId: 'doctor-a',
      doctorEmail: 'doctor-a@example.com',
      doctorName: 'Doctor A',
      diagnosis: 'Original',
      createdAt: new Date('2026-09-16T10:00:00Z'),
    });
  });
}

describe('clinical record access', () => {
  test('denies unauthenticated patient reads', async () => {
    const db = environment.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'patients/patient-1')));
  });

  test('allows one authenticated doctor to read another doctor record', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'patients/patient-1'), {
        name: 'Jane Doe',
      });
    });
    const db = environment.authenticatedContext('doctor-b').firestore();
    await assertSucceeds(getDoc(doc(db, 'patients/patient-1')));
  });

  test('allows creating a consultation when doctorEmail matches the signed-in account', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'patients/patient-1'), {
        name: 'Jane Doe',
      });
    });
    const db = environment
      .authenticatedContext('doctor-a', { email: 'doctor-a@example.com' })
      .firestore();
    await assertSucceeds(
      setDoc(doc(db, 'consultations/consultation-new'), {
        patientId: 'patient-1',
        doctorId: 'doctor-a',
        doctorEmail: 'doctor-a@example.com',
        doctorName: 'Doctor A',
        diagnosis: 'New',
        createdAt: new Date('2026-09-16T10:00:00Z'),
      }),
    );
  });

  test('rejects creating a consultation with a spoofed doctorEmail', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'patients/patient-1'), {
        name: 'Jane Doe',
      });
    });
    const db = environment
      .authenticatedContext('doctor-a', { email: 'doctor-a@example.com' })
      .firestore();
    await assertFails(
      setDoc(doc(db, 'consultations/consultation-spoofed'), {
        patientId: 'patient-1',
        doctorId: 'doctor-a',
        doctorEmail: 'someone-else@example.com',
        doctorName: 'Doctor A',
        diagnosis: 'New',
        createdAt: new Date('2026-09-16T10:00:00Z'),
      }),
    );
  });

  test('rejects creating a consultation for a patient that does not exist', async () => {
    const db = environment
      .authenticatedContext('doctor-a', { email: 'doctor-a@example.com' })
      .firestore();
    await assertFails(
      setDoc(doc(db, 'consultations/consultation-orphan'), {
        patientId: 'missing-patient',
        doctorId: 'doctor-a',
        doctorEmail: 'doctor-a@example.com',
        doctorName: 'Doctor A',
        diagnosis: 'New',
        createdAt: new Date('2026-09-16T10:00:00Z'),
      }),
    );
  });

  test('allows another doctor to edit clinical fields only', async () => {
    await seedConsultation();
    const db = environment.authenticatedContext('doctor-b').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'consultations/consultation-1'), {
        diagnosis: 'Updated by Doctor B',
      }),
    );
  });

  test('rejects changing original attribution', async () => {
    await seedConsultation();
    const db = environment.authenticatedContext('doctor-b').firestore();
    await assertFails(
      updateDoc(doc(db, 'consultations/consultation-1'), {
        doctorId: 'doctor-b',
      }),
    );
  });

  test('allows only the original doctor to delete a consultation', async () => {
    await seedConsultation();
    const doctorB = environment.authenticatedContext('doctor-b').firestore();
    await assertFails(deleteDoc(doc(doctorB, 'consultations/consultation-1')));

    const doctorA = environment.authenticatedContext('doctor-a').firestore();
    await assertSucceeds(deleteDoc(doc(doctorA, 'consultations/consultation-1')));
  });

  test('allows public doctor directory reads but denies client writes', async () => {
    const publicDb = environment.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(publicDb, 'doctors/doctor-a')));

    const doctorDb = environment.authenticatedContext('doctor-a').firestore();
    await assertFails(setDoc(doc(doctorDb, 'doctors/doctor-a'), { active: true }));
  });

  test('requires authentication for the shared counter', async () => {
    const publicDb = environment.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(publicDb, 'counters/patient_counter')));

    const doctorDb = environment.authenticatedContext('doctor-a').firestore();
    await assertSucceeds(
      setDoc(doc(doctorDb, 'counters/patient_counter'), { value: 1 }),
    );
  });

  test('rejects a non-incrementing counter update', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'counters/patient_counter'), {
        value: 5,
      });
    });
    const doctorDb = environment.authenticatedContext('doctor-a').firestore();

    await assertFails(
      updateDoc(doc(doctorDb, 'counters/patient_counter'), { value: 7 }),
    );
    await assertSucceeds(
      updateDoc(doc(doctorDb, 'counters/patient_counter'), { value: 6 }),
    );
  });
});
