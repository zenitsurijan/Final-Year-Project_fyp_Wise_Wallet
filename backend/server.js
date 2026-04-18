console.log('Starting server...');
import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import mongoose from 'mongoose';
import authRoutes from './routes/auth.routes.js';
import transactionRoutes from './routes/transaction.routes.js';
import budgetRoutes from './routes/budget.routes.js';
import savingsRoutes from './routes/savings.routes.js';
import familyRoutes from './routes/family.routes.js';
import reportRoutes from './routes/report.routes.js';
import notificationRoutes from './routes/notification.routes.js';
import billRoutes from './routes/bill.routes.js';
import adminRoutes from './routes/admin.routes.js';
import { initScheduler } from './utils/scheduler.js';

console.log('Imports loaded. Configuring dotenv...');
dotenv.config();

const app = express();

// Middleware
console.log('Setting up middleware...');
app.use(cors({
    origin: true, // Allow all origins (or list your localhost ports)
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));
app.use(express.json());

// Request logger for debugging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Routes
console.log('Setting up routes...');
app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/budget', budgetRoutes);
app.use('/api/savings', savingsRoutes);
app.use('/api/family', familyRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/admin', adminRoutes);

// Serve Static Files
app.use('/uploads', express.static('uploads'));


// Database Connection
const PORT = process.env.PORT || 5002;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/auth_milestone';

console.log(`Retrieved Config - PORT: ${PORT}, MONGO_URI: ${MONGO_URI}`);
console.log('Connecting to MongoDB...');

import Grid from 'gridfs-stream';

// Global variables for GridFS
let gfs, gridfsBucket;

mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('MongoDB Connected successfully');

        // Initialize GridFS
        const conn = mongoose.connection;
        gridfsBucket = new mongoose.mongo.GridFSBucket(conn.db, {
            bucketName: 'uploads'
        });
        gfs = Grid(conn.db, mongoose.mongo);
        gfs.collection('uploads');

        console.log('GridFS Initialized');

        // Start Scheduler
        initScheduler();
        console.log('Automated Scheduler Started');

        app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
    })
    .catch(err => {
        console.error('MongoDB Connection Error:', err.message);
        process.exit(1);
    });

// Export gridfsBucket for use in other files
export { gridfsBucket };
