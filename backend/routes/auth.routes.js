import express from 'express';
import { register, login, verifyOTP, resendOTP, updateFcmToken } from '../controllers/auth.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);
router.put('/update-fcm-token', protect, updateFcmToken);

export default router;
