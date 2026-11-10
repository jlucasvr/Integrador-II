if (!process.env.TEST_DATABASE_URL) throw new Error('Configure TEST_DATABASE_URL antes de iniciar.');
const { spawnSync } = await import('node:child_process');
const result = spawnSync(process.execPath, [
  '--test', 'test/api.test.js', 'test/points.test.js', 'integration/postgres.test.js',
], { stdio: 'inherit' });
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
