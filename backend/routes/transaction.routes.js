import express from 'express';
import multer from 'multer';
import { GridFsStorage } from 'multer-gridfs-storage';
import path from 'path';
import {
    createTransaction,
    getTransactions,
    getTransaction,
    updateTransaction,
    deleteTransaction,
    getTransactionSummary,
    getCategories,
    addCategory,
    deleteCategory,
    getImage,
    uploadImage
} from '../controllers/transaction.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import dotenv from 'dotenv';
dotenv.config();

const router = express.Router();

// Configure Multer for Disk Storage (Simplest & Most Reliable for FYP)
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'receipt-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage });

// All routes require authentication
router.use(protect);

// Image handling
router.post('/upload', upload.single('image'), uploadImage);
router.get('/image/:id', getImage);

// Transaction CRUD
router.post('/', createTransaction);
router.get('/', getTransactions);
router.get('/summary', getTransactionSummary);
router.get('/categories', getCategories);
router.post('/categories', addCategory);
router.delete('/categories/:category', deleteCategory);
router.get('/:id', getTransaction);
router.put('/:id', updateTransaction);
router.delete('/:id', deleteTransaction);

export default router;
