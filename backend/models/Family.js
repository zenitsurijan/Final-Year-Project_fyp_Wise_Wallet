import mongoose from 'mongoose';

const familySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    inviteCode: {
        type: String,
        required: true,
        unique: true,
        length: 6,
        index: true
    },
    headId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    members: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    settings: {
        currency: { type: String, default: 'USD' },
        sharedBudget: { type: Boolean, default: true }
    }
}, {
    timestamps: true
});

// Generate unique 6-digit invite code
familySchema.statics.generateInviteCode = async function () {
    let code;
    let isUnique = false;

    while (!isUnique) {
        code = Math.floor(100000 + Math.random() * 900000).toString();
        const existing = await this.findOne({ inviteCode: code });
        if (!existing) isUnique = true;
    }

    return code;
};

// Method to add member
familySchema.methods.addMember = function (userId) {
    if (!userId) throw new Error('User ID is required');
    if (this.members.some(id => id && id.toString() === userId.toString())) {
        throw new Error('User is already a member');
    }

    this.members.push(userId);
    return this.save();
};

// Method to remove member
familySchema.methods.removeMember = function (userId) {
    if (!userId) return this.save();
    this.members = this.members.filter(id => id && id.toString() !== userId.toString());
    return this.save();
};

const Family = mongoose.model('Family', familySchema);

export default Family;
