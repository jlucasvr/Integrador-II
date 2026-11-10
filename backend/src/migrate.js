import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { openPostgres } from './postgres.js';

export async function migrate(db) {
  const folder = new URL('../migrations/', import.meta.url);
  const files = (await readdir(folder)).filter((name) => /^\d{3}_[a-z0-9_]+\.sql$/.test(name)).sort();
  return db.transaction(async (tx) => {
    await tx.get('SELECT pg_advisory_xact_lock(781052202)');
    await tx.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
      name text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now()
    )`);
    const installed = new Map((await tx.all('SELECT name, checksum FROM schema_migrations'))
      .map(({ name, checksum }) => [name, checksum]));
    if ([...installed.keys()].some((name) => !files.includes(name))) {
      throw new Error('O banco possui migrações ausentes nesta versão do código.');
    }
    const applied = [];
    for (const name of files) {
      const sql = await readFile(new URL(name, folder), 'utf8');
      const checksum = createHash('sha256').update(sql.replace(/\r\n/g, '\n')).digest('hex');
      if (installed.has(name)) {
        if (installed.get(name) !== checksum) throw new Error(`Migração alterada: ${name}`);
        continue;
      }
      await tx.exec(sql);
      await tx.run('INSERT INTO schema_migrations (name, checksum) VALUES (?, ?)', name, checksum);
      applied.push(name);
    }
    return applied;
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const db = openPostgres();
  try {
    const applied = await migrate(db);
    console.log(applied.length ? `Migrações aplicadas: ${applied.join(', ')}` : 'Esquema atualizado.');
  } finally {
    await db.close();
  }
}
