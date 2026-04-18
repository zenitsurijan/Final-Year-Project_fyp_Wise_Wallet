import mongoose from 'mongoose';

const systemLogSchema = new mongoose.Schema({
    event: { type: String, required: true },
    description: { type: String, required: true },
    level: { 
        type: String, 
        enum: ['info', 'warning', 'error', 'critical'], 
        default: 'info' 
    },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    metadata: { type: Object },
    timestamp: { type: Date, default: Date.now }
});

export default mongoose.model('SystemLog', systemLogSchema);
