import express from 'express';
import { 
    getDashboardStats, 
    getAllUsers, 
    getAllTransactions, 
    getAnalyticsData,
    getSystemLogs,
    updateUserRole,
    toggleUserStatus,
    deleteTransactionAdmin,
    getUserDetails
} from '../controllers/admin.controller.js';
import { protect, authorize } from '../middleware/auth.middleware.js';

const router = express.Router();

// Apply global admin protection
router.use(protect);
router.use(authorize('admin'));

router.get('/stats', getDashboardStats);
router.get('/users', getAllUsers);
router.get('/users/:id', getUserDetails);
router.put('/users/:id/role', updateUserRole);
router.put('/users/:id/status', toggleUserStatus);
router.get('/transactions', getAllTransactions);
router.delete('/transactions/:id', deleteTransactionAdmin);
router.get('/analytics', getAnalyticsData);
router.get('/logs', getSystemLogs);

export default router;
