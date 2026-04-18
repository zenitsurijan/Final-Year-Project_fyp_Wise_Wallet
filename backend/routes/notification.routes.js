import express from 'express';
import { updateFcmToken, getNotifications, markAsRead } from '../controllers/notification.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(protect);

router.post('/token', updateFcmToken);
router.get('/', getNotifications);
router.put('/read', markAsRead);

export default router;
