// The academic preview retains its disposable SQLite database.
export function adaptSqlite(db) {
  const direct = {
    get: (sql, ...values) => db.prepare(sql).get(...values),
    all: (sql, ...values) => db.prepare(sql).all(...values),
    run: (sql, ...values) => db.prepare(sql).run(...values),
    exec: (sql) => db.exec(sql),
  };
  let tail = Promise.resolve();
  function queue(work) {
    const result = tail.then(work);
    tail = result.catch(() => {});
    return result;
  }
  return {
    get: (...args) => queue(() => direct.get(...args)),
    all: (...args) => queue(() => direct.all(...args)),
    run: (...args) => queue(() => direct.run(...args)),
    exec: (...args) => queue(() => direct.exec(...args)),
    close: () => queue(() => db.close()),
    historyOrder: 'm.rowid',
    checkReady: () => queue(() => direct.get('SELECT 1 FROM users LIMIT 1')),
    transaction: (work) => queue(async () => {
      db.exec('BEGIN IMMEDIATE');
      try {
        const result = await work({ ...direct, getForUpdate: direct.get });
        db.exec('COMMIT');
        return result;
      } catch (error) {
        db.exec('ROLLBACK');
        throw error;
      }
    }),
  };
}
