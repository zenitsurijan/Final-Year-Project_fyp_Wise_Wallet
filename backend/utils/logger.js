import SystemLog from '../models/SystemLog.js';

/**
 * Logs a system event to the database.
 * @param {Object} params
 * @param {string} params.event - Short title of the event (e.g., 'USER_REGISTER')
 * @param {string} params.description - Detailed description
 * @param {string} [params.level='info'] - Severity level (info, warning, error, critical)
 * @param {string} [params.userId] - ID of the user involved
 * @param {Object} [params.metadata] - Extra data for debugging
 */
export const logEvent = async ({ event, description, level = 'info', userId = null, metadata = {} }) => {
    try {
        const log = new SystemLog({
            event,
            description,
            level,
            userId,
            metadata
        });
        await log.save();
        console.log(`[SYSTEM LOG] ${level.toUpperCase()}: ${event} - ${description}`);
    } catch (error) {
        console.error('Failed to save system log:', error);
    }
};
