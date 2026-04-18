import { createTransaction, getTransactions } from '../controllers/transaction.controller.js';
import Transaction from '../models/Transaction.js';
import User from '../models/User.js';

// Mock dependencies
jest.mock('../models/Transaction.js');
jest.mock('../models/User.js');
jest.mock('../utils/budgetAlerts.js', () => ({
    checkBudgetThresholds: jest.fn().mockResolvedValue(true)
}));

describe('Transaction Controller Unit Tests', () => {
    let req, res;

    beforeEach(() => {
        req = {
            userId: 'user123',
            body: {},
            query: {},
            user: { familyId: null }
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis()
        };
        jest.clearAllMocks();
    });

    describe('createTransaction', () => {
        it('should create an expense and return 201', async () => {
            req.body = {
                type: 'expense',
                amount: 500,
                category: 'Food',
                description: 'Lunch'
            };

            // Mock saving the transaction
            Transaction.prototype.save = jest.fn().mockResolvedValue(req.body);

            await createTransaction(req, res);

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true
            }));
        });
    });

    describe('getTransactions', () => {
        it('should return a list of transactions for the user', async () => {
            const mockTransactions = [
                { _id: 't1', amount: 100, type: 'expense', description: 'Item 1' },
                { _id: 't2', amount: 200, type: 'income', description: 'Item 2' }
            ];

            Transaction.find.mockReturnValue({
                sort: jest.fn().mockReturnThis(),
                skip: jest.fn().mockReturnThis(),
                limit: jest.fn().mockResolvedValue(mockTransactions)
            });
            Transaction.countDocuments.mockResolvedValue(2);

            await getTransactions(req, res);

            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                transactions: mockTransactions
            }));
        });
    });
});
