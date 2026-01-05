/**
 * Email Service
 *
 * Sends license emails using Resend
 */

const { Resend } = require('resend');
const fs = require('fs');
const path = require('path');

const resend = new Resend(process.env.RESEND_API_KEY);

// Tier display names and machine counts
const TIER_INFO = {
    solo: { name: 'Solo', maxMachines: 1 },
    multiple: { name: 'Multiple', maxMachines: 3 },
    enterprise: { name: 'Enterprise', maxMachines: 6 }
};

/**
 * Load and process the email template
 * @param {string} licenseKey - The license key
 * @param {string} tier - The tier name
 * @returns {string} Processed HTML
 */
function getEmailHtml(licenseKey, tier) {
    const templatePath = path.join(__dirname, '../../email-templates/license-email.html');

    // Try to load custom template, fall back to inline template
    let html;
    try {
        html = fs.readFileSync(templatePath, 'utf8');
    } catch (error) {
        // Fallback template if file not found
        html = getFallbackTemplate();
    }

    const tierInfo = TIER_INFO[tier] || TIER_INFO.solo;
    const purchaseDate = new Date().toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });

    // Replace placeholders
    return html
        .replace(/{{LICENSE_KEY}}/g, licenseKey)
        .replace(/{{TIER_NAME}}/g, tierInfo.name)
        .replace(/{{MAX_MACHINES}}/g, tierInfo.maxMachines.toString())
        .replace(/{{PURCHASE_DATE}}/g, purchaseDate);
}

/**
 * Fallback email template
 */
function getFallbackTemplate() {
    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Your MomentumBar License</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background-color: #f5f5f5; padding: 40px;">
    <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h1 style="color: #333; margin-bottom: 24px;">Thank you for purchasing MomentumBar!</h1>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Your license key for <strong>{{TIER_NAME}}</strong> is:
        </p>

        <div style="background: #f8f9fa; border: 2px dashed #e0e0e0; border-radius: 8px; padding: 24px; text-align: center; margin: 24px 0;">
            <code style="font-size: 24px; font-weight: bold; letter-spacing: 2px;">{{LICENSE_KEY}}</code>
        </div>

        <h2 style="color: #333; font-size: 18px; margin-top: 32px;">How to Activate</h2>
        <ol style="color: #555; font-size: 15px; line-height: 1.8;">
            <li>Open MomentumBar on your Mac</li>
            <li>Go to Settings → License</li>
            <li>Enter your license key</li>
            <li>Click Activate</li>
        </ol>

        <p style="color: #555; font-size: 14px; margin-top: 32px; padding-top: 24px; border-top: 1px solid #eee;">
            Plan: {{TIER_NAME}} • Machines: {{MAX_MACHINES}} Mac(s) • Purchase Date: {{PURCHASE_DATE}}
        </p>

        <p style="color: #999; font-size: 13px; margin-top: 24px;">
            Need help? Contact us at support@momentumbar.app
        </p>
    </div>
</body>
</html>
`;
}

/**
 * Send license email to customer
 * @param {string} email - Customer email
 * @param {string} licenseKey - Generated license key
 * @param {string} tier - License tier
 */
async function sendLicenseEmail(email, licenseKey, tier) {
    const html = getEmailHtml(licenseKey, tier);
    const tierInfo = TIER_INFO[tier] || TIER_INFO.solo;

    try {
        const { data, error } = await resend.emails.send({
            from: process.env.EMAIL_FROM || 'MomentumBar <noreply@momentumbar.app>',
            to: email,
            subject: `Your MomentumBar ${tierInfo.name} License Key`,
            html: html
        });

        if (error) {
            console.error('Email send error:', error);
            throw new Error(`Failed to send email: ${error.message}`);
        }

        console.log(`Email sent successfully: ${data.id}`);
        return data;

    } catch (error) {
        console.error('Email service error:', error);
        throw error;
    }
}

/**
 * Send a test email (for debugging)
 */
async function sendTestEmail(email) {
    return sendLicenseEmail(email, 'SOLO-TEST1-TEST2-TEST3', 'solo');
}

module.exports = {
    sendLicenseEmail,
    sendTestEmail
};
