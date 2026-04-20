import express from 'express';
import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import path from 'path';
import {
    createTransaction, getTransactions, getTransaction,
    updateTransaction, deleteTransaction, getTransactionSummary,
    getCategories, addCategory, deleteCategory, getImage, uploadImage
} from '../controllers/transaction.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import dotenv from 'dotenv';
dotenv.config();

const router = express.Router();

const storage = multer.memoryStorage();
const upload = multer({ storage });

router.use(protect);
router.post('/upload', upload.single('image'), uploadImage);
router.get('/image/:id', getImage);
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