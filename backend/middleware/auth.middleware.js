import jwt from 'jsonwebtoken';

import User from '../models/User.js';

export const protect = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        console.log(`Auth check for ${req.url}: ${authHeader ? 'Token present' : 'No token'}`);

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'No token provided' });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Fetch user and attach to request
        const user = await User.findById(decoded.id);
        if (!user) {
            return res.status(401).json({ success: false, message: 'User not found' });
        }

        req.user = user;
        req.userId = user._id.toString(); // Keep userId for compatibility
        next();
    } catch (error) {
        return res.status(401).json({ success: false, message: 'Invalid or expired token' });
    }
};

// Alias for backward compatibility
export const authMiddleware = protect;

// Role-based access control middleware
export const authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `User role ${req.user.role} is not authorized to access this route`
            });
        }
        next();
    };
};
