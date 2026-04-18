import express from 'express';
import {
    createFamily,
    joinFamily,
    sendInviteEmail,
    getFamilyDashboard,
    getFamilyMembers,
    getMemberSpendingReport,
    removeMember,
    transferHeadRole,
    leaveFamily,
    deleteFamily,
    updateFamilySettings
} from '../controllers/family.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import { isFamilyHead, isInFamily } from '../middleware/rbac.middleware.js';

const router = express.Router();

router.use(protect);

// Setup
router.post('/create', createFamily);
router.post('/join', joinFamily);
router.post('/invite', isInFamily, sendInviteEmail);

// Dashboard & Members (All authenticated family members)
router.get('/dashboard', isInFamily, getFamilyDashboard);
router.get('/members', isInFamily, getFamilyMembers);
router.get('/member-report/:memberId', isInFamily, getMemberSpendingReport);

// Member Management
router.delete('/members/:userId', isInFamily, removeMember);
router.put('/transfer-head', isFamilyHead, transferHeadRole);
router.post('/leave', isInFamily, leaveFamily);
router.delete('/', isFamilyHead, deleteFamily);
router.put('/settings', isFamilyHead, updateFamilySettings);

export default router;
