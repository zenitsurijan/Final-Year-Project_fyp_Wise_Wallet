import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
    user_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    type: {
        type: String,
        required: true,
        enum: ['budget_alert', 'bill_reminder', 'savings_goal', 'summary', 'system', 'other']
    },
    category: {
        type: String
    },
    threshold: {
        type: Number
    },
    message: {
        type: String,
        required: true
    },
    percentage: {
        type: Number
    },
    is_read: {
        type: Boolean,
        default: false
    },
    created_at: {
        type: Date,
        default: Date.now
    }
});

export default mongoose.model('Notification', notificationSchema);
