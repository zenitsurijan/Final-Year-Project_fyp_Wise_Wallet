import Budget from '../models/Budget.js';
import Transaction from '../models/Transaction.js';
import User from '../models/User.js';
import { sendPushNotification } from './notification.service.js';

/**
 * Check budget thresholds and create alerts + send notifications
 * @param {string} userId - ID of the user
 * @param {number} amount - Amount of the transaction (optional, for reference)
 * @param {string} category - Category of the transaction
 * @returns {Promise<object>} - Result of the check
 */
export const checkBudgetThreshold = async (userId, amount, category) => {
    try {
        const now = new Date();
        const month = now.getMonth() + 1;
        const year = now.getFullYear();

        // Get personal budget for the user
        const budget = await Budget.findOne({
            user: userId,
            month,
            year,
            type: 'personal'
        });

        if (!budget) return { alerts: [] };

        const user = await User.findById(userId);
        const alerts = [];
        const thresholds = [80, 90, 100];

        // Calculate current total spent for this month
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59);

        const totalSpentResult = await Transaction.aggregate([
            {
                $match: {
                    userId: userId,
                    date: { $gte: startDate, $lte: endDate },
                    type: 'expense'
                }
            },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);

        const currentTotal = totalSpentResult[0]?.total || 0;
        const overallPercent = (currentTotal / budget.overallLimit) * 100;

        // Ensure triggeredThresholds exists
        if (!budget.triggeredThresholds) {
            budget.triggeredThresholds = { overall: [], categories: new Map() };
        }

        // 1. Check overall budget thresholds
        for (const threshold of thresholds) {
            if (overallPercent >= threshold &&
                !budget.triggeredThresholds.overall.includes(threshold)) {

                alerts.push({
                    type: 'overall',
                    threshold,
                    current: currentTotal,
                    limit: budget.overallLimit
                });

                budget.alertHistory.push({
                    threshold,
                    category: null,
                    amountAtTime: currentTotal,
                    notified: true
                });

                budget.triggeredThresholds.overall.push(threshold);

                // Send push notification
                if (user.fcmToken) {
                    await sendPushNotification(
                        user.fcmToken,
                        `Budget Alert: ${threshold}% Reached!`,
                        `You've spent $${currentTotal.toFixed(2)} of your $${budget.overallLimit} monthly budget.`,
                        { type: 'budget_alert', threshold: threshold.toString() }
                    );
                }
            }
        }

        // 2. Check category budget thresholds
        if (category && budget.categories) {
            const catBudget = budget.categories.find(c =>
                c.name.toLowerCase() === category.toLowerCase()
            );

            if (catBudget) {
                const catSpentResult = await Transaction.aggregate([
                    {
                        $match: {
                            userId: userId,
                            date: { $gte: startDate, $lte: endDate },
                            type: 'expense',
                            $or: [
                                { category: catBudget.name },
                                { customCategory: catBudget.name }
                            ]
                        }
                    },
                    { $group: { _id: null, total: { $sum: '$amount' } } }
                ]);

                const catTotal = catSpentResult[0]?.total || 0;
                const catPercent = (catTotal / catBudget.limit) * 100;

                for (const threshold of thresholds) {
                    const catTriggered = budget.triggeredThresholds.categories.get(catBudget.name) || [];

                    if (catPercent >= threshold && !catTriggered.includes(threshold)) {
                        alerts.push({
                            type: 'category',
                            category: catBudget.name,
                            threshold,
                            current: catTotal,
                            limit: catBudget.limit
                        });

                        budget.alertHistory.push({
                            threshold,
                            category: catBudget.name,
                            amountAtTime: catTotal,
                            notified: true
                        });

                        const existing = budget.triggeredThresholds.categories.get(catBudget.name) || [];
                        budget.triggeredThresholds.categories.set(catBudget.name, [...existing, threshold]);

                        if (user.fcmToken) {
                            await sendPushNotification(
                                user.fcmToken,
                                `${catBudget.name} Budget: ${threshold}% Reached!`,
                                `You've spent $${catTotal.toFixed(2)} of your $${catBudget.limit} ${catBudget.name} budget.`,
                                { type: 'category_alert', category: catBudget.name, threshold: threshold.toString() }
                            );
                        }
                    }
                }
            }
        }

        await budget.save();
        return { alerts };
    } catch (error) {
        console.error('Error checking budget threshold:', error);
        return { alerts: [], error: error.message };
    }
};
