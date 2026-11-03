import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  type Firestore,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

type Fields = Record<string, unknown>;

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-hopin',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

// The test library types its Firestore as the older compat API; at runtime it
// is the same instance the modular functions take.
function rider(uid: string): Firestore {
  return env.authenticatedContext(uid, { rider: true }).firestore() as unknown as Firestore;
}

function stranger(uid: string): Firestore {
  return env.authenticatedContext(uid).firestore() as unknown as Firestore;
}

function signedOut(): Firestore {
  return env.unauthenticatedContext().firestore() as unknown as Firestore;
}

function profile(changes: Fields = {}): Fields {
  return {
    name: 'Rider One',
    photoUrl: null,
    language: 'en',
    updatedAt: serverTimestamp(),
    ...changes,
  };
}

// Writes test data as an admin, past the rules.
async function seed(path: string, data: Fields): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Firestore;
    await setDoc(doc(db, path), data);
  });
}

describe('who gets in', () => {
  it('turns away signed-out visitors', async () => {
    await seed('people/r1', profile({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(signedOut(), 'people/r1')));
    await assertFails(setDoc(doc(signedOut(), 'people/r1'), profile()));
  });

  it('turns away signed-in accounts without the rider claim', async () => {
    await seed('people/r1', profile({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(stranger('s1'), 'people/r1')));
    await assertFails(setDoc(doc(stranger('s1'), 'people/s1'), profile()));
  });

  it('turns away a claim that is not exactly true', async () => {
    const almost = env
      .authenticatedContext('s2', { rider: 'true' })
      .firestore() as unknown as Firestore;
    await assertFails(setDoc(doc(almost, 'people/s2'), profile()));
  });

  it('keeps every other collection closed, even to riders', async () => {
    await seed('rides/x', { a: 1 });
    await assertFails(getDoc(doc(rider('r1'), 'rides/x')));
    await assertFails(setDoc(doc(rider('r1'), 'config/riders'), { uids: ['r1'] }));
  });
});

function place(changes: Fields = {}): Fields {
  return {
    name: 'Uni',
    kind: 'uni',
    lat: 6.9733,
    lng: 79.9157,
    placeEn: 'University',
    placeTa: null,
    placeSi: 'විශ්වවිද්‍යාලය',
    updatedAt: serverTimestamp(),
    deletedAt: null,
    ...changes,
  };
}

describe('places', () => {
  it('lets a rider keep their own places', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/places/p1'), place()));
    await assertSucceeds(getDoc(doc(db, 'people/r1/places/p1')));
    await assertSucceeds(updateDoc(doc(db, 'people/r1/places/p1'), { name: 'Campus', updatedAt: serverTimestamp() }));
  });

  it("keeps places private, even from the other rider", async () => {
    await seed('people/r1/places/p1', place({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(rider('r2'), 'people/r1/places/p1')));
    await assertFails(setDoc(doc(rider('r2'), 'people/r1/places/p2'), place()));
  });

  it('needs the rider claim, even for your own', async () => {
    await assertFails(setDoc(doc(stranger('r1'), 'people/r1/places/p1'), place()));
  });

  it('removes by marking, never by deleting', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/places/p1'), place()));
    await assertSucceeds(
      updateDoc(doc(db, 'people/r1/places/p1'), { deletedAt: serverTimestamp(), updatedAt: serverTimestamp() }),
    );
    await assertFails(deleteDoc(doc(db, 'people/r1/places/p1')));
  });

  it('checks every field', async () => {
    const db = rider('r1');
    const bad: Fields[] = [
      { kind: 'school' },
      { name: '' },
      { name: 'x'.repeat(41) },
      { lat: 91 },
      { lng: -181 },
      { lat: '6.9' },
      { placeSi: 'x'.repeat(201) },
      { colour: 'amber' },
      { updatedAt: Timestamp.now() },
      { deletedAt: Timestamp.now() },
    ];
    for (const changes of bad) {
      await assertFails(setDoc(doc(db, 'people/r1/places/p1'), place(changes)));
    }
    const { lat: _lat, ...noLat } = place();
    await assertFails(setDoc(doc(db, 'people/r1/places/p1'), noLat));
  });
});

describe('people', () => {
  it('lets a rider create and update their own profile', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1'), profile()));
    await assertSucceeds(
      updateDoc(doc(db, 'people/r1'), { language: 'ta', updatedAt: serverTimestamp() }),
    );
  });

  it('lets riders read each other', async () => {
    await seed('people/r2', profile({ name: 'Rider Two', updatedAt: Timestamp.now() }));
    await assertSucceeds(getDoc(doc(rider('r1'), 'people/r2')));
  });

  it("refuses writing someone else's profile", async () => {
    await assertFails(setDoc(doc(rider('r1'), 'people/r2'), profile()));
  });

  it('refuses deleting a profile, even your own', async () => {
    await seed('people/r1', profile({ updatedAt: Timestamp.now() }));
    await assertFails(deleteDoc(doc(rider('r1'), 'people/r1')));
  });

  it('needs the server time as updatedAt', async () => {
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), profile({ updatedAt: Timestamp.now() })));
  });

  it('accepts only English or Tamil', async () => {
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), profile({ language: 'si' })));
  });

  it('refuses unknown fields and missing ones', async () => {
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), profile({ email: 'x@example.com' })));
    const { name: _name, ...noName } = profile();
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), noName));
  });

  it('checks the name and photo address', async () => {
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), profile({ name: '' })));
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), profile({ name: 'x'.repeat(81) })));
    await assertFails(setDoc(doc(rider('r1'), 'people/r1'), profile({ photoUrl: 42 })));
    await assertSucceeds(
      setDoc(doc(rider('r1'), 'people/r1'), profile({ photoUrl: 'https://example.com/p.png' })),
    );
  });
});
