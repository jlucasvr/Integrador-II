import { adaptSqlite } from './sqlite-adapter.js';
import { existsSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import { createApp } from './app.js';
import { openDatabase, seedDemo } from './database.js';

const webRoot = fileURLToPath(new URL('../../web/', import.meta.url));
if (!existsSync(join(webRoot, 'main.dart.js'))) {
  throw new Error('Execute a prévia na pasta backend de um pacote gerado com iniciar.ps1 -Action package.');
}

const databasePath = process.env.PREVIEW_DB_PATH || ':memory:';
const db = openDatabase(databasePath);
const password = randomBytes(12).toString('base64url');
const fresh = db.prepare('SELECT COUNT(*) AS total FROM users').get().total === 0;
if (fresh) seedDemo(db, process.env.DEMO_PASSWORD || password);
const app = express();
app.use(express.static(webRoot));
app.use(createApp(adaptSqlite(db), { demo: true }));

const port = Number(process.env.PREVIEW_PORT || 0);
if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('PREVIEW_PORT inválida.');
const server = app.listen(port, '127.0.0.1', () => {
  console.log(`Avaliação local: http://127.0.0.1:${server.address().port}`);
  console.log(databasePath === ':memory:'
    ? 'Dados demonstrativos em memória. Encerrar descarta alterações.'
    : 'Dados de desenvolvimento em banco local persistente.');
  if (fresh) console.log(`Gestor de avaliação: gestor@example.test | Senha temporária: ${process.env.DEMO_PASSWORD || password}`);
  else console.log('Use a senha de avaliação definida na primeira execução deste banco.');
});

function shutdown() {
  server.close(() => db.close());
  server.closeAllConnections();
}
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
