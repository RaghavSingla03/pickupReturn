import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { authenticate, authorizeRole } from '../middleware/auth.middleware.js';
import { PgRateLimitStore } from '../stores/rateLimitStore.js';
import {
  adminLogin,
  getDashboard,
  getUsers, updateUserStatus, createUser, deleteUser, batchDeleteUsers,
  getLoads, updateLoadStatus, createLoad, deleteLoad, batchDeleteLoads, getShippers,
  getBookings,
  getDriversForVerification, verifyDriver, getVerificationHistory,
} from '../controllers/admin.controller.js';
import { getDriverDocumentsAdmin } from '../controllers/upload.controller.js';
import { getAdminSettings, updateSettings, testEmailEndpoint } from '../controllers/settings.controller.js';

const router = Router();

// Brute-force guard for the admin account. Applied unconditionally — the
// security_rate_limit DB kill-switch must never disable this one.
const adminLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  store: new PgRateLimitStore(15 * 60 * 1000, 'admin-login:'),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts. Try again in 15 minutes.' },
});

// Public: admin login
router.post('/login', adminLoginLimiter, adminLogin);

// All routes below require a valid admin JWT
router.use(authenticate);
router.use(authorizeRole('admin'));

router.get('/dashboard',         getDashboard);
router.get('/users',             getUsers);
router.post('/users',            createUser);
router.delete('/users/batch',    batchDeleteUsers);
router.put('/users/:id/status',  updateUserStatus);
router.delete('/users/:id',      deleteUser);
router.get('/loads',             getLoads);
router.post('/loads',            createLoad);
router.delete('/loads/batch',    batchDeleteLoads);
router.put('/loads/:id/status',  updateLoadStatus);
router.delete('/loads/:id',      deleteLoad);
router.get('/shippers',          getShippers);
router.get('/bookings',          getBookings);
router.get('/settings',          getAdminSettings);
router.put('/settings',          updateSettings);
router.post('/settings/test-email', testEmailEndpoint);

// Driver verification
router.get('/drivers/verification',              getDriversForVerification);
router.get('/drivers/:driverId/documents',       getDriverDocumentsAdmin);
router.get('/drivers/:driverId/history',         getVerificationHistory);
router.put('/drivers/:driverId/verify',          verifyDriver);

export default router;
