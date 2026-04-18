import express from 'express';
import {
    createGoal,
    getGoals,
    addContribution,
    deleteGoal
} from '../controllers/savings.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(protect);

router.post('/', createGoal);
router.get('/', getGoals);
router.post('/:id/contribute', addContribution);
router.delete('/:id', deleteGoal);

export default router;
