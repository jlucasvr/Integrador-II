import { randomBytes } from 'node:crypto';
import { openDatabase, seedDemo } from '../../src/database.js';
import { adaptSqlite } from '../../src/sqlite-adapter.js';
import { openPostgres } from '../../src/postgres.js';
import { migrate } from '../../src/migrate.js';
import { transferSqlite } from '../../src/import-sqlite.js';

export async function isolatedPostgres(connectionString) {
  if (!connectionString) throw new Error('Configure TEST_DATABASE_URL para executar os testes PostgreSQL.');
  const schema = `test_${randomBytes(12).toString('hex')}`;
  const admin = openPostgres({ connectionString });
  let db;
  try {
    await admin.exec(`CREATE SCHEMA ${schema}`);
    const url = new URL(connectionString);
    // node-postgres URL options take precedence over the Pool options object.
    url.searchParams.delete('options');
    db = openPostgres({ connectionString: url.href, options: `-c search_path=${schema}` });
    return { ...db, async close() {
      try {
        await db.close();
        await admin.exec(`DROP SCHEMA ${schema} CASCADE`);
      } finally { await admin.close(); }
    } };
  } catch (error) {
    await db?.close();
    await admin.close();
    throw error;
  }
}

export async function testDatabase(password) {
  const fixture = openDatabase(':memory:');
  try { seedDemo(fixture, password); } catch (error) { fixture.close(); throw error; }
  if (!process.env.TEST_DATABASE_URL) {
    return { ...adaptSqlite(fixture), kind: 'sqlite' };
  }
  let db;
  try {
    db = await isolatedPostgres(process.env.TEST_DATABASE_URL);
    await migrate(db);
    await transferSqlite(fixture, db);
    return { ...db, kind: 'postgres' };
  } catch (error) {
    await db?.close();
    throw error;
  } finally { fixture.close(); }
}
