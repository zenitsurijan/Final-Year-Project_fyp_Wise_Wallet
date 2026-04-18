import Budget from '../models/Budget.js';
import Notification from '../models/Notification.js';
import Transaction from '../models/Transaction.js';
import User from '../models/User.js';
import { checkBudgetThresholds } from '../utils/budgetAlerts.js';

// Create new budget
// Create or Update budget
export const createBudget = async (req, res) => {
    try {
        const { month, categories, total_budget } = req.body;
        const user_id = req.userId; // Use consistent req.userId (string)

        // Check if budget already exists
        let budget = await Budget.findOne({ user_id, month, type: 'personal' });

        if (budget) {
            // Update existing
            budget.categories = categories;
            budget.total_budget = total_budget;
            budget.updated_at = Date.now();
        } else {
            // Create new
            budget = new Budget({
                user_id,
                month,
                categories,
                total_budget
            });
        }

        // Calculate spent amounts
        await budget.calculateSpentAmounts();
        await budget.save();

        res.status(200).json({
            success: true,
            message: 'Budget saved successfully',
            data: budget
        });
    } catch (error) {
        console.error('Error saving budget:', error);

        // Self-healing: Drop old problematic legacy indexes if they exist
        const isLegacyIndex = error.code === 11000 && (
            error.message.includes('user_1_category_1_month_1_year_1') ||
            error.message.includes('user_1_familyId_1_month_1_year_1')
        );

        if (isLegacyIndex) {
            try {
                const indexName = error.message.includes('user_1_category_1_month_1_year_1')
                    ? 'user_1_category_1_month_1_year_1'
                    : 'user_1_familyId_1_month_1_year_1';

                console.log(`Dropping obsolete legacy index: ${indexName}`);
                await Budget.collection.dropIndex(indexName);

                // Retry saving (recursive call or logic)
                const budgetData = await Budget.findOne({
                    user_id: req.userId,
                    month: req.body.month,
                    type: req.body.type || 'personal'
                });

                if (budgetData) {
                    budgetData.categories = req.body.categories;
                    budgetData.total_budget = req.body.total_budget;
                    await budgetData.calculateSpentAmounts();
                    await budgetData.save();
                    return res.status(200).json({
                        success: true,
                        message: 'Budget saved successfully (Legacy index repaired)',
                        data: budgetData
                    });
                } else {
                    const newBudget = new Budget({
                        user_id: req.userId,
                        month: req.body.month,
                        categories: req.body.categories,
                        total_budget: req.body.total_budget,
                        type: req.body.type || 'personal'
                    });
                    await newBudget.calculateSpentAmounts();
                    await newBudget.save();
                    return res.status(200).json({
                        success: true,
                        message: 'Budget saved successfully (Legacy index repaired)',
                        data: newBudget
                    });
                }
            } catch (retryError) {
                console.error('Retry failed:', retryError);
                return res.status(500).json({
                    success: false,
                    message: 'Error saving budget (Retry failed): ' + retryError.message,
                    error: retryError.message
                });
            }
        }

        res.status(500).json({
            success: false,
            message: 'Error saving budget: ' + error.message,
            error: error.message
        });
    }
};

// Get current month budget
export const getCurrentBudget = async (req, res) => {
    try {
        const user_id = req.userId;
        const now = new Date();
        const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        let budget = await Budget.findOne({ user_id, month });

        if (!budget) {
            return res.status(404).json({
                success: false,
                message: 'No budget found for current month'
            });
        }

        await budget.calculateSpentAmounts();
        await budget.save();

        res.status(200).json({
            success: true,
            data: budget
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching budget',
            error: error.message
        });
    }
};

