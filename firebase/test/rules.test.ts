import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  type Firestore,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
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
    name: 'Fort',
    kind: 'other',
    lat: 6.9344,
    lng: 79.8501,
    placeEn: 'Colombo Fort',
    placeTa: null,
    placeSi: 'කොළඹ කොටුව',
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

  it('can share rides there, or not', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/places/p1'), place({ shareRides: true })));
    await assertSucceeds(setDoc(doc(db, 'people/r1/places/p2'), place({ shareRides: false })));
    await assertFails(setDoc(doc(db, 'people/r1/places/p3'), place({ shareRides: 'yes' })));
  });

  it('keeps your own order', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/places/p1'), place({ order: 0 })));
    await assertSucceeds(setDoc(doc(db, 'people/r1/places/p2'), place({ order: 41 })));
    for (const order of [-1, 1000, 1.5, '2']) {
      await assertFails(setDoc(doc(db, 'people/r1/places/p3'), place({ order })));
    }
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

function settings(changes: Fields = {}): Fields {
  return {
    language: 'ta',
    stages: [
      { metres: 1500, pattern: 'gentleDoubleTap' },
      { metres: 400, pattern: 'strongLongBuzz' },
    ],
    updatedAt: serverTimestamp(),
    ...changes,
  };
}

describe('settings', () => {
  it('lets a rider keep their own settings', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/settings/app'), settings()));
    await assertSucceeds(getDoc(doc(db, 'people/r1/settings/app')));
  });

  it('lets the app listen to your settings, and only yours', async () => {
    await seed('people/r1/settings/app', settings({ updatedAt: Timestamp.now() }));
    const since = where('updatedAt', '>', Timestamp.fromMillis(0));
    await assertSucceeds(getDocs(query(collection(rider('r1'), 'people/r1/settings'), since)));
    await assertFails(getDocs(query(collection(rider('r2'), 'people/r1/settings'), since)));
  });

  it('keeps settings private, even from the other rider', async () => {
    await seed('people/r1/settings/app', settings({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(rider('r2'), 'people/r1/settings/app')));
    await assertFails(setDoc(doc(rider('r2'), 'people/r1/settings/app'), settings()));
    await assertFails(setDoc(doc(stranger('r1'), 'people/r1/settings/app'), settings()));
  });

  it('has one document, never deleted', async () => {
    const db = rider('r1');
    await assertFails(setDoc(doc(db, 'people/r1/settings/other'), settings()));
    await assertSucceeds(setDoc(doc(db, 'people/r1/settings/app'), settings()));
    await assertFails(deleteDoc(doc(db, 'people/r1/settings/app')));
  });

  it('takes one to three known stages', async () => {
    const db = rider('r1');
    const stage = (metres: unknown, pattern: unknown = 'waves') => ({ metres, pattern });
    await assertSucceeds(setDoc(doc(db, 'people/r1/settings/app'), settings({ stages: [stage(150)] })));
    await assertSucceeds(
      setDoc(doc(db, 'people/r1/settings/app'), settings({ stages: [stage(3000), stage(700, 'heartbeat'), stage(150)] })),
    );
    const bad: unknown[] = [
      [],
      [stage(3000), stage(2000), stage(1000), stage(150)],
      [stage(450)],
      [stage(1500), stage(450)],
      [stage(3000), stage(1500), stage(450)],
      [stage(400, 'siren')],
      [stage('400')],
      [{ metres: 400, pattern: 'waves', colour: 'amber' }],
      'gentle',
    ];
    for (const stages of bad) {
      await assertFails(setDoc(doc(db, 'people/r1/settings/app'), settings({ stages })));
    }
  });

  it('checks the language, the time and the fields', async () => {
    const db = rider('r1');
    await assertFails(setDoc(doc(db, 'people/r1/settings/app'), settings({ language: 'si' })));
    await assertFails(setDoc(doc(db, 'people/r1/settings/app'), settings({ updatedAt: Timestamp.now() })));
    await assertFails(setDoc(doc(db, 'people/r1/settings/app'), settings({ theme: 'dark' })));
    const { stages: _stages, ...noStages } = settings();
    await assertFails(setDoc(doc(db, 'people/r1/settings/app'), noStages));
  });
});

function ride(changes: Fields = {}): Fields {
  return {
    startedAt: Timestamp.fromMillis(1_700_000_000_000),
    endedAt: Timestamp.fromMillis(1_700_001_800_000),
    verdict: 'bus',
    distanceM: 12400,
    path: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
    halts: '_p~iF~ps|U',
    features: { minutes: 30, haltsPerKm: 1.2, topSpeed: 14.5 },
    fromName: 'Fort',
    toName: 'Pettah',
    guideTo: null,
    updatedAt: serverTimestamp(),
    deletedAt: null,
    ...changes,
  };
}

describe('rides', () => {
  it('lets a rider keep their own rides', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/rides/a1'), ride()));
    await assertSucceeds(getDoc(doc(db, 'people/r1/rides/a1')));
    const since = where('updatedAt', '>', Timestamp.fromMillis(0));
    await assertSucceeds(getDocs(query(collection(db, 'people/r1/rides'), since)));
  });

  it('keeps rides private, even from the other rider', async () => {
    await seed('people/r1/rides/a1', ride({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(rider('r2'), 'people/r1/rides/a1')));
    await assertFails(setDoc(doc(rider('r2'), 'people/r1/rides/a2'), ride()));
    await assertFails(setDoc(doc(stranger('r1'), 'people/r1/rides/a3'), ride()));
  });

  it('takes a ride that was not a bus without its path', async () => {
    const db = rider('r1');
    const { path: _path, halts: _halts, fromName: _f, toName: _t, ...bare } = ride({ verdict: 'not_bus' });
    await assertSucceeds(setDoc(doc(db, 'people/r1/rides/a1'), bare));
    await assertSucceeds(setDoc(doc(db, 'people/r1/rides/a2'), ride({ verdict: 'unknown' })));
  });

  it('removes by marking, never by deleting', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'people/r1/rides/a1'), ride()));
    await assertSucceeds(
      updateDoc(doc(db, 'people/r1/rides/a1'), { deletedAt: serverTimestamp(), updatedAt: serverTimestamp() }),
    );
    await assertFails(deleteDoc(doc(db, 'people/r1/rides/a1')));
  });

  it('checks every field', async () => {
    const db = rider('r1');
    const bad: Fields[] = [
      { verdict: 'car' },
      { distanceM: -1 },
      { distanceM: 2_000_001 },
      { distanceM: '12' },
      { endedAt: Timestamp.fromMillis(1_600_000_000_000) },
      { startedAt: 'today' },
      { path: 'x'.repeat(20_001) },
      { halts: 'x'.repeat(10_001) },
      { features: 'fast' },
      { fromName: 'x'.repeat(201) },
      { guideTo: 'x'.repeat(201) },
      { colour: 'amber' },
      { updatedAt: Timestamp.now() },
      { deletedAt: Timestamp.now() },
    ];
    for (const changes of bad) {
      await assertFails(setDoc(doc(db, 'people/r1/rides/a1'), ride(changes)));
    }
    const tooMany: Record<string, number> = {};
    for (let i = 0; i < 25; i++) tooMany[`f${i}`] = i;
    await assertFails(setDoc(doc(db, 'people/r1/rides/a1'), ride({ features: tooMany })));
    const { verdict: _v, ...noVerdict } = ride();
    await assertFails(setDoc(doc(db, 'people/r1/rides/a1'), noVerdict));
  });
});

