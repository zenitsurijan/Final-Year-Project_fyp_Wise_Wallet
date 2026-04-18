import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Category from '../models/Category.js';

dotenv.config();

const defaultCategories = [
    // Expenses
    { name: 'Food', icon: 'restaurant', type: 'expense', isDefault: true },
    { name: 'Transport', icon: 'directions_car', type: 'expense', isDefault: true },
    { name: 'Shopping', icon: 'shopping_bag', type: 'expense', isDefault: true },
    { name: 'Bills', icon: 'receipt_long', type: 'expense', isDefault: true },
    { name: 'Entertainment', icon: 'movie', type: 'expense', isDefault: true },
    { name: 'Health', icon: 'medical_services', type: 'expense', isDefault: true },
    { name: 'Education', icon: 'school', type: 'expense', isDefault: true },
    { name: 'Other', icon: 'category', type: 'expense', isDefault: true },

    // Income
    { name: 'Salary', icon: 'work', type: 'income', isDefault: true },
    { name: 'Freelance', icon: 'computer', type: 'income', isDefault: true },
    { name: 'Investment', icon: 'trending_up', type: 'income', isDefault: true },
    { name: 'Gift', icon: 'card_giftcard', type: 'income', isDefault: true },
    { name: 'Other Income', icon: 'payments', type: 'income', isDefault: true },
];

const seedCategories = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/auth_milestone');
        console.log('Connected to MongoDB');

        // Clear existing defaults to avoid duplicates or stale data
        await Category.deleteMany({ isDefault: true });

        await Category.insertMany(defaultCategories);
        console.log('Default categories seeded successfully');

        process.exit(0);
    } catch (error) {
        console.error('Error seeding categories:', error);
        process.exit(1);
    }
};

seedCategories();
