import cron from 'node-cron';
import Bill from '../models/Bill.js';
import SavingsGoal from '../models/SavingsGoal.js';
import Transaction from '../models/Transaction.js';
import User from '../models/User.js';
import { sendPushNotification } from '../services/notification.service.js';
import Notification from '../models/Notification.js';

export const initScheduler = () => {
    // 1. Bill Reminders (Daily at 9:00 AM)
    cron.schedule('0 9 * * *', async () => {
        console.log('Running Bill Reminder Job...');
        const today = new Date();
        const threeDaysOut = new Date();
        threeDaysOut.setDate(today.getDate() + 3);
        const dayOut = new Date();
        dayOut.setDate(today.getDate() + 1);

        const bills = await Bill.find({ isPaid: false });

        for (const bill of bills) {
            const dueDate = new Date(bill.dueDate);
            const user = await User.findById(bill.userId);
            if (!user) continue;

            let message = '';
            let type = '';

            // 3 days before
            if (dueDate.toDateString() === threeDaysOut.toDateString() && !bill.remindersSent.includes('3_days')) {
                message = `Reminder: Your bill "${bill.name}" of $${bill.amount} is due in 3 days.`;
                type = '3_days';
            }
            // 1 day before
            else if (dueDate.toDateString() === dayOut.toDateString() && !bill.remindersSent.includes('1_day')) {
                message = `Important: Your bill "${bill.name}" is due tomorrow! ($${bill.amount})`;
                type = '1_day';
            }
            // On due date
            else if (dueDate.toDateString() === today.toDateString() && !bill.remindersSent.includes('today')) {
                message = `Urgent: Your bill "${bill.name}" ($${bill.amount}) is due TODAY.`;
                type = 'today';
            }

            if (message) {
                await sendAndSaveNotification(user, 'bill_reminder', message, { billId: bill._id.toString() });
                bill.remindersSent.push(type);
                await bill.save();
            }
        }
    });

    // 2. Daily Summary (Daily at 8:00 PM)
    cron.schedule('0 20 * * *', async () => {
        console.log('Running Daily Summary Job...');
        const users = await User.find({ fcmToken: { $ne: null } });
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);

        for (const user of users) {
            const dailyTransactions = await Transaction.find({
                userId: user._id,
                date: { $gte: startOfDay },
                type: 'expense'
            });

            const totalSpent = dailyTransactions.reduce((sum, tx) => sum + tx.amount, 0);
            if (totalSpent > 0) {
                const message = `Today's Summary: You've spent $${totalSpent.toFixed(2)} across ${dailyTransactions.length} transactions.`;
                await sendAndSaveNotification(user, 'summary', message);
            }
        }
    });

    // 3. Weekly Summary (Sundays at 7:00 PM)
    cron.schedule('0 19 * * 0', async () => {
        console.log('Running Weekly Summary Job...');
        const users = await User.find({ fcmToken: { $ne: null } });
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        for (const user of users) {
            const weeklyTransactions = await Transaction.find({
                userId: user._id,
                date: { $gte: weekAgo },
                type: 'expense'
            });

            const totalSpent = weeklyTransactions.reduce((sum, tx) => sum + tx.amount, 0);
            if (totalSpent > 0) {
                const message = `Weekly Review: You spent a total of $${totalSpent.toFixed(2)} this week. Check your trends in the app!`;
                await sendAndSaveNotification(user, 'summary', message);
            }
        }
    });

    // 4. Savings Goal Nudges (Daily at 10:00 AM)
    cron.schedule('0 10 * * *', async () => {
        console.log('Running Savings Goal Nudge Job...');
        const goals = await SavingsGoal.find({ status: 'active' });
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        for (const goal of goals) {
            const lastContribution = goal.contributions.length > 0
                ? goal.contributions[goal.contributions.length - 1].date
                : goal.createdAt;

            if (new Date(lastContribution) < weekAgo) {
                const user = await User.findById(goal.userId);
                if (user) {
                    const message = `Don't forget your goal! You haven't contributed to "${goal.name}" in a week.`;
                    await sendAndSaveNotification(user, 'savings_goal', message, { goalId: goal._id.toString() });
                }
            }
        }
    });
};

async function sendAndSaveNotification(user, type, message, data = {}) {
    // Save to DB
    await Notification.create({
        user_id: user._id,
        type,
        message,
        is_read: false
    });

    // Send Push
    if (user.fcmToken) {
        await sendPushNotification(user.fcmToken, getTitle(type), message, { ...data, type });
    }
}

function getTitle(type) {
    switch (type) {
        case 'bill_reminder': return 'Bill Due Reminder';
        case 'savings_goal': return 'Savings Goal Nudge';
        case 'summary': return 'Financial Summary';
        default: return 'Wise Wallet Alert';
    }
}
