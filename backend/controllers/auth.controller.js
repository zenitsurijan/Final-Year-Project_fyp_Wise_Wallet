import User from '../models/User.js';
import jwt from 'jsonwebtoken';
import { sendVerificationEmail } from '../utils/emailService.js';
import { logEvent } from '../utils/logger.js';

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

export const register = async (req, res) => {
    try {
        const { name, email, password } = req.body;
        const userExists = await User.findOne({ email });
        if (userExists) return res.status(400).json({ success: false, message: 'User already exists' });

        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const verificationCodeExpire = new Date(Date.now() + 10 * 60 * 1000);

        const user = await User.create({
            name, email, password, verificationCode, verificationCodeExpire
        });

        console.log(`\n=== DEV OTP: ${verificationCode} ===\n`);

        // Send Email (Async - don't block response completely)
        sendVerificationEmail(user.email, verificationCode).catch(err => {
            console.error('Background Email Error:', err.message);
        });

        await logEvent({
            event: 'USER_REGISTER',
            description: `New user registered: ${user.name} (${user.email})`,
            userId: user._id
        });

        res.status(201).json({
            success: true,
            message: 'User registered. Check email for OTP.',
            token: generateToken(user._id)
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const resendOTP = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });

        if (!user) return res.status(404).json({ success: false, message: 'User not found' });
        if (user.isVerified) return res.status(400).json({ success: false, message: 'Account already verified' });

        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const verificationCodeExpire = new Date(Date.now() + 10 * 60 * 1000);

        user.verificationCode = verificationCode;
        user.verificationCodeExpire = verificationCodeExpire;
        await user.save();

        console.log(`\n=== DEV OTP (Resend): ${verificationCode} ===\n`);

        const emailSent = await sendVerificationEmail(user.email, verificationCode);

        res.status(200).json({
            success: true,
            message: 'OTP resent successfully'
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ email }).select('+password');
        if (!user || !(await user.comparePassword(password))) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        if (!user.isVerified) {
            return res.status(401).json({ success: false, message: 'Account not verified. Please verify your email.', isVerified: false });
        }

        await logEvent({
            event: 'USER_LOGIN',
            description: `User logged in: ${user.name}`,
            userId: user._id,
            level: user.role === 'admin' ? 'warning' : 'info'
        });

        res.status(200).json({
            success: true,
            token: generateToken(user._id),
            user: user.getPublicProfile()
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const verifyOTP = async (req, res) => {
    try {
        const { otp, email } = req.body;
        const user = await User.findOne({ email });

        if (!user) return res.status(404).json({ success: false, message: 'User not found' });
        if (user.verificationCode !== otp || user.verificationCodeExpire < Date.now()) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        user.isVerified = true;
        user.verificationCode = undefined;
        user.verificationCodeExpire = undefined;
        await user.save();

        await logEvent({
            event: 'USER_VERIFIED',
            description: `Email verified for ${user.email}`,
            userId: user._id
        });

        res.status(200).json({ success: true, message: 'Email verified successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;
        // The 'protect' middleware ensures req.user is populated
        req.user.fcmToken = fcmToken;
        await req.user.save();
        res.status(200).json({ success: true, message: 'FCM token updated' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
