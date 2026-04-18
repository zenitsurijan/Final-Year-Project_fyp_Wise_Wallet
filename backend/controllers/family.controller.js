import Family from '../models/Family.js';
import User from '../models/User.js';
import Transaction from '../models/Transaction.js';
import Budget from '../models/Budget.js';
import SavingsGoal from '../models/SavingsGoal.js';
import mongoose from 'mongoose';

// Create a new family group
export const createFamily = async (req, res) => {
    try {
        const { name } = req.body;
        const userId = req.userId;

        // Check if user is already in a family
        const user = await User.findById(userId);
        if (user.familyId) {
            return res.status(400).json({ success: false, message: 'You are already part of a family.' });
        }

        // Generate unique 6-digit invite code
        const inviteCode = await Family.generateInviteCode();

        const family = new Family({
            name: name || `${user.name}'s Family`,
            inviteCode,
            headId: userId,
            members: [userId]
        });

        await family.save();

        // Update user role and familyId
        user.familyId = family._id;
        user.role = 'family_head';
        await user.save();

        res.status(201).json({
            success: true,
            message: 'Family created successfully',
            data: family
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Join a family group using invite code
export const joinFamily = async (req, res) => {
    try {
        const { inviteCode } = req.body;
        const userId = req.userId;

        const family = await Family.findOne({ inviteCode });
        if (!family) {
            return res.status(404).json({ success: false, message: 'Invalid invite code' });
        }

        const user = await User.findById(userId);
        if (user.familyId) {
            return res.status(400).json({ success: false, message: 'You are already part of a family' });
        }

        // Add user to family
        await family.addMember(userId);

        // Update user
        user.familyId = family._id;
        user.role = 'family_member';
        await user.save();

        res.status(200).json({ success: true, message: 'Successfully joined family', data: family });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Send Family Invite via Email
export const sendInviteEmail = async (req, res) => {
    try {
        const { email } = req.body;
        const familyId = req.user.familyId;

        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const family = await Family.findById(familyId);
        if (!family) {
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        const sender = await User.findById(req.userId);

        // Import email service dynamically
        const { sendFamilyInviteEmail } = await import('../utils/emailService.js');

        const result = await sendFamilyInviteEmail(
            email,
            family.inviteCode,
            family.name,
            sender.name
        );

        if (result.success) {
            res.status(200).json({ success: true, message: 'Invite sent successfully!' });
        } else {
            res.status(500).json({ success: false, message: 'Failed to send email', error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get Family Dashboard Stats
export const getFamilyDashboard = async (req, res) => {
    try {
        const familyId = req.user.familyId;
        const family = await Family.findById(familyId).populate('members', 'name email role');

        if (!family) {
            console.error('getFamilyDashboard: Family not found for ID', familyId);
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        const members = family.members || [];
        const memberIds = members.filter(m => m && m._id).map(m => m._id);

        console.log('getFamilyDashboard: Processing dashboard for family', family.name, 'with', memberIds.length, 'members');

        // Date range for current month
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

        // Total Aggregate (Income/Expense)
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

        // Member-wise spending (Bar Chart data)
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

        const memberComparison = members.filter(m => m).map(member => {
            const mId = member._id ? member._id.toString() : null;
            const spending = mId ? memberSpending.find(s => s._id && s._id.toString() === mId) : null;
            return {
                name: member.name || 'Unknown',
                amount: spending ? spending.total : 0,
                total: spending ? spending.total : 0 // Duplicate for frontend compatibility
            };
        });

        // Category-wise spending (Pie Chart data)
        const categorySpending = await Transaction.aggregate([
            {
                $match: {
                    userId: { $in: memberIds },
                    type: 'expense',
                    date: { $gte: startOfMonth, $lte: endOfMonth }
                }
            },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' }
                }
            },
            { $sort: { total: -1 } }
        ]);

        const totalIncome = stats.find(s => s._id === 'income')?.total || 0;
        const totalExpense = stats.find(s => s._id === 'expense')?.total || 0;

        // Recent family transactions
        const recentTransactions = await Transaction.find({ userId: { $in: memberIds } })
            .sort({ date: -1 })
            .limit(10)
            .populate('userId', 'name');

        // Budget Status
        const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
        const familyBudget = await Budget.findOne({
            family_id: family._id.toString(),
            month: monthStr,
            type: 'family'
        });

        // Family Saving Goals
        const savingsGoals = await SavingsGoal.find({
            familyId: family._id.toString(),
            isFamilyGoal: true
        }).sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            data: {
                familyName: family.name,
                inviteCode: family.inviteCode,
                totalIncome,
                totalExpense,
                balance: totalIncome - totalExpense,
                memberComparison: memberComparison, // Unified key with UI
                categorySpending: categorySpending.map(c => ({
                    category: c._id || 'Other',
                    amount: c.total,
                    percentage: totalExpense > 0 ? Math.round((c.total / totalExpense) * 100) : 0
                })), // For Pie Chart support
                recentTransactions,
                budgetStatus: familyBudget ? {
                    totalBudget: familyBudget.total_budget,
                    totalSpent: familyBudget.total_spent,
                    percentage: familyBudget.total_budget > 0
                        ? Math.round((familyBudget.total_spent / familyBudget.total_budget) * 100)
                        : 0
                } : null,
                savingsGoals: savingsGoals.map(goal => ({
                    id: goal._id,
                    name: goal.name,
                    targetAmount: goal.targetAmount,
                    currentAmount: goal.currentAmount,
                    percentage: Math.round((goal.currentAmount / goal.targetAmount) * 100),
                    deadline: goal.deadline
                })),
                isHead: family.headId && req.userId && family.headId.toString() === req.userId.toString(),
                memberCount: (family.members || []).length
            }
        });
    } catch (error) {
        console.error('Family Dashboard Error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get Individual Member Spending Report (Head Only)
export const getMemberSpendingReport = async (req, res) => {
    try {
        const { memberId } = req.params;
        const familyId = req.user.familyId;

        const family = await Family.findById(familyId);
        if (!family) {
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        // Only head can view others' detailed reports
        const headId = family.headId ? family.headId.toString() : null;
        if (req.userId !== headId && req.userId !== memberId) {
            return res.status(403).json({ success: false, message: 'Not authorized to view this report' });
        }

        const member = await User.findById(memberId).select('name email role');

        // Aggregate stats for this member
        const stats = await Transaction.aggregate([
            { $match: { userId: new mongoose.Types.ObjectId(memberId) } },
            {
                $group: {
                    _id: '$type',
                    total: { $sum: '$amount' }
                }
            }
        ]);

        const categorySpending = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(memberId),
                    type: 'expense'
                }
            },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' }
                }
            },
            { $sort: { total: -1 } }
        ]);

        const recentTransactions = await Transaction.find({ userId: memberId })
            .sort({ date: -1 })
            .limit(10);

        res.status(200).json({
            success: true,
            data: {
                member,
                totalIncome: stats.find(s => s._id === 'income')?.total || 0,
                totalExpense: stats.find(s => s._id === 'expense')?.total || 0,
                categorySpending: categorySpending.map(c => ({
                    category: c._id || 'Other',
                    amount: c.total
                })),
                recentTransactions
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Remove a member
export const removeMember = async (req, res) => {
    try {
        const { userId } = req.params;
        const familyId = req.user.familyId;

        const family = await Family.findById(familyId);
        if (!family) {
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        // Cannot remove the head
        if (userId && family.headId && userId.toString() === family.headId.toString()) {
            return res.status(400).json({ success: false, message: 'Cannot remove the family head. Transfer role first.' });
        }

        if (!userId) {
            return res.status(400).json({ success: false, message: 'User ID is required' });
        }

        // Remove from members list
        await family.removeMember(userId);

        // Update the removed user
        await User.findByIdAndUpdate(userId, {
            familyId: null,
            role: 'individual'
        });

        res.status(200).json({ success: true, message: 'Member removed successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get member list
export const getFamilyMembers = async (req, res) => {
    try {
        const familyId = req.user.familyId;
        const family = await Family.findById(familyId).populate('members', 'name email role createdAt');
        res.status(200).json({ success: true, data: family.members });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Transfer Family Head Role
export const transferHeadRole = async (req, res) => {
    try {
        const { newHeadId } = req.body;
        const familyId = req.user.familyId;

        const family = await Family.findById(familyId);

        const headId = family.headId ? family.headId.toString() : null;
        if (req.userId !== headId) {
            return res.status(403).json({ success: false, message: 'Only family head can transfer roles' });
        }

        // Update Family Head
        family.headId = newHeadId;
        await family.save();

        // Update Roles
        await User.findByIdAndUpdate(req.userId, { role: 'family_member' });
        await User.findByIdAndUpdate(newHeadId, { role: 'family_head' });

        res.status(200).json({ success: true, message: 'Head role transferred successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Leave a family group
export const leaveFamily = async (req, res) => {
    try {
        const userId = req.userId;
        const familyId = req.user.familyId;

        const family = await Family.findById(familyId);
        if (!family) {
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        // Check if user is head
        if (userId && family.headId && family.headId.toString() === userId && family.members.length > 1) {
            return res.status(400).json({
                success: false,
                message: 'You are the family head. Please transfer the role before leaving.'
            });
        }

        // If head is the only member, delete family instead
        if (family.members.length <= 1) {
            await Family.findByIdAndDelete(familyId);
        } else {
            await family.removeMember(userId);
        }

        // Update user
        await User.findByIdAndUpdate(userId, {
            familyId: null,
            role: 'individual'
        });

        res.status(200).json({ success: true, message: 'Successfully left the family' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete family group (Head only)
export const deleteFamily = async (req, res) => {
    try {
        const familyId = req.user.familyId;

        const family = await Family.findById(familyId);
        if (!family) {
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        // Double check head role
        if (family.headId && family.headId.toString() !== req.userId) {
            return res.status(403).json({ success: false, message: 'Only family head can delete the group' });
        }

        // Reset all members
        await User.updateMany(
            { familyId: family._id },
            { familyId: null, role: 'individual' }
        );

        // Delete family
        await Family.findByIdAndDelete(familyId);

        res.status(200).json({ success: true, message: 'Family group deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
// Update family settings (Head only)
export const updateFamilySettings = async (req, res) => {
    try {
        const { name, settings } = req.body;
        const familyId = req.user.familyId;

        const family = await Family.findById(familyId);
        if (!family) {
            return res.status(404).json({ success: false, message: 'Family not found' });
        }

        if (name) family.name = name;
        if (settings) {
            family.settings = { ...family.settings, ...settings };
        }

        await family.save();

        res.status(200).json({
            success: true,
            message: 'Family settings updated successfully',
            data: family
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
