/**
 * Webhook Routes
 *
 * Handle Dodo Payments webhooks
 */

const express = require('express');
const DodoPayments = require('dodopayments');
const pool = require('../config/database');
const { generateLicenseKey } = require('../utils/keygen');
const { sendLicenseEmail } = require('../services/email');

const router = express.Router();

// Initialize Dodo Payments client
const dodo = new DodoPayments({
    bearerToken: process.env.DODO_PAYMENTS_API_KEY,
    environment: process.env.DODO_PAYMENTS_ENVIRONMENT,
    webhookKey: process.env.DODO_PAYMENTS_WEBHOOK_KEY
});

// Map Dodo product IDs to tiers
const PRODUCT_TO_TIER = {
    [process.env.DODO_PRODUCT_SOLO]: 'solo',
    [process.env.DODO_PRODUCT_MULTIPLE]: 'multiple',
    [process.env.DODO_PRODUCT_ENTERPRISE]: 'enterprise'
};

const TIER_MAX_MACHINES = {
    solo: 1,
    multiple: 3,
    enterprise: 6
};

// ============================================
// POST /webhooks/dodo
// Handle Dodo Payments webhook events
// ============================================
const processedWebhookIds = new Set();

router.post('/dodo', async (req, res) => {
    let event;
    const webhookId = req.headers['webhook-id'];

    try {
        // Verify webhook signature
        event = await dodo.webhooks.unwrap(req.body.toString(), {
            headers: {
                'webhook-id': req.headers['webhook-id'],
                'webhook-signature': req.headers['webhook-signature'],
                'webhook-timestamp': req.headers['webhook-timestamp']
            }
        });
    } catch (err) {
        console.error('Webhook signature verification failed:', err.message);
        return res.status(401).send(`Webhook Error: ${err.message}`);
    }

    if (webhookId) {
        if (processedWebhookIds.has(webhookId)) {
            return res.json({ received: true, duplicate: true });
        }
        processedWebhookIds.add(webhookId);
    }

    // Handle the event
    try {
        switch (event.type) {
            case 'payment.succeeded':
                await handlePaymentSucceeded(event);
                break;

            case 'payment.failed':
                console.log('Payment failed:', event.data?.payment_id || event.data?.id);
                break;

            default:
                console.log(`Unhandled event type: ${event.type}`);
        }

        res.json({ received: true });
    } catch (error) {
        console.error('Error processing webhook:', error);
        res.status(500).json({ error: 'Webhook processing failed' });
    }
});

/**
 * Handle successful payment
 */
async function handlePaymentSucceeded(event) {
    const payload = event?.data || event?.payload?.data || {};
    const payment = payload?.object || payload;

    console.log('Processing payment:', payment?.payment_id || payment?.id);

    // Get customer email
    const email = payment?.customer?.email || payment?.customer_email;
    if (!email) {
        console.error('No email found in payment payload');
        return;
    }

    const metadata = payment?.metadata || payment?.object?.metadata || {};
    const normalizeTier = (value) => {
        if (typeof value !== 'string') return undefined;
        const candidate = value.toLowerCase();
        return TIER_MAX_MACHINES[candidate] ? candidate : undefined;
    };
    const tierFromMetadata = normalizeTier(metadata.tier);

    const productId = payment?.product_id
        || payment?.product?.product_id
        || payment?.product?.id
        || payment?.items?.[0]?.product_id
        || payment?.product_cart?.[0]?.product_id;
    const tierFromProduct = productId ? normalizeTier(PRODUCT_TO_TIER[productId]) : undefined;

    const finalTier = tierFromMetadata || tierFromProduct || 'solo';
    const maxMachines = TIER_MAX_MACHINES[finalTier];

    // Generate license key
    const licenseKey = generateLicenseKey(finalTier);

    // Store in database
    try {
        await pool.query(
            `INSERT INTO licenses (license_key, tier, email, max_machines, dodo_payment_id, dodo_customer_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
                licenseKey,
                finalTier,
                email,
                maxMachines,
                payment?.payment_id || payment?.id,
                payment?.customer?.customer_id || payment?.customer?.id
            ]
        );

        console.log(`License created: ${licenseKey} for ${email} (${finalTier})`);

        // Send license email
        await sendLicenseEmail(email, licenseKey, finalTier);

        console.log(`License email sent to ${email}`);

    } catch (error) {
        if (error.code === '23505') {
            // Duplicate - webhook might have been processed already
            console.log('License already exists for this session');
        } else {
            throw error;
        }
    }
}

module.exports = router;
