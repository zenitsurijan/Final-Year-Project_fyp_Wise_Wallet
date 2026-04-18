import User from '../models/User.js';

/**
 * Middleware to check if user is a Family Head
 */
export const isFamilyHead = async (req, res, next) => {
    try {
        const user = await User.findById(req.userId);
        if (!user || user.role !== 'family_head') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Only family head can perform this action.'
            });
        }
        next();
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error checking permissions' });
    }
};

/**
 * Middleware to check if user is in a Family
 */
export const isInFamily = async (req, res, next) => {
    try {
        const user = await User.findById(req.userId);
        if (!user || !user.familyId) {
            return res.status(403).json({
                success: false,
                message: 'You must be part of a family to access this resource'
            });
        }
        next();
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error checking family membership' });
    }
};
