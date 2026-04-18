import mongoose from 'mongoose';
import User from './models/User.js';
import dotenv from 'dotenv';
dotenv.config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
    // Reset admin password to 'admin123'
    const admin = await User.findOne({ email: 'admin@wisewallet.com' });
    if (admin) {
        admin.password = 'admin123';
        admin.isVerified = true;
        admin.role = 'admin';
        await admin.save(); // This triggers the bcrypt hash
        console.log('Admin password reset to: admin123');
    } else {
        // Create admin if not exists
        const newAdmin = await User.create({
            name: 'System Admin',
            email: 'admin@wisewallet.com',
            password: 'admin123',
            role: 'admin',
            isVerified: true
        });
        console.log('Admin created with password: admin123');
    }
    process.exit(0);
});
