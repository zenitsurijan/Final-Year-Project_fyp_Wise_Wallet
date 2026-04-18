import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin
try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
        let serviceAccount;
        if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
            serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
        } else {
            // Assume it's a path if not JSON
            // serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH); 
            // In ES modules we use direct import or fs.readFileSync
        }

        if (serviceAccount && admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log('Firebase Admin initialized successfully');
        }
    }
} catch (error) {
    console.error('Failed to initialize Firebase Admin:', error.message);
}

export const sendPushNotification = async (token, title, body, data = {}) => {
    try {
        if (!token) {
            console.log('No FCM token provided, skipping notification.');
            return;
        }

        // Always log for transparency
        console.log(`[PUSH NOTIFICATION] To: ${token} | ${title}: ${body}`);

        if (admin.apps.length > 0) {
            const message = {
                notification: { title, body },
                data: data,
                token
            };

            const response = await admin.messaging().send(message);
            console.log('Successfully sent message:', response);
            return response;
        } else {
            console.log('⚠️ Firebase Admin not initialized. Mocking push notification:');
            console.log(`[MOCK PUSH] Title: ${title} | Body: ${body}`);
            return { success: true, message: 'Mock notification sent' };
        }
    } catch (error) {
        console.error('Error sending push notification:', error);
    }
};
