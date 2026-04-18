import { register, login, verifyOTP } from '../controllers/auth.controller.js';
import User from '../models/User.js';
import jwt from 'jsonwebtoken';

// Mock dependencies
jest.mock('../models/User.js');
jest.mock('jsonwebtoken');
jest.mock('../utils/emailService.js', () => ({
    sendVerificationEmail: jest.fn().mockResolvedValue(true)
}));
jest.mock('../utils/logger.js', () => ({
    logEvent: jest.fn().mockResolvedValue(true)
}));

describe('Auth Controller Unit Tests', () => {
    let req, res;

    beforeEach(() => {
        req = {
            body: {},
            user: {}
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis()
        };
    });

    describe('register', () => {
        it('should return 400 if user already exists', async () => {
            req.body = { email: 'test@example.com' };
            User.findOne.mockResolvedValue(true);

            await register(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                message: 'User already exists'
            }));
        });

        it('should create a new user and return 201', async () => {
            req.body = { name: 'Test User', email: 'test@example.com', password: 'password123' };
            User.findOne.mockResolvedValue(null);
            User.create.mockResolvedValue({ _id: 'userid', email: 'test@example.com', name: 'Test User' });
            jwt.sign.mockReturnValue('mock-token');

            await register(req, res);

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                message: 'User registered. Check email for OTP.'
            }));
        });
    });

    describe('login', () => {
        it('should return 401 for invalid credentials', async () => {
            req.body = { email: 'test@example.com', password: 'wrongpassword' };
            const mockUser = {
                comparePassword: jest.fn().mockResolvedValue(false)
            };
            User.findOne.mockReturnValue({
                select: jest.fn().mockResolvedValue(mockUser)
            });

            await login(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                message: 'Invalid credentials'
            }));
        });

        it('should return 200 and a token on successful login', async () => {
            req.body = { email: 'test@example.com', password: 'password123' };
            const mockUser = {
                _id: 'userid',
                name: 'Test User',
                isVerified: true,
                role: 'user',
                comparePassword: jest.fn().mockResolvedValue(true),
                getPublicProfile: jest.fn().mockReturnValue({ id: 'userid', name: 'Test User' })
            };
            User.findOne.mockReturnValue({
                select: jest.fn().mockResolvedValue(mockUser)
            });
            jwt.sign.mockReturnValue('mock-token');

            await login(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                token: 'mock-token'
            }));
        });
    });
});
