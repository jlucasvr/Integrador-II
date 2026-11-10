import { isIP } from 'node:net';
import { openPostgres } from './postgres.js';
import { createApp } from './app.js';

const production = process.env.NODE_ENV === 'production';
const list = (value) => (value ?? '').split(',').map((entry) => entry.trim()).filter(Boolean);
const allowedOrigins = list(process.env.CORS_ORIGINS);
const proxies = list(process.env.TRUST_PROXY);
const host = process.env.HOST ?? '127.0.0.1';
const port = Number(process.env.PORT ?? 3000);

if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PORT inválida.');
if (production && !allowedOrigins.length) throw new Error('Configure CORS_ORIGINS em produção.');
if (allowedOrigins.some((entry) => {
  const url = URL.parse(entry);
  return !url || url.origin !== entry || !(production ? ['https:'] : ['https:', 'http:']).includes(url.protocol);
})) throw new Error('CORS_ORIGINS deve conter origens HTTP(S) exatas, sem barra final.');
if (proxies.some((entry) => {
  const [address, bits, extra] = entry.split('/');
  const version = isIP(address);
  return !version || extra !== undefined || (bits !== undefined &&
    (!/^\d+$/.test(bits) || Number(bits) < 1 || Number(bits) > (version === 4 ? 32 : 128)));
})) throw new Error('TRUST_PROXY deve conter somente IPs ou sub-redes restritas.');

const db = openPostgres();
try {
  await db.checkReady();
} catch {
  console.error(JSON.stringify({ level: 'error', event: 'startup_database_unavailable' }));
  await db.close();
  process.exit(1);
}
const server = createApp(db, {
  allowedOrigins, localOrigins: !production, trustProxy: proxies.length ? proxies : false, logger: console,
}).listen(port, host, () => {
  console.info(JSON.stringify({ level: 'info', event: 'api_listening', host, port }));
});
server.requestTimeout = 30_000;
server.headersTimeout = 10_000;

function shutdown() {
  server.close(async () => { await db.close(); });
  setTimeout(() => process.exit(1), 15_000).unref();
}
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
