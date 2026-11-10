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

const db = openDatabase(':memory:');
const password = randomBytes(12).toString('base64url');
seedDemo(db, password);
const app = express();
app.use(express.static(webRoot));
app.use(createApp(adaptSqlite(db), { demo: true }));

const server = app.listen(0, '127.0.0.1', () => {
  console.log(`Avaliação local: http://127.0.0.1:${server.address().port}`);
  console.log('Dados fictícios em memória. Encerrar o processo descarta as alterações.');
  console.log(`Gestor de avaliação: gestor@example.test | Senha temporária: ${password}`);
});

function shutdown() {
  server.close(() => db.close());
  server.closeAllConnections();
}
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
