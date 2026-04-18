import { checkBudgetThreshold } from '../services/budget.service.js';
import Budget from '../models/Budget.js';
import Transaction from '../models/Transaction.js';
import User from '../models/User.js';
import { sendPushNotification } from '../services/notification.service.js';

// Mock dependencies
jest.mock('../models/Budget.js');
jest.mock('../models/Transaction.js');
jest.mock('../models/User.js');
jest.mock('../services/notification.service.js');

describe('Budget Service Unit Tests', () => {
    const userId = 'user123';
    const mockUser = { _id: userId, fcmToken: 'mock-fcm-token' };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('checkBudgetThreshold', () => {
        it('should return empty alerts if no budget is found', async () => {
            Budget.findOne.mockResolvedValue(null);

            const result = await checkBudgetThreshold(userId, 100, 'Food');

            expect(result.alerts).toEqual([]);
        });

        it('should trigger a notification when overall budget exceeds 80%', async () => {
            const mockBudget = {
                user: userId,
                overallLimit: 1000,
                triggeredThresholds: { overall: [], categories: new Map() },
                alertHistory: [],
                save: jest.fn().mockResolvedValue(true)
            };

            Budget.findOne.mockResolvedValue(mockBudget);
            User.findById.mockResolvedValue(mockUser);
            
            // Mock total spent as 850 (85% of 1000)
            Transaction.aggregate.mockResolvedValue([{ total: 850 }]);

            const result = await checkBudgetThreshold(userId, 100, 'Food');

            expect(result.alerts).toHaveLength(1);
            expect(result.alerts[0].threshold).toBe(80);
            expect(sendPushNotification).toHaveBeenCalledWith(
                'mock-fcm-token',
                expect.stringContaining('80% Reached'),
                expect.any(String),
                expect.any(Object)
            );
            expect(mockBudget.triggeredThresholds.overall).toContain(80);
        });

        it('should not re-trigger a notification if threshold was already reached', async () => {
            const mockBudget = {
                user: userId,
                overallLimit: 1000,
                triggeredThresholds: { overall: [80], categories: new Map() },
                alertHistory: [],
                save: jest.fn().mockResolvedValue(true)
            };

            Budget.findOne.mockResolvedValue(mockBudget);
            User.findById.mockResolvedValue(mockUser);
            Transaction.aggregate.mockResolvedValue([{ total: 850 }]);

            const result = await checkBudgetThreshold(userId, 100, 'Food');

            expect(result.alerts).toHaveLength(0);
            expect(sendPushNotification).not.toHaveBeenCalled();
        });
    });
});