// A live share (docs/PLAN.md, Sharing and stops): an unguessable id, the
// rider's position and where they are going; no name.
const shareId = 'Kq3vT9xLmP2wZr7NbY4c';

function share(changes: Fields = {}): Fields {
  return {
    uid: 'r1',
    lat: 6.9101,
    lng: 79.8523,
    toName: 'Fort',
    toTa: 'கோட்டை',
    toLat: 6.9344,
    toLng: 79.8501,
    leftMin: 12,
    metresLeft: 2400,
    startedAt: Timestamp.now(),
    endedAt: null,
    updatedAt: serverTimestamp(),
    ...changes,
  };
}

describe('shares', () => {
  it('lets a rider share a ride, and anyone with its link watch it', async () => {
    await assertSucceeds(setDoc(doc(rider('r1'), `shares/${shareId}`), share()));
    await assertSucceeds(getDoc(doc(signedOut(), `shares/${shareId}`)));
    await assertSucceeds(getDoc(doc(stranger('s1'), `shares/${shareId}`)));
  });

  it('lets only riders look for open shares', async () => {
    await seed(`shares/${shareId}`, share({ updatedAt: Timestamp.now() }));
    const open = (db: Firestore) => getDocs(query(collection(db, 'shares'), where('endedAt', '==', null)));
    await assertSucceeds(open(rider('r2')));
    await assertFails(open(signedOut()));
    await assertFails(open(stranger('s1')));
  });

  it('only its rider writes or removes it', async () => {
    await seed(`shares/${shareId}`, share({ updatedAt: Timestamp.now() }));
    await assertFails(updateDoc(doc(rider('r2'), `shares/${shareId}`), { lat: 6.92, updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(rider('r2'), `shares/${shareId}`)));
    await assertFails(setDoc(doc(rider('r2'), 'shares/Zz9vT9xLmP2wZr7NbY4c'), share()));
    await assertFails(setDoc(doc(signedOut(), 'shares/Zz9vT9xLmP2wZr7NbY4c'), share()));
    await assertSucceeds(updateDoc(doc(rider('r1'), `shares/${shareId}`), { lat: 6.92, updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(doc(rider('r1'), `shares/${shareId}`)));
  });

  it('ends without a position, for good', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, `shares/${shareId}`), share()));
    await assertFails(
      updateDoc(doc(db, `shares/${shareId}`), { endedAt: Timestamp.now(), updatedAt: serverTimestamp() }),
    );
    await assertSucceeds(
      updateDoc(doc(db, `shares/${shareId}`), {
        endedAt: Timestamp.now(),
        lat: null,
        lng: null,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db, `shares/${shareId}`), { endedAt: null, lat: 6.92, lng: 79.85, updatedAt: serverTimestamp() }),
    );
    await assertFails(setDoc(doc(db, 'shares/Yy9vT9xLmP2wZr7NbY4c'), share({ endedAt: Timestamp.now(), lat: null, lng: null })));
  });

  it('needs a long, plain link', async () => {
    const db = rider('r1');
    await assertFails(setDoc(doc(db, 'shares/abc'), share()));
    await assertFails(setDoc(doc(db, 'shares/Kq3vT9xLmP2wZr7NbY4c-x'), share()));
  });

  it('checks every field, and holds no name', async () => {
    const db = rider('r1');
    const bad: Fields[] = [
      { uid: 'r2' },
      { name: 'Rider One' },
      { lat: 91 },
      { lng: '79.8' },
      { toName: 'x'.repeat(201) },
      { toTa: '' },
      { toLat: -91 },
      { leftMin: -1 },
      { leftMin: 1.5 },
      { leftMin: 1441 },
      { metresLeft: 2_000_001 },
      { startedAt: 'now' },
      { updatedAt: Timestamp.now() },
    ];
    for (const changes of bad) {
      await assertFails(setDoc(doc(db, `shares/${shareId}`), share(changes)));
    }
    const { startedAt: _s, ...noStart } = share();
    await assertFails(setDoc(doc(db, `shares/${shareId}`), noStart));
    // A noticed ride has no destination.
    await assertSucceeds(
      setDoc(
        doc(db, `shares/${shareId}`),
        share({ toName: null, toTa: null, toLat: null, toLng: null, leftMin: null, metresLeft: null }),
      ),
    );
  });

  it("can't move its start or change hands", async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, `shares/${shareId}`), share()));
    await assertFails(
      updateDoc(doc(db, `shares/${shareId}`), { startedAt: Timestamp.fromMillis(0), updatedAt: serverTimestamp() }),
    );
  });
});

