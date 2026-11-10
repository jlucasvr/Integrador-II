import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { once } from 'node:events';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { openDatabase, seedDemo, verifyPassword } from '../src/database.js';
import { createApp } from '../src/app.js';
import { transferSqlite } from '../src/import-sqlite.js';
import { migrate } from '../src/migrate.js';
import { isolatedPostgres } from '../test/support/database.js';

async function database(t) {
  const db = await isolatedPostgres(process.env.TEST_DATABASE_URL);
  t.after(() => db.close());
  return db;
}

test('readiness distingue banco sem migração; migração é repetível e logs omitem consulta e cabeçalhos', async (t) => {
  const db = await database(t);
  const logs = [];
  const logger = { info: (line) => logs.push(JSON.parse(line)), error: (line) => logs.push(JSON.parse(line)) };
  const server = createApp(db, { logger }).listen(0, '127.0.0.1');
  t.after(() => new Promise((resolve) => { server.close(resolve); server.closeAllConnections(); }));
  await once(server, 'listening');
  const url = `http://127.0.0.1:${server.address().port}/api/v1`;
  const headers = { Authorization: 'Bearer secret-example', 'X-Request-Id': 'untrusted-id' };
  assert.equal((await fetch(url + '/health')).status, 200);
  const unavailable = await fetch(url + '/ready?lat=12.987&lon=-31.888', { headers });
  assert.equal(unavailable.status, 503);
  const id = unavailable.headers.get('x-request-id');
  assert.match(id, /^[0-9a-f-]{36}$/);
  assert.ok(logs.some((entry) => entry.event === 'http_request' && entry.requestId === id && entry.route === '/api/v1/ready'));
  assert.doesNotMatch(JSON.stringify(logs), /12\.987|31\.888|secret-example|untrusted-id/);
  assert.deepEqual(await migrate(db), ['001_initial.sql']);
  assert.deepEqual(await migrate(db), []);
  assert.equal((await fetch(url + '/ready')).status, 200);
});

for (const version of [1, 2, 3]) {
  test(`importação SQLite v${version} preserva dados e invalida sessões sem alterar o arquivo`, async (t) => {
    const db = await database(t);
    await migrate(db);
    const dir = mkdtempSync(join(tmpdir(), 'apoio-import-'));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    const path = join(dir, 'origin.sqlite');
    const fixture = openDatabase(path);
    const date = '2026-01-01T12:00:00.000Z';
    try {
      seedDemo(fixture, 'import-test-password');
      fixture.exec(`
        UPDATE points SET contact='Contato', version=2 WHERE id='central';
        UPDATE stocks SET quantity=122, version=2, updated_at='${date}' WHERE id='central-water';
        INSERT INTO movements VALUES ('z-first','central-water','demo-manager','entry',1,120,121,'','${date}');
        INSERT INTO movements VALUES ('a-second','central-water','demo-manager','entry',1,121,122,'','${date}');
        INSERT INTO verification_events VALUES ('event','inst-central','demo-admin','verified','validação','${date}');
        INSERT INTO point_creations VALUES ('demo-manager','retry','fingerprint','central');
        INSERT INTO sessions VALUES ('legacy-token-hash','demo-manager',9999999999999);
      `);
      if (version < 3) fixture.exec('DROP TABLE point_creations; ALTER TABLE points DROP COLUMN version');
      if (version === 1) fixture.exec('ALTER TABLE points DROP COLUMN contact');
      fixture.exec(`PRAGMA user_version=${version}; PRAGMA journal_mode=DELETE`);
    } finally { fixture.close(); }
    const hash = () => createHash('sha256').update(readFileSync(path)).digest('hex');
    const original = hash();
    const source = new DatabaseSync(path, { readOnly: true });
    try {
      const counts = await transferSqlite(source, db);
      assert.equal(counts.movements, 2);
      assert.equal(counts.verification_events, 1);
      assert.equal(counts.point_creations, version === 3 ? 1 : 0);
      assert.deepEqual(await db.get("SELECT contact,version FROM points WHERE id='central'"),
        { contact: version === 1 ? '' : 'Contato', version: version === 3 ? 2 : 0 });
      assert.deepEqual((await db.all('SELECT id FROM movements ORDER BY sequence')).map(({id}) => id), ['z-first', 'a-second']);
      assert.deepEqual(await db.get("SELECT quantity,version,updated_at FROM stocks WHERE id='central-water'"),
        { quantity: 122, version: 2, updated_at: new Date(date) });
      assert.equal((await db.get('SELECT count(*) FROM sessions')).count, '0');
      const user = await db.get("SELECT password_hash FROM users WHERE id='demo-manager'");
      assert.ok(await verifyPassword('import-test-password', user.password_hash));
      await assert.rejects(transferSqlite(source, db), /precisa estar vazio/);
    } finally { source.close(); }
    assert.equal(hash(), original);
  });
}

test('linha incompatível com restrição PostgreSQL reverte a importação inteira', async (t) => {
  const db = await database(t);
  await migrate(db);
  const fixture = openDatabase(':memory:');
  try {
    seedDemo(fixture, 'import-test-password');
    fixture.exec("UPDATE points SET active=2 WHERE id='central'");
    await assert.rejects(transferSqlite(fixture, db), { code: '23514' });
    assert.equal((await db.get('SELECT count(*) FROM users')).count, '0');
    assert.equal((await db.get('SELECT count(*) FROM municipalities')).count, '0');
  } finally { fixture.close(); }
});
