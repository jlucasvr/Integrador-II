import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { randomUUID, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

export function openDatabase(path = resolve('data/apoio.sqlite')) {
  if (path !== ':memory:') mkdirSync(dirname(path), { recursive: true });
  const db = new DatabaseSync(path);
  db.exec('PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000;');
  if (path !== ':memory:') db.exec('PRAGMA journal_mode = WAL;');
  db.exec(`
    CREATE TABLE IF NOT EXISTS municipalities (id TEXT PRIMARY KEY, name TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('manager','municipality')),
      municipality_id TEXT REFERENCES municipalities(id));
    CREATE TABLE IF NOT EXISTS institutions (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, municipality_id TEXT NOT NULL REFERENCES municipalities(id),
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','verified','suspended')));
    CREATE TABLE IF NOT EXISTS memberships (
      user_id TEXT REFERENCES users(id), institution_id TEXT REFERENCES institutions(id),
      PRIMARY KEY(user_id,institution_id));
    CREATE TABLE IF NOT EXISTS points (
      id TEXT PRIMARY KEY, institution_id TEXT NOT NULL REFERENCES institutions(id),
      name TEXT NOT NULL, address TEXT NOT NULL, region TEXT NOT NULL, hours TEXT NOT NULL,
      latitude REAL NOT NULL CHECK(latitude BETWEEN -90 AND 90),
      longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180), active INTEGER NOT NULL DEFAULT 1);
    CREATE TABLE IF NOT EXISTS items (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, unit TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS stocks (
      id TEXT PRIMARY KEY, point_id TEXT NOT NULL REFERENCES points(id), item_id TEXT NOT NULL REFERENCES items(id),
      quantity INTEGER NOT NULL CHECK(quantity BETWEEN 0 AND 1000000000),
      public_quantity INTEGER NOT NULL DEFAULT 1, visible INTEGER NOT NULL DEFAULT 1,
      distributable INTEGER NOT NULL DEFAULT 1, accepts_donation INTEGER NOT NULL DEFAULT 1,
      version INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, UNIQUE(point_id,item_id));
    CREATE TABLE IF NOT EXISTS sessions (
      token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), expires_at INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS movements (
      id TEXT PRIMARY KEY, stock_id TEXT NOT NULL REFERENCES stocks(id), user_id TEXT NOT NULL REFERENCES users(id),
      type TEXT NOT NULL CHECK(type IN ('entry','exit','adjustment')), quantity INTEGER NOT NULL,
      previous_balance INTEGER NOT NULL, resulting_balance INTEGER NOT NULL, note TEXT NOT NULL,
      created_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS verification_events (
      id TEXT PRIMARY KEY, institution_id TEXT NOT NULL REFERENCES institutions(id),
      user_id TEXT NOT NULL REFERENCES users(id), status TEXT NOT NULL, note TEXT NOT NULL, created_at TEXT NOT NULL);
    PRAGMA user_version = 1;
  `);
  return db;
}

export function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  return `${salt}:${scryptSync(password, salt, 64).toString('hex')}`;
}
export function verifyPassword(password, stored) {
  const [salt, hash] = stored.split(':');
  const expected = Buffer.from(hash, 'hex');
  const actual = scryptSync(password, salt, 64);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

export function seedDemo(db, password) {
  if (db.prepare('SELECT COUNT(*) AS total FROM users').get().total !== 0) {
    throw new Error('O banco já possui usuários. Nenhum dado foi sobrescrito.');
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO municipalities VALUES (?,?)').run('demo-city','Cidade Exemplo');
    const user = db.prepare('INSERT INTO users VALUES (?,?,?,?,?,?)');
    user.run('demo-manager','Gestor de demonstração','gestor@example.test',hashPassword(password),'manager',null);
    user.run('demo-admin','Prefeitura de demonstração','prefeitura@example.test',hashPassword(password),'municipality','demo-city');
    const institutions = ['Instituição Solidariedade','Associação Bairro Unido','Rede de Apoio Municipal'];
    const names = ['Centro de Apoio Central','Ponto Comunitário Norte','Escola de Apoio Sul'];
    const addresses = ['Rua Exemplo, 100 · Centro','Avenida Modelo, 250 · Bairro Norte','Rua Ilustrativa, 40 · Bairro Sul'];
    ['central','norte','sul'].forEach((id,i)=>{
      db.prepare('INSERT INTO institutions VALUES (?,?,?,?)').run(`inst-${id}`,institutions[i],'demo-city','verified');
      db.prepare('INSERT INTO points VALUES (?,?,?,?,?,?,?,?,?)').run(id,`inst-${id}`,names[i],addresses[i],
        'Cidade Exemplo',`Segunda a sexta, das 8h às ${i===1?'17':'18'}h`,-23.55+i*.01,-46.63+i*.01,1);
    });
    // Gestor vinculado somente à instituição Central; os demais pontos permitem testar isolamento.
    db.prepare('INSERT INTO memberships VALUES (?,?)').run('demo-manager','inst-central');
    const items = [['water','Água potável','Água','garrafas de 1 L'],['food','Cesta básica','Alimentos','cestas'],
      ['hygiene','Kit de higiene','Higiene','kits'],['blanket','Cobertor','Abrigo','unidades']];
    for (const item of items) db.prepare('INSERT INTO items VALUES (?,?,?,?)').run(...item);
    const stocks = [['central-water','central','water',120,1,1],['central-food','central','food',25,1,1],
      ['central-hygiene','central','hygiene',0,1,1],['norte-water','norte','water',60,0,1],
      ['norte-blanket','norte','blanket',40,1,1],['sul-water','sul','water',0,1,1],['sul-food','sul','food',10,1,0]];
    for (const [id,point,item,quantity,published,donation] of stocks) {
      db.prepare(`INSERT INTO stocks(id,point_id,item_id,quantity,public_quantity,accepts_donation,updated_at)
        VALUES (?,?,?,?,?,?,?)`).run(id,point,item,quantity,published,donation,new Date().toISOString());
    }
    db.exec('COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

export const newId = () => randomUUID();
