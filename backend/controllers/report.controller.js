import Transaction from '../models/Transaction.js';
import Budget from '../models/Budget.js';
import mongoose from 'mongoose';

// Utility to get date range
const getDateRange = (start, end) => ({
    $gte: new Date(start),
    $lte: new Date(end)
});

export const getDailyReport = async (req, res) => {
    try {
        const { date } = req.query; // Expecting YYYY-MM-DD
        const searchDate = date ? new Date(date) : new Date();
        const startOfDay = new Date(searchDate.setHours(0, 0, 0, 0));
        const endOfDay = new Date(searchDate.setHours(23, 59, 59, 999));

        const transactions = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: startOfDay, $lte: endOfDay }
                }
            },
            {
                $group: {
                    _id: "$type",
                    total: { $sum: "$amount" },
                    count: { $sum: 1 }
                }
            }
        ]);

        const categoryBreakdown = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: startOfDay, $lte: endOfDay },
                    type: 'expense'
                }
            },
            {
                $group: {
                    _id: "$category",
                    total: { $sum: "$amount" }
                }
            },
            { $sort: { total: -1 } }
        ]);

        const totals = { income: 0, expense: 0, count: 0 };
        transactions.forEach(t => {
            if (t._id === 'income') totals.income = t.total;
            if (t._id === 'expense') totals.expense = t.total;
            totals.count += t.count;
        });

        res.status(200).json({
            success: true,
            date: startOfDay,
            summary: {
                ...totals,
                netBalance: totals.income - totals.expense
            },
            categories: categoryBreakdown
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getMonthlyReport = async (req, res) => {
    try {
        const { month, year } = req.query; // month 1-12
        const m = parseInt(month) || new Date().getMonth() + 1;
        const y = parseInt(year) || new Date().getFullYear();

        const startOfMonth = new Date(y, m - 1, 1);
        const endOfMonth = new Date(y, m, 0, 23, 59, 59, 999);

        // Previous month for comparison
        const prevMonth = m === 1 ? 12 : m - 1;
        const prevYear = m === 1 ? y - 1 : y;
        const startOfPrevMonth = new Date(prevYear, prevMonth - 1, 1);
        const endOfPrevMonth = new Date(prevYear, prevMonth, 0, 23, 59, 59, 999);

        // Current Month Totals & Category Breakdown
        const currentData = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: startOfMonth, $lte: endOfMonth }
                }
            },
            {
                $facet: {
                    totals: [
                        { $group: { _id: "$type", total: { $sum: "$amount" } } }
                    ],
                    categories: [
                        { $match: { type: 'expense' } },
                        { $group: { _id: "$category", total: { $sum: "$amount" } } },
                        { $sort: { total: -1 } }
                    ],
                    trends: [
                        {
                            $group: {
                                _id: { $dayOfMonth: "$date" },
                                income: { $sum: { $cond: [{ $eq: ["$type", "income"] }, "$amount", 0] } },
                                expense: { $sum: { $cond: [{ $eq: ["$type", "expense"] }, "$amount", 0] } }
                            }
                        },
                        { $sort: { "_id": 1 } }
                    ]
                }
            }
        ]);

        // Previous Month Totals
        const prevData = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: startOfPrevMonth, $lte: endOfPrevMonth }
                }
            },
            { $group: { _id: "$type", total: { $sum: "$amount" } } }
        ]);

        // Budget Adherence
        const budget = await Budget.findOne({
            userId: req.userId,
            month: m,
            year: y
        });

        const report = {
            currentMonth: {
                income: 0,
                expense: 0,
                categories: currentData[0].categories,
                trends: currentData[0].trends
            },
            prevMonth: { income: 0, expense: 0 },
            budgetAdherence: 0
        };

        currentData[0].totals.forEach(t => {
            if (t._id === 'income') report.currentMonth.income = t.total;
            if (t._id === 'expense') report.currentMonth.expense = t.total;
        });

        prevData.forEach(t => {
            if (t._id === 'income') report.prevMonth.income = t.total;
            if (t._id === 'expense') report.prevMonth.expense = t.total;
        });

        if (budget && budget.totalLimit > 0) {
            report.budgetAdherence = (report.currentMonth.expense / budget.totalLimit) * 100;
        }

        res.status(200).json({ success: true, ...report });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getYearlyReport = async (req, res) => {
    try {
        const { year } = req.query;
        const y = parseInt(year) || new Date().getFullYear();
        const startOfYear = new Date(y, 0, 1);
        const endOfYear = new Date(y, 11, 31, 23, 59, 59, 999);

        const yearlyData = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: startOfYear, $lte: endOfYear }
                }
            },
            {
                $group: {
                    _id: { $month: "$date" },
                    income: { $sum: { $cond: [{ $eq: ["$type", "income"] }, "$amount", 0] } },
                    expense: { $sum: { $cond: [{ $eq: ["$type", "expense"] }, "$amount", 0] } }
                }
            },
            { $sort: { "_id": 1 } }
        ]);

        const topCategories = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: startOfYear, $lte: endOfYear },
                    type: 'expense'
                }
            },
            { $group: { _id: "$category", total: { $sum: "$amount" } } },
            { $sort: { total: -1 } },
            { $limit: 5 }
        ]);

        res.status(200).json({
            success: true,
            year: y,
            monthlyBreakdown: yearlyData,
            topCategories
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getCustomReport = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        if (!startDate || !endDate) {
            return res.status(400).json({ success: false, message: "Start and end dates are required" });
        }

        const start = new Date(startDate);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const data = await Transaction.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(req.userId),
                    date: { $gte: start, $lte: end }
                }
            },
            {
                $facet: {
                    summary: [
                        { $group: { _id: "$type", total: { $sum: "$amount" }, count: { $sum: 1 } } }
                    ],
                    categories: [
                        { $match: { type: 'expense' } },
                        { $group: { _id: "$category", total: { $sum: "$amount" } } },
                        { $sort: { total: -1 } }
                    ],
                    transactions: [
                        { $sort: { date: -1 } },
                        { $limit: 100 } // Limit for overview
                    ]
                }
            }
        ]);

        const totals = { income: 0, expense: 0, count: 0 };
        data[0].summary.forEach(s => {
            if (s._id === 'income') totals.income = s.total;
            if (s._id === 'expense') totals.expense = s.total;
            totals.count += s.count;
        });

        res.status(200).json({
            success: true,
            range: { start, end },
            summary: totals,
            categories: data[0].categories,
            transactions: data[0].transactions
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
