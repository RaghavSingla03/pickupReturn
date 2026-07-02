import multer from 'multer';
import path from 'path';
import jwt from 'jsonwebtoken';
import { fileURLToPath } from 'url';
import pool from '../db/db.js';
import { serverError } from '../utils/errors.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const JWT_SECRET = process.env.JWT_SECRET;
const uploadsDir = path.join(__dirname, '..', 'uploads');

// Doc types only the owner or an admin may view. Vehicle photos are shown to
// shippers on match cards, so they stay visible to any authenticated user.
const SENSITIVE_DOC_TYPES = ['RC', 'permit', 'insurance', 'PUC', 'licence'];

const ALLOWED_EXTENSIONS = ['.pdf', '.jpg', '.jpeg', '.png', '.webp'];
const ALLOWED_MIMETYPES  = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', 'uploads'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, `${req.user.id}-${uniqueSuffix}${path.extname(file.originalname).toLowerCase()}`);
  },
});

export const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    const ext  = path.extname(file.originalname).toLowerCase();
    const mime = file.mimetype;
    if (ALLOWED_EXTENSIONS.includes(ext) && ALLOWED_MIMETYPES.includes(mime)) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF and image files (JPG, PNG, WebP) are allowed.'));
    }
  },
});

export async function uploadDocument(req, res) {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });

    // Verified drivers cannot replace documents
    const { rows: [truck] } = await pool.query('SELECT is_verified FROM trucks WHERE user_id = $1', [req.user.id]);
    if (truck?.is_verified === 1) {
      return res.status(403).json({ error: 'Your documents are verified and cannot be changed.' });
    }

    const { doc_type } = req.body;
    const validTypes = ['RC', 'permit', 'insurance', 'PUC', 'licence', 'vehicle_front', 'vehicle_left', 'vehicle_right'];
    if (!validTypes.includes(doc_type)) {
      return res.status(400).json({ error: `Doc type must be one of: ${validTypes.join(', ')}` });
    }

    const file_url = `/uploads/${req.file.filename}`;
    await pool.query(
      'INSERT INTO documents (user_id, doc_type, file_url) VALUES ($1,$2,$3)',
      [req.user.id, doc_type, file_url]
    );
    res.status(201).json({ message: 'Document uploaded.', file_url });
  } catch (err) {
    return serverError(res, err, 'upload:document');
  }
}

export async function getUserDocuments(req, res) {
  try {
    const { rows: documents } = await pool.query(
      'SELECT * FROM documents WHERE user_id = $1 ORDER BY uploaded_at DESC',
      [req.user.id]
    );
    res.json({ documents });
  } catch (err) {
    return serverError(res, err, 'upload:getUserDocs');
  }
}

// Short-lived token so <img>/<a> tags (which cannot send headers) can load files
export function issueFileToken(req, res) {
  const token = jwt.sign(
    { id: req.user.id, role: req.user.role, scope: 'files' },
    JWT_SECRET,
    { expiresIn: '15m' }
  );
  res.json({ token, expires_in: 900 });
}

function fileRequester(req) {
  const authHeader = req.headers.authorization;
  try {
    if (authHeader?.startsWith('Bearer ')) {
      return jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    }
    if (req.query.t) {
      const decoded = jwt.verify(req.query.t, JWT_SECRET);
      return decoded.scope === 'files' ? decoded : null;
    }
  } catch {
    return null;
  }
  return null;
}

// Authenticated replacement for the old public express.static('/uploads') mount
export async function serveUploadedFile(req, res) {
  try {
    const filename = path.basename(req.params.filename); // strips any path traversal
    const fileUrl = `/uploads/${filename}`;

    // Branding files must stay public — the login page shows them pre-auth
    const { rows: branding } = await pool.query(
      "SELECT value FROM settings WHERE key IN ('logo_url', 'favicon_url')"
    );
    if (branding.some(r => r.value === fileUrl)) {
      return res.sendFile(path.join(uploadsDir, filename));
    }

    const requester = fileRequester(req);
    if (!requester) return res.status(401).json({ error: 'Authentication required.' });

    const { rows: [doc] } = await pool.query(
      'SELECT user_id, doc_type FROM documents WHERE file_url = $1',
      [fileUrl]
    );

    const isAdmin = requester.role === 'admin';
    const isOwner = doc
      ? doc.user_id === requester.id
      : filename.startsWith(`${requester.id}-`); // orphaned file: fall back to filename prefix
    const isVehiclePhoto = doc && !SENSITIVE_DOC_TYPES.includes(doc.doc_type);

    if (!isAdmin && !isOwner && !isVehiclePhoto) {
      return res.status(403).json({ error: 'Access denied.' });
    }

    res.sendFile(path.join(uploadsDir, filename), err => {
      if (err && !res.headersSent) res.status(404).json({ error: 'File not found.' });
    });
  } catch (err) {
    return serverError(res, err, 'upload:serveFile');
  }
}

// Admin-only: fetch documents for any driver by user ID
export async function getDriverDocumentsAdmin(req, res) {
  try {
    const { rows: documents } = await pool.query(
      'SELECT * FROM documents WHERE user_id = $1 ORDER BY uploaded_at DESC',
      [req.params.driverId]
    );
    res.json({ documents });
  } catch (err) {
    return serverError(res, err, 'upload:getDriverDocsAdmin');
  }
}
