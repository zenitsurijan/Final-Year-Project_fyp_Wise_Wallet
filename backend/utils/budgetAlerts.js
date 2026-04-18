import Budget from '../models/Budget.js';
import Notification from '../models/Notification.js';
import User from '../models/User.js';
import { sendPushNotification } from '../services/notification.service.js';

export async function checkBudgetThresholds(userId, category, amount) {
    try {
        const user = await User.findById(userId);
        if (!user) return;

        const now = new Date();
        const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        // 1. Check Personal Budget
        const personalBudget = await Budget.findOne({ user_id: userId, month, type: 'personal' });
        if (personalBudget) {
            await processBudgetAlerts(personalBudget, user, category);
        }

        // 2. Check Family Budget if user is member
        if (user.familyId) {
            const familyBudget = await Budget.findOne({ family_id: user.familyId, month, type: 'family' });
            if (familyBudget) {
                // For family budget, we notify the Family Head as well? 
                // User requirement says "Family Head can track family-wide monthly budgets".
                // I'll notify the user who made the transaction and the head if it's family-wide.
                const head = await User.findOne({ familyId: user.familyId, role: 'family_head' });
                await processBudgetAlerts(familyBudget, user, category, head);
            }
        }
    } catch (error) {
        console.error('Error checking budget thresholds:', error);
    }
}

async function processBudgetAlerts(budget, user, categoryName, headUser = null) {
    await budget.calculateSpentAmounts();
    const thresholds = [80, 90, 100];

    // Check Category Budget
    const cat = budget.categories.find(c => c.category_name === categoryName);
    if (cat) {
        for (const threshold of thresholds) {
            const triggered = budget.triggeredThresholds.categories.get(cat.category_name) || [];
            if (cat.percentage >= threshold && !triggered.includes(threshold)) {
                await sendAndSaveAlert(budget, user, cat.category_name, threshold, cat.percentage, cat.spent_amount, headUser);
                budget.triggeredThresholds.categories.set(cat.category_name, [...triggered, threshold]);
            }
        }
    }

    // Check Total Budget
    const totalPercentage = budget.total_budget > 0
        ? Math.round((budget.total_spent / budget.total_budget) * 100)
        : 0;

    for (const threshold of thresholds) {
        if (totalPercentage >= threshold && !budget.triggeredThresholds.overall.includes(threshold)) {
            await sendAndSaveAlert(budget, user, 'Total Budget', threshold, totalPercentage, budget.total_spent, headUser);
            budget.triggeredThresholds.overall.push(threshold);
        }
    }

    await budget.save();
}

async function sendAndSaveAlert(budget, user, category, threshold, actualPercentage, spentAmount, headUser) {
    let message = '';
    const budgetType = budget.type === 'family' ? 'family ' : '';

    if (threshold === 80) {
        message = `You've spent ${actualPercentage}% of the ${budgetType}${category} budget.`;
    } else if (threshold === 90) {
        message = `Warning! Spent ${actualPercentage}% of ${budgetType}${category} budget. Almost at limit!`;
    } else if (threshold >= 100) {
        message = `Budget exceeded! Overspent on ${budgetType}${category} (${actualPercentage}%).`;
    }

    // Save internal notification for the user
    await Notification.create({
        user_id: user._id,
        type: 'budget_alert',
        category,
        threshold,
        message,
        percentage: actualPercentage,
        is_read: false
    });

    // Send Push Notification
    if (user.fcmToken) {
        await sendPushNotification(user.fcmToken, `Budget Alert: ${threshold}%`, message, {
            type: 'budget_alert',
            category,
            threshold: threshold.toString()
        });
    }

    // Also notify head if it's a family budget and head is different from user
    if (headUser && headUser._id.toString() !== user._id.toString() && headUser.fcmToken) {
        await sendPushNotification(headUser.fcmToken, `Family Budget Alert: ${threshold}%`, `${user.name}'s spending: ${message}`);
    }

    // Log to alert history
    budget.alertHistory.push({
        threshold,
        category,
        amountAtTime: spentAmount
    });
}
