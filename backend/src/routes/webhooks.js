/**
 * Webhook Routes
 *
 * Handle Stripe payment webhooks
 */

const express = require('express');
const Stripe = require('stripe');
const pool = require('../config/database');
const { generateLicenseKey } = require('../utils/keygen');
const { sendLicenseEmail } = require('../services/email');

const router = express.Router();

// Initialize Stripe
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

// Map Stripe price IDs to tiers
const PRICE_TO_TIER = {
    [process.env.STRIPE_PRICE_SOLO]: 'solo',
    [process.env.STRIPE_PRICE_MULTIPLE]: 'multiple',
    [process.env.STRIPE_PRICE_ENTERPRISE]: 'enterprise'
};

const TIER_MAX_MACHINES = {
    solo: 1,
    multiple: 3,
    enterprise: 6
};

// ============================================
// POST /webhooks/stripe
// Handle Stripe webhook events
// ============================================
router.post('/stripe', async (req, res) => {
    let event;

    try {
        // Verify webhook signature
        const sig = req.headers['stripe-signature'];
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
        console.error('Webhook signature verification failed:', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle the event
    try {
        switch (event.type) {
            case 'checkout.session.completed':
                await handleCheckoutComplete(event.data.object);
                break;

            case 'payment_intent.succeeded':
                // Can also handle direct payment intents if needed
                console.log('Payment succeeded:', event.data.object.id);
                break;

            case 'payment_intent.payment_failed':
                console.log('Payment failed:', event.data.object.id);
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
 * Handle successful checkout session
 */
async function handleCheckoutComplete(session) {
    console.log('Processing checkout session:', session.id);

    // Get customer email
    const email = session.customer_email || session.customer_details?.email;
    if (!email) {
        console.error('No email found in checkout session');
        return;
    }

    // Get the line items to determine the tier
    const lineItems = await stripe.checkout.sessions.listLineItems(session.id);
    const priceId = lineItems.data[0]?.price?.id;

    const tier = PRICE_TO_TIER[priceId];
    if (!tier) {
        console.error('Unknown price ID:', priceId);
        // Default to solo if unknown
    }

    const finalTier = tier || 'solo';
    const maxMachines = TIER_MAX_MACHINES[finalTier];

    // Generate license key
    const licenseKey = generateLicenseKey(finalTier);

    // Store in database
    try {
        await pool.query(
            `INSERT INTO licenses (license_key, tier, email, max_machines, stripe_session_id, stripe_customer_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [licenseKey, finalTier, email, maxMachines, session.id, session.customer]
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
