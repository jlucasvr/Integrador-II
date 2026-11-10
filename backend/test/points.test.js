import { testDatabase } from './support/database.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { openDatabase, seedDemo, hashPassword } from '../src/database.js';
import { createApp } from '../src/app.js';

const point = {
  institution_id: 'inst-central', name: 'Novo ponto', address: 'Rua A, 10',
  region: 'Cidade', hours: '8h às 18h', contact: '(11) 1234-5678',
  latitude: -23.5, longitude: -46.6, active: true,
};

async function startPointsApi(t) {
  const db = await testDatabase('test-password');
  const server = createApp(db).listen(0, '127.0.0.1');
  t.after(async () => {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    await db.close();
  });
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;
  let manager;
  async function request(path, method = 'GET', body, { token = manager, key } = {}) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (key !== undefined) headers['Idempotency-Key'] = key;
    const r = await fetch(base + path, {method, headers, ...(body ? {body: JSON.stringify(body)} : {})});
    return {status: r.status, body: await r.json()};
  }
  async function login(email) {
    const result = await request('/auth/login', 'POST', { email, password: 'test-password' });
    assert.equal(result.status, 200);
    return result.body.data.token;
  }
  manager = await login('gestor@example.test');
  return { db, request, login };
}

test('cadastro e edição preservam vínculo, validam dados e refletem na consulta pública', async (t) => {
  const { request } = await startPointsApi(t);
  assert.deepEqual((await request('/manage/my-institutions')).body.data.map(i => i.id), ['inst-central']);
  assert.equal((await request('/manage/points','POST',{...point,institution_id:'inst-norte'})).status,403);
  for (const invalid of [
    { latitude: 91 }, { longitude: null }, { latitude: { toString: 0 } },
    { name: '' }, { active: 1 }, ...[true, {}, [], 123, null, ' '].map(institution_id => ({ institution_id })),
  ]) {
    assert.equal((await request('/manage/points','POST',{...point,...invalid})).status,400);
  }
  const created = await request('/manage/points','POST',point);
  assert.equal(created.status,201);
  const id = created.body.data.id;
  assert.equal((await request(`/points/${id}`)).body.data.contact,point.contact);
  assert.equal((await request(`/manage/points/${id}`,'PATCH',{...point,name:'Atualizado',expectedVersion:0})).status,200);
  assert.equal((await request(`/manage/points/${id}`,'PATCH',{...point,expectedVersion:0})).status,409);
  assert.equal((await request(`/points/${id}`)).body.data.name,'Atualizado');
  assert.equal((await request('/manage/points/norte','PATCH',{...point,expectedVersion:0})).status,403);
  assert.equal((await request(`/manage/points/${id}`,'PATCH',{...point,active:false,expectedVersion:1})).status,200);
  assert.equal((await request(`/points/${id}`)).status,404);
  assert.equal((await request('/manage/points')).body.data.find(p => p.id === id).active,0);
});

test('a mesma tentativa de cadastro devolve o mesmo ponto e isola as chaves por gestor', async (t) => {
  const { db, request, login } = await startPointsApi(t);
  const create = (body, options) => request('/manage/points', 'POST', body, options);
  const key = 'same-attempt';
  const [first, concurrent] = await Promise.all([create(point, { key }), create(point, { key })]);
  assert.equal(first.status, 201);
  assert.deepEqual(concurrent, first);
  assert.deepEqual(await create(point, { key }), first);
  assert.equal(Number((await db.get('SELECT count(*) AS total FROM points WHERE name=?', point.name)).total), 1);
  const changed = await create({ ...point, contact: 'Outro contato' }, { key });
  assert.equal(changed.status, 409);
  assert.equal(changed.body.error.code, 'IDEMPOTENCY_CONFLICT');
  assert.equal((await create(point, { key: 'bad key' })).status, 400);
  const distinct = await create(point, { key: 'new-attempt' });
  assert.equal(distinct.status, 201);
  assert.notEqual(distinct.body.data.id, first.body.data.id);

  await db.run('INSERT INTO users VALUES (?,?,?,?,?,?)', 'other-manager', 'Outro gestor', 'other@example.test', hashPassword('test-password'), 'manager', null);
  const token = await login('other@example.test');
  assert.equal((await create(point, { key, token })).status, 403);
  await db.run('INSERT INTO memberships VALUES (?,?)', 'other-manager', 'inst-central');
  const other = await create(point, { key, token });
  assert.equal(other.status, 201);
  assert.notEqual(other.body.data.id, first.body.data.id);
  await db.run('DELETE FROM memberships WHERE user_id=?', 'demo-manager');
  assert.equal((await create(point, { key })).status, 403);
});

