import SavingsGoal from '../models/SavingsGoal.js';
import User from '../models/User.js';
import Notification from '../models/Notification.js';
import { sendPushNotification } from '../services/notification.service.js';

// Create a new savings goal
export const createGoal = async (req, res) => {
    try {
        const { name, targetAmount, deadline, isFamilyGoal } = req.body;
        const userId = req.userId;

        const user = await User.findById(userId);
        let familyId = null;
        if (isFamilyGoal) {
            if (!user.familyId) {
                return res.status(400).json({ success: false, message: 'You are not part of a family' });
            }
            familyId = user.familyId;
        }

        const goal = new SavingsGoal({
            userId,
            familyId,
            isFamilyGoal,
            name,
            targetAmount,
            deadline: new Date(deadline)
        });

        await goal.save();

        res.status(201).json({ success: true, data: goal });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get all goals (personal and family)
export const getGoals = async (req, res) => {
    try {
        const userId = req.userId;
        const user = await User.findById(userId);

        const query = {
            $or: [
                { userId: userId },
                { familyId: user.familyId, isFamilyGoal: true }
            ]
        };

        const goals = await SavingsGoal.find(query).sort({ deadline: 1 });

        // Add insights to each goal
        const goalsWithInsights = goals.map(goal => {
            const goalObj = goal.toObject();
            goalObj.insights = calculateGoalInsights(goalObj);
            return goalObj;
        });

        res.status(200).json({ success: true, data: goalsWithInsights });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Add a contribution to a goal
export const addContribution = async (req, res) => {
    try {
        const { id } = req.params;
        const { amount, note } = req.body;
        const userId = req.userId;

        const goal = await SavingsGoal.findById(id);
        if (!goal) {
            return res.status(404).json({ success: false, message: 'Goal not found' });
        }

        // Verify access (personal goal or family goal member)
        if (!goal.isFamilyGoal && goal.userId.toString() !== userId) {
            return res.status(403).json({ success: false, message: 'Not authorized' });
        }

        goal.contributions.push({
            userId,
            amount,
            note,
            date: new Date()
        });

        goal.calculateProgress();

        // --- Requirement 4: Celebrations & Milestones ---
        const progress = Math.round((goal.currentAmount / goal.targetAmount) * 100);
        const user = await User.findById(userId);

        if (progress >= 100 && goal.status === 'completed') {
            await sendAndSaveGoalNote(user, goal, 'Goal Achieved! 🏆', `Incredible! You've reached your target for "${goal.name}".`);
        } else if (progress >= 50 && progress < 60) {
            // Only notify once for 50% milestone? For simplicity we check if we just crossed it
            // Better would be a flag in DB, but for now we check progress
            await sendAndSaveGoalNote(user, goal, 'Halfway there! ⚡', `You've reached 50% of your goal for "${goal.name}". Keep it up!`);
        }

        await goal.save();

        res.status(200).json({ success: true, data: goal });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete a goal
export const deleteGoal = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.userId;

        const goal = await SavingsGoal.findById(id);
        if (!goal) {
            return res.status(404).json({ success: false, message: 'Goal not found' });
        }

        if (goal.userId.toString() !== userId) {
            return res.status(403).json({ success: false, message: 'Only the creator can delete this goal' });
        }

        await SavingsGoal.findByIdAndDelete(id);
        res.status(200).json({ success: true, message: 'Goal deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Helper: Calculate Insights
const calculateGoalInsights = (goal) => {
    const now = new Date();
    const deadline = new Date(goal.deadline);
    const timeDiff = deadline.getTime() - now.getTime();
    const daysRemaining = Math.max(1, Math.ceil(timeDiff / (1000 * 3600 * 24)));

    const amountNeeded = Math.max(0, goal.targetAmount - goal.currentAmount);
    const progressPercentage = Math.min(100, Math.round((goal.currentAmount / goal.targetAmount) * 100));

    // Recommendations
    const dailyNeeded = amountNeeded / daysRemaining;
    const weeklyNeeded = dailyNeeded * 7;
    const monthlyNeeded = dailyNeeded * 30;

    // Motivational Messages
    let motivation = "Keep going! Every small saving counts.";
    if (progressPercentage >= 90) motivation = "Almost there! You can do it!";
    else if (progressPercentage >= 75) motivation = "Amazing progress! You're in the home stretch.";
    else if (progressPercentage >= 50) motivation = "Halfway point reached! You're doing great.";
    else if (progressPercentage >= 25) motivation = "Solid start! Keep that momentum going.";

    return {
        progressPercentage,
        daysRemaining,
        amountNeeded,
        dailyNeeded: dailyNeeded.toFixed(2),
        weeklyNeeded: weeklyNeeded.toFixed(2),
        monthlyNeeded: monthlyNeeded.toFixed(2),
        motivation
    };
};

async function sendAndSaveGoalNote(user, goal, title, message) {
    await Notification.create({
        user_id: user._id,
        type: 'savings_goal',
        message,
        is_read: false
    });

    if (user.fcmToken) {
        await sendPushNotification(user.fcmToken, title, message, {
            type: 'savings_goal',
            goalId: goal._id.toString()
        });
    }
}
