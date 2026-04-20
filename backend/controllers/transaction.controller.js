import Transaction from '../models/Transaction.js';
import Budget from '../models/Budget.js';
import User from '../models/User.js';
import Category from '../models/Category.js';
import mongoose from 'mongoose';
import { sendPushNotification } from '../services/notification.service.js';
import { checkBudgetThresholds } from '../utils/budgetAlerts.js';
import path from 'path';
import { v2 as cloudinary } from 'cloudinary';

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

export const createTransaction = async (req, res) => {
    try {
        const { type, amount, category, customCategory, description, date, receiptImage, receiptImageId } = req.body;
        const transaction = new Transaction({
            userId: req.userId,
            type, amount, category,
            customCategory: customCategory || null,
            description: description || '',
            date: date || new Date(),
            receiptImage: receiptImage || null,
            receiptImageId: receiptImageId || null
        });
        await transaction.save();
        if (type === 'expense') {
            await checkBudgetThresholds(req.userId, category || customCategory, amount);
        }
        res.status(201).json({ success: true, transaction });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getTransactions = async (req, res) => {
    try {
        const { page = 1, limit = 20, type, category, startDate, endDate, hasReceipt, search, minAmount, maxAmount, scope } = req.query;
        let query = { userId: req.userId };
        if (scope === 'family' && req.user.familyId) {
            const familyMembers = await User.find({ familyId: req.user.familyId }).select('_id');
            const memberIds = familyMembers.map(m => m._id);
            query = { userId: { $in: memberIds } };
        }
        if (type) query.type = type;
        if (category) query.category = category;
        if (startDate || endDate) {
            query.date = {};
            if (startDate) query.date.$gte = new Date(startDate);
            if (endDate) query.date.$lte = new Date(endDate);
        }
        if (hasReceipt === 'true') query.receiptImageId = { $ne: null };
        if (minAmount || maxAmount) {
            query.amount = {};
            if (minAmount) query.amount.$gte = parseFloat(minAmount);
            if (maxAmount) query.amount.$lte = parseFloat(maxAmount);
        }
        if (search) query.description = { $regex: search, $options: 'i' };
        const transactions = await Transaction.find(query)
            .sort({ date: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));
        const total = await Transaction.countDocuments(query);
        res.json({ success: true, transactions, pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) } });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getTransaction = async (req, res) => {
    try {
        const transaction = await Transaction.findOne({ _id: req.params.id, userId: req.userId });
        if (!transaction) return res.status(404).json({ success: false, message: 'Transaction not found' });
        res.json({ success: true, transaction });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateTransaction = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ success: false, message: 'Invalid Transaction ID' });
        const updateData = { ...req.body };
        delete updateData.userId;
        const transaction = await Transaction.findOneAndUpdate(
            { _id: id, userId: req.userId },
            updateData,
            { new: true, runValidators: true }
        );
        if (!transaction) return res.status(404).json({ success: false, message: 'Transaction not found or unauthorized' });
        if (transaction.type === 'expense') {
            await checkBudgetThresholds(req.userId, transaction.category || transaction.customCategory, 0);
        }
        res.json({ success: true, transaction });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteTransaction = async (req, res) => {
    try {
        const transaction = await Transaction.findOneAndDelete({ _id: req.params.id, userId: req.userId });
        if (!transaction) return res.status(404).json({ success: false, message: 'Transaction not found' });
        res.json({ success: true, message: 'Transaction deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getTransactionSummary = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        const matchQuery = { userId: new mongoose.Types.ObjectId(req.userId) };
        if (startDate || endDate) {
            matchQuery.date = {};
            if (startDate) matchQuery.date.$gte = new Date(startDate);
            if (endDate) matchQuery.date.$lte = new Date(endDate);
        }
        const summary = await Transaction.aggregate([
            { $match: matchQuery },
            { $group: { _id: '$type', total: { $sum: '$amount' }, count: { $sum: 1 } } }
        ]);
        const result = { income: { total: 0, count: 0 }, expense: { total: 0, count: 0 } };
        summary.forEach(item => { result[item._id] = { total: item.total, count: item.count }; });
        result.balance = result.income.total - result.expense.total;
        res.json({ success: true, summary: result });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getCategories = async (req, res) => {
    try {
        const systemCategories = await Category.find({ isDefault: true, userId: null });
        const userCategories = await Category.find({ userId: req.userId });
        const allCategories = [...systemCategories, ...userCategories];
        res.status(200).json({ success: true, categories: allCategories, customCategories: userCategories.map(c => c.name) });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const addCategory = async (req, res) => {
    try {
        const { name, icon, type } = req.body;
        if (!name) return res.status(400).json({ success: false, message: 'Category name is required' });
        if (!type) return res.status(400).json({ success: false, message: 'Category type is required' });
        const existing = await Category.findOne({ name, userId: req.userId, type });
        if (existing) return res.status(400).json({ success: false, message: 'Category already exists' });
        const newCategory = new Category({ name, icon: icon || 'category', type, userId: req.userId, isDefault: false });
        await newCategory.save();
        const systemCategories = await Category.find({ isDefault: true });
        const userCategories = await Category.find({ userId: req.userId });
        res.status(200).json({ success: true, message: 'Category added', categories: [...systemCategories, ...userCategories] });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteCategory = async (req, res) => {
    try {
        const { category } = req.params;
        const result = await Category.findOneAndDelete({
            $or: [{ _id: mongoose.isValidObjectId(category) ? category : null }, { name: category }],
            userId: req.userId
        });
        if (!result) return res.status(404).json({ success: false, message: 'Custom category not found or cannot delete default categories' });
        const systemCategories = await Category.find({ isDefault: true });
        const userCategories = await Category.find({ userId: req.userId });
        res.status(200).json({ success: true, message: 'Category deleted', categories: [...systemCategories, ...userCategories] });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const uploadImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No file uploaded' });
        }
        const result = await new Promise((resolve, reject) => {
            cloudinary.uploader.upload_stream(
                { folder: 'wise-wallet-receipts' },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result);
                }
            ).end(req.file.buffer);
        });
        res.status(201).json({
            success: true,
            fileId: result.public_id,
            filename: result.public_id,
            url: result.secure_url
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getImage = async (req, res) => {
    try {
        const publicId = req.params.id;
        const url = cloudinary.url(publicId);
        res.redirect(url);
    } catch (error) {
        res.status(404).json({ success: false, message: 'Image not found' });
    }
};