test('falha ao guardar a tentativa reverte o ponto e permite reenviar', async (t) => {
  const { db, request } = await startPointsApi(t);
  if (db.kind === 'postgres') {
    await db.exec('ALTER TABLE point_creations ADD CONSTRAINT injected_failure CHECK (false)');
  } else await db.exec(`CREATE TRIGGER fail_creation BEFORE INSERT ON point_creations
    BEGIN SELECT RAISE(ABORT, 'falha injetada no teste'); END`);
  const create = () => request('/manage/points', 'POST', point, { key: 'retry-after-rollback' });
  assert.equal((await create()).status, 500);
  assert.equal(Number((await db.get('SELECT count(*) AS total FROM points WHERE name=?', point.name)).total), 0);
  assert.equal(Number((await db.get('SELECT count(*) AS total FROM point_creations')).total), 0);
  await db.exec(db.kind === 'postgres' ? 'ALTER TABLE point_creations DROP CONSTRAINT injected_failure' : 'DROP TRIGGER fail_creation');
  assert.equal((await create()).status, 201);
  assert.equal(Number((await db.get('SELECT count(*) AS total FROM points WHERE name=?', point.name)).total), 1);
});

test('catálogo e vínculo exigem acesso ao ponto e preservam o estoque em conflito', async (t) => {
  const { db, request } = await startPointsApi(t);
  const catalog = '/manage/points/central/catalog';
  const stock = '/manage/points/central/stock';
  assert.equal((await request(catalog, 'GET', undefined, { token: null })).status, 401);
  assert.equal((await request('/manage/points/norte/catalog')).status, 403);
  assert.equal((await request('/manage/points/norte/stock', 'POST', { item_id: 'hygiene' })).status, 403);
  assert.equal((await request(stock, 'POST', { item_id: true })).status, 400);
  assert.equal((await request(stock, 'POST', { item_id: 'missing' })).status, 404);
  const available = await request(catalog);
  assert.equal(available.status, 200);
  assert.deepEqual(available.body.data.map(item => item.id), ['blanket']);

  const link = () => request(stock, 'POST', { item_id: 'blanket', quantity: 99, visible: true });
  const attempts = await Promise.all([link(), link()]);
  assert.deepEqual(attempts.map(attempt => attempt.status).sort(), [201, 409]);
  const { id } = attempts.find(attempt => attempt.status === 201).body.data;
  assert.equal(attempts.find(attempt => attempt.status === 409).body.error.code, 'ITEM_ALREADY_LINKED');
  const linked = (await request(stock)).body.data.find(item => item.id === id);
  assert.equal(linked.unit, 'unidades');
  assert.equal(linked.version, 0);
  assert.equal(linked.quantity, 0);
  assert.equal(linked.visible, 0);
  assert.equal(linked.public_quantity, 0);
  assert.equal(linked.distributable, 0);
  assert.equal(linked.accepts_donation, 0);
  assert.deepEqual((await request(catalog)).body.data, []);
  assert.equal((await request('/points/central')).body.data.resources.some(item => item.id === id), false);

  const moved = await request(`/manage/stocks/${id}/movements`, 'POST', {
    type: 'entry', quantity: 5, expectedVersion: 0,
  });
  assert.equal(moved.status, 201);
  assert.equal((await link()).status, 409);
  assert.equal((await db.get('SELECT quantity FROM stocks WHERE id=?', id)).quantity, 5);
  assert.equal((await db.get("SELECT quantity FROM stocks WHERE id='central-water'")).quantity, 120);
});

test('bases SQLite das versões 1 e 2 preservam pontos e estoques na versão 3', () => {
  const directory = mkdtempSync(join(tmpdir(), 'apoio-schema-'));
  try {
    for (const version of [1, 2]) {
      const path = join(directory, `v${version}.sqlite`);
      const previous = openDatabase(path);
      try {
        seedDemo(previous, 'test-password');
        previous.exec(`DROP TABLE point_creations; PRAGMA user_version=${version};`);
        if (version === 1) {
          previous.exec('ALTER TABLE points DROP COLUMN contact; ALTER TABLE points DROP COLUMN version');
        } else {
          previous.exec("UPDATE points SET contact='Contato existente', version=4 WHERE id='central'");
        }
      } finally {
        previous.close();
      }
      const migrated = openDatabase(path);
      try {
        assert.equal(migrated.prepare('PRAGMA user_version').get().user_version, 3);
        assert.equal(migrated.prepare('SELECT count(*) AS total FROM points').get().total, 3);
        assert.equal(migrated.prepare('SELECT count(*) AS total FROM stocks').get().total, 7);
        assert.equal(migrated.prepare('SELECT count(*) AS total FROM point_creations').get().total, 0);
        assert.equal(migrated.prepare("SELECT version FROM points WHERE id='central'").get().version, version === 1 ? 0 : 4);
        assert.equal(migrated.prepare("SELECT contact FROM points WHERE id='central'").get().contact, version === 1 ? '' : 'Contato existente');
        assert.deepEqual(migrated.prepare('PRAGMA foreign_key_check').all(), []);
      } finally {
        migrated.close();
      }
    }
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
