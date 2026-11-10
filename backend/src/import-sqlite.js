import { DatabaseSync } from 'node:sqlite';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { openPostgres } from './postgres.js';

// Fixed identifiers, in foreign-key order. Sessions are deliberately invalidated.
const tables = {
  municipalities: 'id name',
  users: 'id name email password_hash role municipality_id',
  institutions: 'id name municipality_id status',
  memberships: 'user_id institution_id',
  points: 'id institution_id name address region hours latitude longitude active contact version',
  point_creations: 'user_id request_key request_hash point_id',
  items: 'id name category unit',
  stocks: 'id point_id item_id quantity public_quantity visible distributable accepts_donation version updated_at',
  movements: 'id stock_id user_id type quantity previous_balance resulting_balance note created_at',
  verification_events: 'id institution_id user_id status note created_at',
};
const defaults = { contact: "''", version: '0' };

export async function transferSqlite(source, destination) {
  source.exec('BEGIN');
  try {
    const version = source.prepare('PRAGMA user_version').get().user_version;
    if (![1, 2, 3].includes(version)) throw new Error('Versão SQLite não suportada.');
    if (source.prepare('PRAGMA integrity_check').get().integrity_check !== 'ok' ||
        source.prepare('PRAGMA foreign_key_check').get()) {
      throw new Error('O SQLite de origem tem inconsistências.');
    }
    return await destination.transaction(async (tx) => {
      const names = Object.keys(tables);
      await tx.exec(`LOCK TABLE ${[...names, 'sessions'].join(', ')} IN SHARE ROW EXCLUSIVE MODE`);
      for (const name of [...names, 'sessions']) {
        if (await tx.get(`SELECT 1 FROM ${name} LIMIT 1`)) {
          throw new Error('O PostgreSQL de destino precisa estar vazio.');
        }
      }
      const counts = {};
      for (const [name, fields] of Object.entries(tables)) {
        const columns = fields.split(' ');
        const original = new Set(source.prepare(`PRAGMA table_info(${name})`).all().map(c => c.name));
        if (name === 'point_creations' && version < 3 && !original.size) {
          counts[name] = 0;
          continue;
        }
        const projection = columns.map((col) => {
          if (original.has(col)) return col;
          if (name === 'points' && version < 3 && Object.hasOwn(defaults, col)) return defaults[col];
          throw new Error(`Coluna ausente no SQLite: ${name}.${col}`);
        });
        const select = source.prepare(`SELECT ${projection.join(', ')} FROM ${name}${name === 'movements' ? ' ORDER BY rowid' : ''}`);
        select.setReturnArrays(true);
        const sql = `INSERT INTO ${name} (${columns.join(', ')}) VALUES (${columns.map(() => '?').join(', ')})`;
        let inserted = 0;
        for (const values of select.iterate()) {
          await tx.run(sql, ...values);
          inserted++;
        }
        const { count } = await tx.get(`SELECT count(*) FROM ${name}`);
        if (Number(count) !== inserted) throw new Error(`Contagem divergente: ${name}`);
        counts[name] = inserted;
      }
      return counts;
    });
  } finally {
    source.exec('ROLLBACK');
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  if (process.argv.length !== 3) throw new Error('Uso: npm run import:sqlite -- caminho/apoio.sqlite');
  const source = new DatabaseSync(resolve(process.argv[2]), { readOnly: true });
  const db = openPostgres();
  try {
    console.log(JSON.stringify({ event: 'sqlite_imported', counts: await transferSqlite(source, db) }));
  } catch (error) {
    // PostgreSQL constraint details can contain the original row.
    console.error(error.code ? `Importação revertida. Código: ${error.code}` : error.message);
    process.exitCode = 1;
  } finally {
    source.close();
    await db.close();
  }
}
