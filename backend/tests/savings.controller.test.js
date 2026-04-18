import { createGoal, getGoals } from '../controllers/savings.controller.js';
import SavingsGoal from '../models/SavingsGoal.js';
import User from '../models/User.js';

// Mock models
jest.mock('../models/SavingsGoal.js');
jest.mock('../models/User.js');

describe('Savings Controller Unit Tests', () => {
    let req, res;

    beforeEach(() => {
        req = {
            userId: 'user123',
            body: {}
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis()
        };
        jest.clearAllMocks();
    });

    describe('createGoal', () => {
        it('should create a personal savings goal', async () => {
            req.body = {
                name: 'New Laptop',
                targetAmount: 1500,
                deadline: '2026-12-31',
                isFamilyGoal: false
            };

            User.findById.mockResolvedValue({ _id: 'user123', familyId: null });
            SavingsGoal.prototype.save = jest.fn().mockResolvedValue(req.body);

            await createGoal(req, res);

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true
            }));
        });
    });

    describe('getGoals', () => {
        it('should fetch all goals for a user', async () => {
            const mockGoals = [
                { name: 'Goal 1', targetAmount: 1000, currentAmount: 200, toObject: () => ({ name: 'Goal 1', targetAmount: 1000, currentAmount: 200 }) }
            ];

            User.findById.mockResolvedValue({ _id: 'user123', familyId: 'fam1' });
            SavingsGoal.find.mockReturnValue({
                sort: jest.fn().mockResolvedValue(mockGoals)
            });

            await getGoals(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                data: expect.any(Array)
            }));
        });
    });
});
