import mongoose from 'mongoose';

const categorySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    icon: {
        type: String,
        required: true,
        default: 'category'
    },
    type: {
        type: String,
        enum: ['expense', 'income'],
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null // null for system defaults
    },
    isDefault: {
        type: Boolean,
        default: false
    }
}, { timestamps: true });

// Ensure unique category names per user (or system-wide for defaults)
categorySchema.index({ name: 1, userId: 1, type: 1 }, { unique: true });

const Category = mongoose.model('Category', categorySchema);
export default Category;