// Get budget status
export const getBudgetStatus = async (req, res) => {
    try {
        const user_id = req.userId;
        const now = new Date();
        const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        const budget = await Budget.findOne({ user_id, month });

        if (!budget) {
            return res.status(404).json({
                success: false,
                message: 'No budget set for current month'
            });
        }

        await budget.calculateSpentAmounts();
        await budget.save();

        const percentage = budget.total_budget > 0
            ? Math.round((budget.total_spent / budget.total_budget) * 100)
            : 0;

        let status = 'healthy';
        if (percentage >= 100) status = 'overspent';
        else if (percentage >= 80) status = 'warning';

        const overspent_categories = budget.categories.filter(cat => cat.percentage >= 100);
        const daysLeftInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate() - now.getDate();

        res.status(200).json({
            success: true,
            data: {
                status,
                total_budget: budget.total_budget,
                total_spent: budget.total_spent,
                percentage,
                overspent_categories,
                remaining_budget: budget.total_budget - budget.total_spent,
                days_left_in_month: daysLeftInMonth
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching budget status',
            error: error.message
        });
    }
};

// Get budget by month
export const getBudgetByMonth = async (req, res) => {
    try {
        const { month } = req.params;
        const user_id = req.userId;

        const budget = await Budget.findOne({ user_id, month });

        if (!budget) {
            return res.status(404).json({
                success: false,
                message: 'Budget not found'
            });
        }

        await budget.calculateSpentAmounts();
        await budget.save();

        res.status(200).json({
            success: true,
            data: budget
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching budget',
            error: error.message
        });
    }
};

// Update budget
export const updateBudget = async (req, res) => {
    try {
        const { id } = req.params;
        const { categories, total_budget } = req.body;
        const user_id = req.userId;

        const budget = await Budget.findOne({ _id: id, user_id });

        if (!budget) {
            return res.status(404).json({
                success: false,
                message: 'Budget not found'
            });
        }

        budget.categories = categories;
        budget.total_budget = total_budget;
        budget.updated_at = Date.now();

        await budget.calculateSpentAmounts();
        await budget.save();

        res.status(200).json({
            success: true,
            message: 'Budget updated successfully',
            data: budget
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating budget',
            error: error.message
        });
    }
};

// Delete budget
export const deleteBudget = async (req, res) => {
    try {
        const { id } = req.params;
        const user_id = req.userId;

        const budget = await Budget.findOneAndDelete({ _id: id, user_id });

        if (!budget) {
            return res.status(404).json({
                success: false,
                message: 'Budget not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Budget deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting budget',
            error: error.message
        });
    }
};

// Get budget alerts
export const getBudgetAlerts = async (req, res) => {
    try {
        const user_id = req.userId;
        const alerts = await Notification.find({
            user_id,
            type: 'budget_alert'
        }).sort({ created_at: -1 }).limit(20);

        res.status(200).json({
            success: true,
            alerts
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching alerts',
            error: error.message
        });
    }
};

// Set Family Budget
export const setFamilyBudget = async (req, res) => {
    try {
        const { month, categories, total_budget } = req.body;
        const user_id = req.userId;

        const user = await User.findById(user_id);
        if (!user || user.role !== 'family_head') {
            return res.status(403).json({
                success: false,
                message: 'Only Family Head can set family budget'
            });
        }

        if (!user.familyId) {
            return res.status(400).json({
                success: false,
                message: 'You are not part of any family'
            });
        }

        let budget = await Budget.findOne({
            family_id: user.familyId,
            month,
            type: 'family'
        });

        if (budget) {
            budget.categories = categories;
            budget.total_budget = total_budget;
            budget.updated_at = Date.now();
        } else {
            budget = new Budget({
                user_id,
                family_id: user.familyId,
                month,
                type: 'family',
                categories,
                total_budget
            });
        }

        await budget.calculateSpentAmounts();
        await budget.save();

        res.status(200).json({
            success: true,
            message: 'Family budget saved successfully',
            data: budget
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error saving family budget',
            error: error.message
        });
    }
};

// Get Family Budget and Breakdown
export const getFamilyBudget = async (req, res) => {
    try {
        const user_id = req.userId;
        const now = new Date();
        const month = req.query.month && req.query.year
            ? `${req.query.year}-${String(req.query.month).padStart(2, '0')}`
            : `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        const user = await User.findById(user_id);
        if (!user.familyId) {
            return res.status(400).json({
                success: false,
                message: 'You are not part of any family'
            });
        }

        let budget = await Budget.findOne({
            family_id: user.familyId,
            month,
            type: 'family'
        });

        if (!budget) {
            return res.status(404).json({
                success: false,
                message: 'No family budget found for this month'
            });
        }

        await budget.calculateSpentAmounts();
        await budget.save();

        // Calculate member-wise breakdown
        const members = await User.find({ familyId: user.familyId });
        const [year, m] = month.split('-');
        const startDate = new Date(year, m - 1, 1);
        const endDate = new Date(year, m, 0, 23, 59, 59, 999);

        const breakdown = await Promise.all(members.map(async (member) => {
            const spentResult = await Transaction.aggregate([
                {
                    $match: {
                        userId: member._id,
                        type: 'expense',
                        date: { $gte: startDate, $lte: endDate }
                    }
                },
                { $group: { _id: null, total: { $sum: '$amount' } } }
            ]);

            return {
                id: member._id,
                name: member.name,
                spent: spentResult[0]?.total || 0
            };
        }));

        res.status(200).json({
            success: true,
            data: budget,
            breakdown
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching family budget',
            error: error.message
        });
    }
};

// Get overspending analysis
export const getOverspendingAnalysis = async (req, res) => {
    try {
        const user_id = req.userId;
        const now = new Date();

        // Fetch user to check for family context
        const user = await User.findById(user_id);
        const familyId = user?.familyId;

        // Fetch last 3 months of budgets to show trends (Personal or Family)
        const trends = [];
        for (let i = 0; i < 3; i++) {
            const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const monthStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

            // Try to find personal budget first, then family budget if user is in a family
            let budget = await Budget.findOne({ user_id, month: monthStr, type: 'personal' });
            if (!budget && familyId) {
                budget = await Budget.findOne({ family_id: familyId, month: monthStr, type: 'family' });
            }

            if (budget) {
                trends.push({
                    month: d.getMonth() + 1,
                    year: d.getFullYear(),
                    spent: budget.total_spent || 0,
                    limit: budget.total_budget || 0,
                    overspent: (budget.total_spent || 0) > (budget.total_budget || 0)
                });
            }
        }

        // Generate recommendations
        const recommendations = [];
        const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        // Check current personal budget
        let currentBudget = await Budget.findOne({ user_id, month: currentMonth, type: 'personal' });
        // If no personal, check family
        if (!currentBudget && familyId) {
            currentBudget = await Budget.findOne({ family_id: familyId, month: currentMonth, type: 'family' });
        }

        if (currentBudget && currentBudget.categories) {
            currentBudget.categories.forEach(cat => {
                const percentage = cat.percentage || (cat.budget_limit > 0 ? (cat.spent_amount / cat.budget_limit) * 100 : 0);
                if (percentage >= 100) {
                    recommendations.push({
                        severity: 'high',
                        message: `You've exceeded the ${currentBudget.type === 'family' ? 'family ' : ''}${cat.category_name} budget. Consider reducing non-essential expenses in this category.`
                    });
                } else if (percentage >= 80) {
                    recommendations.push({
                        severity: 'medium',
                        message: `The ${currentBudget.type === 'family' ? 'family ' : ''}${cat.category_name} spending is at ${Math.round(percentage)}%. Try to hold back for the rest of the month.`
                    });
                }
            });

            const totalSpent = currentBudget.total_spent || 0;
            const totalBudget = currentBudget.total_budget || 0;

            if (totalBudget > 0 && totalSpent > totalBudget * 0.9) {
                recommendations.push({
                    severity: 'high',
                    message: `You've used over 90% of the ${currentBudget.type === 'family' ? 'family' : 'total monthly'} budget. We recommend reviewing upcoming bills.`
                });
            }
        }

        if (recommendations.length === 0) {
            recommendations.push({
                severity: 'low',
                message: "Great job! Your spending is well within limits. Keep it up!"
            });
        }

        res.status(200).json({
            success: true,
            recommendations,
            trends
        });
    } catch (error) {
        console.error('Overspending Analysis Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error generating overspending analysis',
            error: error.message
        });
    }
};
