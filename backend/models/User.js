import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true, select: false },
    isVerified: { type: Boolean, default: false },
    verificationCode: String,
    verificationCodeExpire: Date,
    familyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Family', default: null },
    role: { type: String, enum: ['user', 'family_member', 'family_head', 'admin'], default: 'user' },
    isActive: { type: Boolean, default: true },
    fcmToken: { type: String, default: null },
    customCategories: { type: [String], default: [] }
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

// Match password
userSchema.methods.comparePassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// Get public profile
userSchema.methods.getPublicProfile = function () {
    return {
        _id: this._id,
        name: this.name,
        email: this.email,
        isVerified: this.isVerified,
        familyId: this.familyId,
        role: this.role,
    };
};

const User = mongoose.model('User', userSchema);
export default User;