// A bus ride's halts, pooled between the riders so both phones can work
// out the stops (docs/PLAN.md, Sharing and stops).
function halts(changes: Fields = {}): Fields {
  return {
    uid: 'r1',
    points: '6.92700,79.85100,30;6.93100,79.85050,45',
    updatedAt: serverTimestamp(),
    deletedAt: null,
    ...changes,
  };
}

describe('halts', () => {
  it("lets riders read the pool, and write only their own rides' halts", async () => {
    await assertSucceeds(setDoc(doc(rider('r1'), 'halts/k2x9w1ab7q'), halts()));
    await assertSucceeds(getDoc(doc(rider('r2'), 'halts/k2x9w1ab7q')));
    const since = where('updatedAt', '>', Timestamp.fromMillis(0));
    await assertSucceeds(getDocs(query(collection(rider('r2'), 'halts'), since)));
    await assertFails(setDoc(doc(rider('r2'), 'halts/k2x9w1ab7r'), halts()));
    await assertFails(
      updateDoc(doc(rider('r2'), 'halts/k2x9w1ab7q'), { points: '', updatedAt: serverTimestamp() }),
    );
    // Not even by making it theirs.
    await assertFails(
      updateDoc(doc(rider('r2'), 'halts/k2x9w1ab7q'), { uid: 'r2', points: '', updatedAt: serverTimestamp() }),
    );
  });

  it('keeps everyone else out', async () => {
    await seed('halts/k2x9w1ab7q', halts({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(signedOut(), 'halts/k2x9w1ab7q')));
    await assertFails(getDoc(doc(stranger('s1'), 'halts/k2x9w1ab7q')));
    await assertFails(setDoc(doc(stranger('s1'), 'halts/k2x9w1ab7z'), halts({ uid: 's1' })));
  });

  it('takes a ride back by marking, never by deleting', async () => {
    const db = rider('r1');
    await assertSucceeds(setDoc(doc(db, 'halts/k2x9w1ab7q'), halts()));
    await assertSucceeds(
      updateDoc(doc(db, 'halts/k2x9w1ab7q'), {
        points: '',
        deletedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(db, 'halts/k2x9w1ab7q')));
  });

  it('checks every field', async () => {
    const db = rider('r1');
    const bad: Fields[] = [
      { uid: 'r2' },
      { points: 'x'.repeat(10_001) },
      { points: 12 },
      { name: 'Fort' },
      { updatedAt: Timestamp.now() },
      { deletedAt: Timestamp.now() },
    ];
    for (const changes of bad) {
      await assertFails(setDoc(doc(db, 'halts/k2x9w1ab7q'), halts(changes)));
    }
    await assertFails(setDoc(doc(db, 'halts/a-b'), halts()));
  });
});

// A rename or removal of a learned stop, shared by both riders and kept at
// the stop's spot.
function stopNote(changes: Fields = {}): Fields {
  return {
    lat: 6.9271,
    lng: 79.851,
    name: 'Clock tower',
    removed: false,
    by: 'r1',
    updatedAt: serverTimestamp(),
    ...changes,
  };
}

describe('stop notes', () => {
  it('lets either rider rename or remove a learned stop', async () => {
    await assertSucceeds(setDoc(doc(rider('r1'), 'stopNotes/n1'), stopNote()));
    await assertSucceeds(getDoc(doc(rider('r2'), 'stopNotes/n1')));
    await assertSucceeds(
      setDoc(doc(rider('r2'), 'stopNotes/n1'), stopNote({ by: 'r2', name: null, removed: true })),
    );
    const since = where('updatedAt', '>', Timestamp.fromMillis(0));
    await assertSucceeds(getDocs(query(collection(rider('r1'), 'stopNotes'), since)));
  });

  it('keeps everyone else out, and is never deleted', async () => {
    await seed('stopNotes/n1', stopNote({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(signedOut(), 'stopNotes/n1')));
    await assertFails(getDoc(doc(stranger('s1'), 'stopNotes/n1')));
    await assertFails(setDoc(doc(stranger('s1'), 'stopNotes/n2'), stopNote({ by: 's1' })));
    await assertFails(deleteDoc(doc(rider('r1'), 'stopNotes/n1')));
  });

  it('checks every field', async () => {
    const db = rider('r1');
    const bad: Fields[] = [
      { by: 'r2' },
      { lat: 91 },
      { lng: '79.8' },
      { name: '' },
      { name: 'x'.repeat(81) },
      { removed: 'yes' },
      { colour: 'amber' },
      { updatedAt: Timestamp.now() },
    ];
    for (const changes of bad) {
      await assertFails(setDoc(doc(db, 'stopNotes/n1'), stopNote(changes)));
    }
    const { removed: _r, ...noRemoved } = stopNote();
    await assertFails(setDoc(doc(db, 'stopNotes/n1'), noRemoved));
  });
});

// A change to one direction of a route from the route files (docs/PLAN.md,
// Which bus): its board lines and whether it is removed, shared by both
// riders; the newest note for a direction wins.
function routeNote(changes: Fields = {}): Fields {
  return {
    route: 'ntc:15-87:SL',
    direction: 'Colombo>Kandy',
    ta: 'கண்டி',
    si: null,
    en: 'Kandy',
    removed: false,
    by: 'r1',
    updatedAt: serverTimestamp(),
    ...changes,
  };
}

describe('route notes', () => {
  it('lets either rider change a route direction for both', async () => {
    await assertSucceeds(setDoc(doc(rider('r1'), 'routeNotes/n1'), routeNote()));
    await assertSucceeds(getDoc(doc(rider('r2'), 'routeNotes/n1')));
    await assertSucceeds(
      setDoc(
        doc(rider('r2'), 'routeNotes/n2'),
        routeNote({ by: 'r2', ta: null, en: null, removed: true }),
      ),
    );
    const since = where('updatedAt', '>', Timestamp.fromMillis(0));
    await assertSucceeds(getDocs(query(collection(rider('r1'), 'routeNotes'), since)));
  });

  it('keeps everyone else out, and is never deleted', async () => {
    await seed('routeNotes/n1', routeNote({ updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(signedOut(), 'routeNotes/n1')));
    await assertFails(getDoc(doc(stranger('s1'), 'routeNotes/n1')));
    await assertFails(setDoc(doc(stranger('s1'), 'routeNotes/n2'), routeNote({ by: 's1' })));
    await assertFails(deleteDoc(doc(rider('r1'), 'routeNotes/n1')));
  });

  it('checks every field', async () => {
    const db = rider('r1');
    const bad: Fields[] = [
      { by: 'r2' },
      { route: '' },
      { route: 'x'.repeat(121) },
      { direction: '' },
      { direction: 'x'.repeat(201) },
      { ta: '' },
      { si: 'x'.repeat(121) },
      { en: 7 },
      { removed: 'yes' },
      { colour: 'amber' },
      { updatedAt: Timestamp.now() },
    ];
    for (const changes of bad) {
      await assertFails(setDoc(doc(db, 'routeNotes/n1'), routeNote(changes)));
    }
    for (const key of ['route', 'direction', 'removed', 'by', 'updatedAt']) {
      const { [key]: _gone, ...missing } = routeNote();
      await assertFails(setDoc(doc(db, 'routeNotes/n1'), missing));
    }
    // The board lines may be left out: the route file's then stand.
    const { ta: _ta, si: _si, en: _en, ...plain } = routeNote();
    await assertSucceeds(setDoc(doc(db, 'routeNotes/n1'), plain));
  });
});
