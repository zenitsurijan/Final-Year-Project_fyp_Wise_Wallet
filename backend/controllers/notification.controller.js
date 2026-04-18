import Notification from '../models/Notification.js';
import User from '../models/User.js';

// Update FCM Token
export const updateFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;
        if (!fcmToken) {
            return res.status(400).json({ success: false, message: 'Token is required' });
        }

        await User.findByIdAndUpdate(req.userId, { fcmToken });

        res.json({ success: true, message: 'FCM token updated successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get User Notifications
export const getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ user_id: req.userId })
            .sort({ created_at: -1 })
            .limit(50);

        res.json({ success: true, notifications });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Mark as Read
export const markAsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            { user_id: req.userId, is_read: false },
            { is_read: true }
        );
        res.json({ success: true, message: 'Notifications marked as read' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
