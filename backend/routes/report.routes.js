import express from 'express';
import {
    getDailyReport,
    getMonthlyReport,
    getYearlyReport,
    getCustomReport
} from '../controllers/report.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All report routes are protected
router.use(protect);

router.get('/daily', getDailyReport);
router.get('/monthly', getMonthlyReport);
router.get('/yearly', getYearlyReport);
router.get('/custom', getCustomReport);

export default router;
