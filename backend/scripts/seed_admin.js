import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from '../models/User.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '../.env') });

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/auth_milestone';

async function seedAdmin() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(MONGO_URI);
        console.log('Connected.');

        const adminEmail = 'admin@gmail.com';
        const adminPassword = 'AdminPassword123'; // User should change this later

        const existingAdmin = await User.findOne({ email: adminEmail });
        if (existingAdmin) {
            console.log('Admin user already exists. Updating role...');
            existingAdmin.role = 'admin';
            await existingAdmin.save();
            console.log('Admin user updated successfully.');
        } else {
            console.log('Creating new Admin user...');
            const admin = new User({
                name: 'System Admin',
                email: adminEmail,
                password: adminPassword,
                role: 'admin',
                isVerified: true
            });
            await admin.save();
            console.log('Admin user created successfully!');
            console.log('Email:', adminEmail);
            console.log('Password:', adminPassword);
        }

        process.exit(0);
    } catch (error) {
        console.error('Error seeding admin:', error);
        process.exit(1);
    }
}

seedAdmin();
