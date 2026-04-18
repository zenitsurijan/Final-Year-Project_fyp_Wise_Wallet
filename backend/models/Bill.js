import mongoose from 'mongoose';

const billSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    },
    dueDate: {
        type: Date,
        required: true
    },
    category: {
        type: String,
        default: 'General'
    },
    recurrence: {
        type: String,
        enum: ['none', 'weekly', 'monthly', 'yearly'],
        default: 'none'
    },
    isPaid: {
        type: Boolean,
        default: false
    },
    remindersSent: {
        type: [String], // ['3_days', '1_day', 'today']
        default: []
    }
}, { timestamps: true });

const Bill = mongoose.model('Bill', billSchema);
export default Bill;
