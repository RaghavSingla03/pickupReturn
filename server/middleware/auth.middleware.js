import jwt from 'jsonwebtoken';
import pool from '../db/db.js';

if (!process.env.JWT_SECRET) {
  throw new Error('FATAL: JWT_SECRET environment variable is not set. Refusing to start.');
}
const JWT_SECRET = process.env.JWT_SECRET;

export async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    const { rows: [user] } = await pool.query('SELECT is_active FROM users WHERE id = $1', [decoded.id]);
    if (!user || user.is_active === 0) {
      return res.status(403).json({ error: 'Account suspended. Contact admin.' });
    }

    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

// SSE auth: EventSource cannot set headers, so browsers pass a short-lived
// stream token (?st=) scoped to one booking, minted by /bookings/:uuid/stream-token.
// Clients that can set headers (the Flutter app) use the normal Bearer path.
export async function authenticateStream(req, res, next) {
  const streamToken = req.query.st;
  if (!streamToken) return authenticate(req, res, next);
  try {
    const decoded = jwt.verify(streamToken, JWT_SECRET);
    if (decoded.scope !== 'stream' || decoded.uuid !== req.params.uuid) {
      return res.status(401).json({ error: 'Invalid stream token.' });
    }
    req.user = { id: decoded.id, role: decoded.role };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

export function authorizeRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied. Insufficient permissions.' });
    }
    next();
  };
}
