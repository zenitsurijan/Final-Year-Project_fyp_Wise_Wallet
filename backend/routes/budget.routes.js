import express from 'express';
import * as budgetController from '../controllers/budget.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(protect); // All routes require authentication

router.post('/', budgetController.createBudget);
router.get('/current', budgetController.getCurrentBudget);
router.get('/status', budgetController.getBudgetStatus);
router.get('/alerts', budgetController.getBudgetAlerts);
router.get('/overspending', budgetController.getOverspendingAnalysis);
router.post('/family/set', budgetController.setFamilyBudget);
router.get('/family', budgetController.getFamilyBudget);
router.get('/:month', budgetController.getBudgetByMonth);
router.put('/:id', budgetController.updateBudget);
router.delete('/:id', budgetController.deleteBudget);

export default router;
