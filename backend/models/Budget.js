import mongoose from 'mongoose';

const budgetSchema = new mongoose.Schema({
    user_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    family_id: {
        type: String, // String to match familyId in User model
        default: null,
        index: true
    },
    type: {
        type: String,
        enum: ['personal', 'family'],
        default: 'personal'
    },
    month: {
        type: String,
        required: true,
        match: /^\d{4}-\d{2}$/,
        index: true
    },
    categories: [{
        category_name: {
            type: String,
            required: true
        },
        budget_limit: {
            type: Number,
            required: true,
            min: 0
        },
        spent_amount: {
            type: Number,
            default: 0,
            min: 0
        },
        percentage: {
            type: Number,
            default: 0
        }
    }],
    total_budget: {
        type: Number,
        required: true,
        min: 0
    },
    total_spent: {
        type: Number,
        default: 0
    },
    triggeredThresholds: {
        overall: { type: [Number], default: [] },
        categories: {
            type: Map,
            of: [Number],
            default: new Map()
        }
    },
    alertHistory: [{
        threshold: Number,
        category: String,
        amountAtTime: Number,
        date: { type: Date, default: Date.now }
    }],
    created_at: {
        type: Date,
        default: Date.now
    },
    updated_at: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

// Compound unique index for personal budgets
budgetSchema.index({ user_id: 1, month: 1, type: 1 }, { unique: true });
// Unique index for family budgets per month
budgetSchema.index({ family_id: 1, month: 1, type: 1 }, { unique: true, partialFilterExpression: { type: 'family' } });

// Method to calculate spent amounts from transactions
budgetSchema.methods.calculateSpentAmounts = async function () {
    const Transaction = mongoose.model('Transaction');
    const User = mongoose.model('User');

    if (!this.month || !/^\d{4}-\d{2}$/.test(this.month)) {
        throw new Error('Invalid budget month format. Expected YYYY-MM');
    }

    const [year, month] = this.month.split('-');
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);

    let matchQuery = {
        type: 'expense',
        date: { $gte: startDate, $lte: endDate }
    };

    if (this.type === 'family' && this.family_id) {
        // Find all members of this family
        const familyMembers = await User.find({ familyId: this.family_id }).select('_id');
        const memberIds = familyMembers.map(m => m._id);
        matchQuery.userId = { $in: memberIds };
    } else {
        // Ensure userId is ObjectId for aggregation
        // Convert to string first to handle both String and ObjectId types safely
        matchQuery.userId = new mongoose.Types.ObjectId(this.user_id.toString());
    }

    // 1. Calculate Overall Total Spent (regardless of categories defined in budget)
    const totalSpentResult = await Transaction.aggregate([
        { $match: matchQuery },
        { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    this.total_spent = totalSpentResult[0]?.total || 0;

    // 2. Aggregate all spending by category for the period
    const spendingBreakdown = await Transaction.aggregate([
        { $match: matchQuery },
        {
            $group: {
                _id: { $ifNull: ['$customCategory', '$category'] },
                totalSpent: { $sum: '$amount' }
            }
        }
    ]);

    // 3. Update existing categories and add new ones with spending
    if (!this.categories) this.categories = []; // Ensure categories array exists

    const existingCategoriesMap = {};
    this.categories.forEach(cat => {
        existingCategoriesMap[cat.category_name] = cat;
        cat.spent_amount = 0; // Reset
    });

    for (const item of spendingBreakdown) {
        const catName = item._id;
        const amount = item.totalSpent;

        if (catName && existingCategoriesMap[catName]) {
            existingCategoriesMap[catName].spent_amount = amount;
        } else if (catName) {
            // Auto-add new category with spending to the list
            this.categories.push({
                category_name: catName,
                budget_limit: 0,
                spent_amount: amount
            });
        }
    }

    // 4. Recalculate percentages and prune unused auto-categories
    this.categories = this.categories.filter(cat => {
        cat.percentage = cat.budget_limit > 0
            ? Math.round((cat.spent_amount / cat.budget_limit) * 100)
            : (cat.spent_amount > 0 ? 100 : 0);

        // Keep the category if:
        // 1. It has a budget limit (user explicitly wants to track it)
        // 2. OR it has spending (it's currently active)
        return cat.budget_limit > 0 || cat.spent_amount > 0;
    });

    return this;
};

export default mongoose.model('Budget', budgetSchema);
