import mongoose from 'mongoose';

const contributionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    },
    note: {
        type: String,
        default: ''
    }
});

const savingsGoalSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    familyId: {
        type: String, // Stored as string to match User model's familyId style
        default: null
    },
    isFamilyGoal: {
        type: Boolean,
        default: false
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    targetAmount: {
        type: Number,
        required: true
    },
    currentAmount: {
        type: Number,
        default: 0
    },
    deadline: {
        type: Date,
        required: true
    },
    status: {
        type: String,
        enum: ['active', 'completed'],
        default: 'active'
    },
    contributions: [contributionSchema]
}, {
    timestamps: true
});

// Calculate current progress based on contributions
savingsGoalSchema.methods.calculateProgress = function () {
    this.currentAmount = this.contributions.reduce((sum, item) => sum + item.amount, 0);
    if (this.currentAmount >= this.targetAmount) {
        this.status = 'completed';
    } else {
        this.status = 'active';
    }
    return this.currentAmount;
};

const SavingsGoal = mongoose.model('SavingsGoal', savingsGoalSchema);

export default SavingsGoal;
