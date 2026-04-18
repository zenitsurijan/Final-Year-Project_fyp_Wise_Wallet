// Global Jest Setup for Safe Unit Testing
// This ensures that all database models are mocked by default

jest.mock('../models/User.js');
jest.mock('../models/Transaction.js');
jest.mock('../models/Budget.js');
jest.mock('../models/SavingsGoal.js');
jest.mock('../models/Category.js');
jest.mock('../models/Notification.js');

// Mock utilities
jest.mock('../utils/logger.js', () => ({
    logEvent: jest.fn().mockResolvedValue(true)
}));

jest.mock('../utils/emailService.js', () => ({
    sendVerificationEmail: jest.fn().mockResolvedValue(true)
}));

jest.mock('../services/notification.service.js', () => ({
    sendPushNotification: jest.fn().mockResolvedValue(true)
}));

console.log('--- TEST ENVIRONMENT INITIALIZED (MOCK MODE) ---');
