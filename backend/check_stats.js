import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from './models/User.js';
import Transaction from './models/Transaction.js';
import SavingsGoal from './models/SavingsGoal.js';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/auth_milestone';

async function checkCounts() {
    try {
        await mongoose.connect(MONGO_URI);
        const userCount = await User.countDocuments();
        const adminCount = await User.countDocuments({ role: 'admin' });
        const transactionCount = await Transaction.countDocuments();
        const savingsCount = await SavingsGoal.countDocuments();
        console.log({
            userCount,
            adminCount,
            transactionCount,
            savingsCount
        });
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkCounts();
