import Bill from '../models/Bill.js';
import User from '../models/User.js';

// Create Bill
export const createBill = async (req, res) => {
    try {
        const { name, amount, dueDate, recurrence, category } = req.body;
        const bill = new Bill({
            userId: req.userId,
            name,
            amount,
            dueDate,
            recurrence,
            category
        });
        await bill.save();
        res.status(201).json({ success: true, bill });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get Bills
export const getBills = async (req, res) => {
    try {
        const bills = await Bill.find({ userId: req.userId }).sort({ dueDate: 1 });
        res.json({ success: true, bills });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update Bill
export const updateBill = async (req, res) => {
    try {
        const bill = await Bill.findOneAndUpdate(
            { _id: req.params.id, userId: req.userId },
            req.body,
            { new: true }
        );
        if (!bill) return res.status(404).json({ success: false, message: 'Bill not found' });
        res.json({ success: true, bill });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete Bill
export const deleteBill = async (req, res) => {
    try {
        const bill = await Bill.findOneAndDelete({ _id: req.params.id, userId: req.userId });
        if (!bill) return res.status(404).json({ success: false, message: 'Bill not found' });
        res.json({ success: true, message: 'Bill deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
