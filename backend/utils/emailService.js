import nodemailer from 'nodemailer';
import dotenv from 'dotenv';
dotenv.config();

// Create reusable transporter object using the default SMTP transport
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Send OTP Verification Email
 * @param {string} email - Recipient email
 * @param {string} otp - Verification code
 */
export const sendVerificationEmail = async (email, otp) => {
    const mailOptions = {
        from: `"WiseWallet Milestone" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: 'Verify your WiseWallet Account',
        html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
            <div style="background-color: #6200EA; padding: 20px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0;">Wise Wallet</h1>
            </div>
            <div style="padding: 30px; background-color: #ffffff;">
                <h2 style="color: #333333; margin-top: 0;">Welcome to WiseWallet!</h2>
                <p style="color: #666666; font-size: 16px; line-height: 1.5;">
                    Thank you for registering. To verify your account, please use the following One Time Password (OTP):
                </p>
                <div style="background-color: #f5f5f5; padding: 15px; border-radius: 4px; text-align: center; margin: 20px 0;">
                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #6200EA;">${otp}</span>
                </div>
                <p style="color: #666666; font-size: 14px;">
                    This code will expire in 10 minutes. Do not share this code with anyone.
                </p>
                <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 30px 0;">
                <p style="color: #999999; font-size: 12px; text-align: center;">
                    If you did not request this email, please ignore it.
                </p>
            </div>
        </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`✅ Email sent successfully to ${email}`);
        return true;
    } catch (error) {
        console.error('❌ Email Sending Error:', error.message);
        return false;
    }
};

/**
 * Send Family Invite Email
 * @param {string} email - Recipient email
 * @param {string} inviteCode - 6-digit family invite code
 * @param {string} familyName - Name of the family group
 * @param {string} senderName - Name of the person sending the invite
 */
export const sendFamilyInviteEmail = async (email, inviteCode, familyName, senderName) => {
    const mailOptions = {
        from: `"WiseWallet" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: `${senderName} invited you to join "${familyName}" on WiseWallet!`,
        html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
            <div style="background: linear-gradient(135deg, #6200EA 0%, #3700B3 100%); padding: 30px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0;">👨‍👩‍👧‍👦 Family Invite</h1>
            </div>
            <div style="padding: 30px; background-color: #ffffff;">
                <h2 style="color: #333333; margin-top: 0;">You're invited!</h2>
                <p style="color: #666666; font-size: 16px; line-height: 1.6;">
                    <strong>${senderName}</strong> has invited you to join their family group 
                    <strong>"${familyName}"</strong> on WiseWallet.
                </p>
                <p style="color: #666666; font-size: 16px; line-height: 1.6;">
                    Use the code below to join and start tracking finances together:
                </p>
                <div style="background-color: #f0e6ff; padding: 20px; border-radius: 8px; text-align: center; margin: 25px 0;">
                    <span style="font-size: 40px; font-weight: bold; letter-spacing: 8px; color: #6200EA;">${inviteCode}</span>
                </div>
                <p style="color: #666666; font-size: 14px; text-align: center;">
                    Open the WiseWallet app → Go to Family → Join with Code
                </p>
                <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 30px 0;">
                <p style="color: #999999; font-size: 12px; text-align: center;">
                    If you don't have the app, download it from your app store.
                </p>
            </div>
        </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`✅ Family invite email sent to ${email}`);
        return { success: true };
    } catch (error) {
        console.error('❌ Family Invite Email Error:', error.message);
        return { success: false, error: error.message };
    }
};
