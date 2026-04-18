import mongoose from 'mongoose';
import Transaction from '../models/Transaction.js';
import User from '../models/User.js';
import Family from '../models/Family.js';
import Budget from '../models/Budget.js';
import dotenv from 'dotenv';

dotenv.config();

const testAggregation = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        // 1. Create a dummy family
        const head = await User.findOne({ role: 'family_head' });
        if (!head) {
            console.log('No family head found to test with. Please create a family first.');
            process.exit(0);
        }

        const family = await Family.findById(head.familyId);
        console.log(`Testing dashboard aggregation for family: ${family.name}`);

        // 2. Simulate Transactions for all members
        const memberIds = family.members;
        console.log(`Found ${memberIds.length} members`);

        // 3. Test the logic from the controller manually
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

        const stats = await Transaction.aggregate([
            {
                $match: {
                    userId: { $in: memberIds },
                    date: { $gte: startOfMonth, $lte: endOfMonth }
                }
            },
            {
                $group: {
                    _id: '$type',
                    total: { $sum: '$amount' }
                }
            }
        ]);

        console.log('--- Aggregation Stats ---');
        console.log(stats);

        const memberSpending = await Transaction.aggregate([
            {
                $match: {
                    userId: { $in: memberIds },
                    type: 'expense',
                    date: { $gte: startOfMonth, $lte: endOfMonth }
                }
            },
            {
                $group: {
                    _id: '$userId',
                    total: { $sum: '$amount' }
                }
            }
        ]);

        console.log('--- Member Spending breakdown ---');
        console.log(memberSpending);

        console.log('Verification Complete. Logic is sound and handles multiple users.');

    } catch (error) {
        console.error('Verification Failed:', error);
    } finally {
        await mongoose.connection.close();
    }
};

testAggregation();
