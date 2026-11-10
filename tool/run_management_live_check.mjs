import { testDatabase } from '../backend/test/support/database.js';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { createServer } from 'node:http';
import { createApp } from '../backend/src/app.js';

const db = await testDatabase('integration-test-password');
const server = createServer(createApp(db));
try {
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const url = `http://127.0.0.1:${server.address().port}/api/v1`;
  const test = spawn('flutter test --no-pub tool/management_live_check.dart', {
    shell: true,
    stdio: 'inherit',
    env: { ...process.env, APOIO_ISOLATED_API_URL: url },
  });
  const [code] = await once(test, 'close');
  process.exitCode = code ?? 1;
} finally {
  if (server.listening) {
    await new Promise((resolve) => {
      server.close(resolve);
      server.closeAllConnections();
    });
  }
  await db.close();
}
