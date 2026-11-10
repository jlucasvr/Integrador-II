import pg from 'pg';

function queries(connection) {
  const query = (sql, values) => {
    let index = 0;
    // Queries are application-owned strings. Values always go through the driver.
    return connection.query(sql.replace(/\?/g, () => `$${++index}`), values);
  };
  return {
    get: async (sql, ...values) => (await query(sql, values)).rows[0],
    all: async (sql, ...values) => (await query(sql, values)).rows,
    run: async (sql, ...values) => ({ changes: (await query(sql, values)).rowCount }),
    getForUpdate: async (sql, ...values) => (await query(`${sql} FOR UPDATE`, values)).rows[0],
    exec: (sql) => connection.query(sql),
  };
}

export function openPostgres(options = {}) {
  const connectionString = options.connectionString ?? process.env.DATABASE_URL;
  if (!connectionString && !(process.env.PGHOST && process.env.PGDATABASE && process.env.PGUSER)) {
    throw new Error('Configure DATABASE_URL ou PGHOST, PGDATABASE e PGUSER.');
  }
  const pool = new pg.Pool({
    connectionString, connectionTimeoutMillis: 3000, statement_timeout: 10000, ...options,
  });
  pool.on('error', (error) => {
    console.error(JSON.stringify({ level: 'error', event: 'postgres_idle_connection_error', code: error.code }));
  });
  return {
    ...queries(pool),
    historyOrder: 'm.sequence',
    async checkReady() {
      const row = await queries(pool).get("SELECT 1 AS ready FROM schema_migrations WHERE name='001_initial.sql'");
      if (!row) throw new Error('Esquema ainda não inicializado.');
    },
    async transaction(work) {
      const client = await pool.connect();
      let failure;
      try {
        await client.query('BEGIN');
        const result = await work(queries(client));
        await client.query('COMMIT');
        return result;
      } catch (error) {
        try { await client.query('ROLLBACK'); } catch (rollbackError) { failure = rollbackError; }
        throw error;
      } finally {
        client.release(failure);
      }
    },
    close: () => pool.end(),
  };
}
