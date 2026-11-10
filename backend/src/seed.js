import { openDatabase, seedDemo } from './database.js';
import { transferSqlite } from './import-sqlite.js';
import { openPostgres } from './postgres.js';

const password = process.env.DEMO_PASSWORD;
if (process.env.NODE_ENV === 'production') throw new Error('Seed fictício desabilitado em produção.');
if (!password || password.length < 12 || password.length > 256) {
  throw new Error('Defina DEMO_PASSWORD com 12 a 256 caracteres.');
}
const fixture = openDatabase(':memory:');
const db = openPostgres();
try {
  seedDemo(fixture, password);
  const counts = await transferSqlite(fixture, db);
  console.log(JSON.stringify({ event: 'demo_seeded', counts }));
} catch (error) {
  console.error(error.code ? `Seed revertido. Código: ${error.code}` : error.message);
  process.exitCode = 1;
} finally {
  fixture.close();
  await db.close();
}
