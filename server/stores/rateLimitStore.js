import pool from '../db/db.js';

/**
 * PostgreSQL-backed store for express-rate-limit v8.
 * Survives server restarts — counters are persisted in the rate_limits table.
 */
export class PgRateLimitStore {
  // prefix keeps limiters from sharing counters — without it every limiter
  // keyed by the same IP increments the same row.
  constructor(windowMs, prefix = '') {
    this.windowMs = windowMs;
    this.keyPrefix = prefix;
    // Clean up expired rows every 5 minutes
    this._cleanupInterval = setInterval(() => this._cleanup(), 5 * 60 * 1000);
    if (this._cleanupInterval.unref) this._cleanupInterval.unref();
  }

  _key(key) {
    return this.keyPrefix + key;
  }

  async get(key) {
    key = this._key(key);
    try {
      const { rows: [row] } = await pool.query(
        'SELECT hits, expires_at FROM rate_limits WHERE key = $1',
        [key]
      );
      if (!row) return undefined;
      if (new Date() > new Date(row.expires_at)) {
        await pool.query('DELETE FROM rate_limits WHERE key = $1', [key]);
        return undefined;
      }
      return { totalHits: row.hits, resetTime: new Date(row.expires_at) };
    } catch {
      return undefined;
    }
  }

  async increment(key) {
    key = this._key(key);
    const expiresAt = new Date(Date.now() + this.windowMs);
    const { rows: [row] } = await pool.query(
      `INSERT INTO rate_limits (key, hits, expires_at)
       VALUES ($1, 1, $2)
       ON CONFLICT (key) DO UPDATE
         SET hits = CASE
               WHEN rate_limits.expires_at < NOW() THEN 1
               ELSE rate_limits.hits + 1
             END,
             expires_at = CASE
               WHEN rate_limits.expires_at < NOW() THEN $2
               ELSE rate_limits.expires_at
             END
       RETURNING hits, expires_at`,
      [key, expiresAt]
    );
    return { totalHits: row.hits, resetTime: new Date(row.expires_at) };
  }

  async decrement(key) {
    key = this._key(key);
    await pool.query(
      'UPDATE rate_limits SET hits = GREATEST(hits - 1, 0) WHERE key = $1 AND expires_at > NOW()',
      [key]
    );
  }

  async resetKey(key) {
    await pool.query('DELETE FROM rate_limits WHERE key = $1', [this._key(key)]);
  }

  async resetAll() {
    await pool.query('DELETE FROM rate_limits');
  }

  async shutdown() {
    clearInterval(this._cleanupInterval);
  }

  async _cleanup() {
    await pool.query('DELETE FROM rate_limits WHERE expires_at < NOW()').catch(() => {});
  }
}
