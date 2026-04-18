import User from '../models/User.js';
import Transaction from '../models/Transaction.js';
import SavingsGoal from '../models/SavingsGoal.js';
import SystemLog from '../models/SystemLog.js';
import { logEvent } from '../utils/logger.js';
import mongoose from 'mongoose';
import Budget from '../models/Budget.js';
import Family from '../models/Family.js';


// Get global dashboard statistics
export const getDashboardStats = async (req, res) => {
    try {
        const [userCount, transactionCount, savingsCount, financialSummary] = await Promise.all([
            User.countDocuments({ role: { $ne: 'admin' } }),
            Transaction.countDocuments(),
            SavingsGoal.countDocuments(),
            Transaction.aggregate([
                {
                    $group: {
                        _id: '$type',
                        total: { $sum: '$amount' }
                    }
                }
            ])
        ]);

        const income = financialSummary.find(s => s._id === 'income')?.total || 0;
        const expenses = financialSummary.find(s => s._id === 'expense')?.total || 0;

        res.status(200).json({
            success: true,
            stats: {
                totalUsers: userCount,
                totalTransactions: transactionCount,
                totalSavingsGoals: savingsCount,
                totalIncome: income,
                totalExpenses: expenses,
                netBalance: income - expenses
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get all users (paginated)
export const getAllUsers = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const users = await User.find({ role: { $ne: 'admin' } })
            .select('-password')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await User.countDocuments({ role: { $ne: 'admin' } });

        res.status(200).json({
            success: true,
            users,
            pagination: {
                total,
                page,
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get all transactions (paginated)
export const getAllTransactions = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const transactions = await Transaction.find()
            .populate('userId', 'name email')
            .sort({ date: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Transaction.countDocuments();

        res.status(200).json({
            success: true,
            transactions,
            pagination: {
                total,
                page,
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get analytics data (trends & categories)
export const getAnalyticsData = async (req, res) => {
    try {
        const { timeframe = 'last30days' } = req.query;
        let startDate = new Date();
        
        if (timeframe === 'last7days') {
            startDate.setDate(startDate.getDate() - 7);
        } else {
            startDate.setDate(startDate.getDate() - 30);
        }

        const [dailyTrends, categoryStats] = await Promise.all([
            // Daily trends
            Transaction.aggregate([
                { $match: { date: { $gte: startDate } } },
                {
                    $group: {
                        _id: {
                            date: { $dateToString: { format: "%Y-%m-%d", date: "$date" } },
                            type: "$type"
                        },
                        total: { $sum: "$amount" }
                    }
                },
                { $sort: { "_id.date": 1 } }
            ]),
            // Category breakdown
            Transaction.aggregate([
                { $match: { type: 'expense' } },
                {
                    $group: {
                        _id: "$category",
                        total: { $sum: "$amount" }
                    }
                },
                { $sort: { total: -1 } }
            ])
        ]);

        res.status(200).json({
            success: true,
            analytics: {
                dailyTrends,
                categoryStats
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
// Get system audit logs (paginated)
export const getSystemLogs = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const logs = await SystemLog.find()
            .populate('userId', 'name email')
            .sort({ timestamp: -1 })
            .skip(skip)
            .limit(limit);

        const total = await SystemLog.countDocuments();

        res.status(200).json({
            success: true,
            logs,
            pagination: {
                total,
                page,
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
// Update user role (Promote to Admin / Remove Admin)
export const updateUserRole = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.body;

        if (!['individual', 'admin', 'family_head', 'family_member'].includes(role)) {
            return res.status(400).json({ success: false, message: 'Invalid role' });
        }

        const user = await User.findByIdAndUpdate(id, { role }, { new: true });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        await logEvent({
            event: 'ADMIN_ROLE_CHANGE',
            description: `Admin changed role for ${user.email} to ${role}`,
            userId: req.user._id,
            level: 'warning',
            metadata: { targetUserId: user._id, newRole: role }
        });

        res.status(200).json({ success: true, user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Toggle user account status (Suspend / Reactive)
export const toggleUserStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { isActive } = req.body;

        const user = await User.findByIdAndUpdate(id, { isActive }, { new: true });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        await logEvent({
            event: isActive ? 'USER_REACTIVATED' : 'USER_SUSPENDED',
            description: `Admin ${isActive ? 'reactivated' : 'suspended'} account: ${user.email}`,
            userId: req.user._id,
            level: 'warning',
            metadata: { targetUserId: user._id }
        });

        res.status(200).json({ success: true, user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete transaction (Global Revocation)
export const deleteTransactionAdmin = async (req, res) => {
    try {
        const { id } = req.params;
        const tx = await Transaction.findById(id).populate('userId', 'email');
        if (!tx) return res.status(404).json({ success: false, message: 'Transaction not found' });

        await Transaction.findByIdAndDelete(id);

        await logEvent({
            event: 'ADMIN_REVOKE_TRANSACTION',
            description: `Admin revoked transaction of amount ${tx.amount} from user ${tx.userId?.email}`,
            userId: req.user._id,
            level: 'critical',
            metadata: { transactionId: tx._id, amount: tx.amount, category: tx.category }
        });

        res.status(200).json({ success: true, message: 'Transaction revoked and deleted' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get specific user detail summary
export const getUserDetails = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await User.findById(id).select('-password');
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        const [transactions, budget, savingsGoals] = await Promise.all([
            Transaction.find({ userId: id }).sort({ date: -1 }).limit(10),
            Budget.findOne({ user_id: id, type: 'personal' }).sort({ month: -1 }),
            SavingsGoal.find({ userId: id })
        ]);

        const financialSummary = await Transaction.aggregate([
            { $match: { userId: new mongoose.Types.ObjectId(id) } },
            {
                $group: {
                    _id: '$type',
                    total: { $sum: '$amount' }
                }
            }
        ]);

        const income = financialSummary.find(s => s._id === 'income')?.total || 0;
        const expenses = financialSummary.find(s => s._id === 'expense')?.total || 0;

        // Fetch Family Data
        let familyData = {
            count: 0,
            members: []
        };

        if (user.familyId) {
            const family = await Family.findById(user.familyId).populate('members', 'name role email');
            if (family) {
                familyData.count = family.members.length;
                familyData.members = family.members.map(m => ({
                    name: m.name,
                    relation: m.role === 'family_head' ? 'Head' : 'Member', // Mapping role to relation as a fallback
                    email: m.email
                }));
            }
        }

        res.status(200).json({
            success: true,
            user,
            stats: {
                totalIncome: income,
                totalExpenses: expenses,
                netBalance: income - expenses
            },
            recentTransactions: transactions,
            currentBudget: budget,
            savingsGoals,
            familyDetails: familyData // Combined keys for frontend
        });


    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
