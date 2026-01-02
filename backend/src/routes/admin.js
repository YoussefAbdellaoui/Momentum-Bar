/**
 * Admin Routes for License Management
 *
 * These endpoints allow you to:
 * - View all licenses
 * - Revoke/reactivate licenses
 * - Manually create licenses
 * - View license statistics
 *
 * IMPORTANT: Protect these routes with authentication in production!
 */

const express = require('express');
const pool = require('../config/database');
const { generateLicenseKey } = require('../utils/keygen');
const { sendLicenseEmail } = require('../services/email');

const router = express.Router();

// Simple API key authentication middleware
// In production, use proper authentication (JWT, session, etc.)
const adminAuth = (req, res, next) => {
    const apiKey = req.headers['x-admin-key'];

    if (apiKey !== process.env.ADMIN_API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }

    next();
};

router.use(adminAuth);

// ============================================
// GET /admin/licenses - List all licenses
// ============================================
router.get('/licenses', async (req, res) => {
    try {
        const { status, tier, search, page = 1, limit = 50 } = req.query;
        const offset = (page - 1) * limit;

        let query = `
            SELECT
                l.*,
                COUNT(am.id) as activated_count
            FROM licenses l
            LEFT JOIN activated_machines am ON l.id = am.license_id
        `;

        const conditions = [];
        const params = [];

        if (status) {
            params.push(status);
            conditions.push(`l.status = $${params.length}`);
        }

        if (tier) {
            params.push(tier);
            conditions.push(`l.tier = $${params.length}`);
        }

        if (search) {
            params.push(`%${search}%`);
            conditions.push(`(l.email ILIKE $${params.length} OR l.license_key ILIKE $${params.length})`);
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }

        query += `
            GROUP BY l.id
            ORDER BY l.created_at DESC
            LIMIT $${params.length + 1} OFFSET $${params.length + 2}
        `;

        params.push(limit, offset);

        const result = await pool.query(query, params);

        // Get total count
        let countQuery = 'SELECT COUNT(*) FROM licenses l';
        if (conditions.length > 0) {
            countQuery += ' WHERE ' + conditions.join(' AND ');
        }
        const countResult = await pool.query(countQuery, params.slice(0, -2));
        const total = parseInt(countResult.rows[0].count);

        res.json({
            licenses: result.rows,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });

    } catch (error) {
        console.error('Error listing licenses:', error);
        res.status(500).json({ error: 'Failed to list licenses' });
    }
});

// ============================================
// GET /admin/licenses/:id - Get license details
// ============================================
router.get('/licenses/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const license = await pool.query(
            'SELECT * FROM licenses WHERE id = $1',
            [id]
        );

        if (!license.rows[0]) {
            return res.status(404).json({ error: 'License not found' });
        }

        const machines = await pool.query(
            'SELECT * FROM activated_machines WHERE license_id = $1 ORDER BY activated_at DESC',
            [id]
        );

        res.json({
            license: license.rows[0],
            machines: machines.rows
        });

    } catch (error) {
        console.error('Error getting license:', error);
        res.status(500).json({ error: 'Failed to get license' });
    }
});

// ============================================
// POST /admin/licenses - Create license manually
// ============================================
router.post('/licenses', async (req, res) => {
    try {
        const { email, tier, sendEmail = true } = req.body;

        if (!email || !tier) {
            return res.status(400).json({ error: 'Email and tier are required' });
        }

        const validTiers = ['solo', 'multiple', 'enterprise'];
        if (!validTiers.includes(tier)) {
            return res.status(400).json({ error: 'Invalid tier' });
        }

        const licenseKey = generateLicenseKey(tier);
        const maxMachines = { solo: 1, multiple: 3, enterprise: 6 }[tier];

        const result = await pool.query(
            `INSERT INTO licenses (license_key, tier, email, max_machines)
             VALUES ($1, $2, $3, $4)
             RETURNING *`,
            [licenseKey, tier, email, maxMachines]
        );

        const license = result.rows[0];

        // Send email if requested
        if (sendEmail) {
            await sendLicenseEmail(email, licenseKey, tier);
        }

        res.status(201).json({
            success: true,
            license,
            emailSent: sendEmail
        });

    } catch (error) {
        console.error('Error creating license:', error);
        res.status(500).json({ error: 'Failed to create license' });
    }
});

// ============================================
// PATCH /admin/licenses/:id - Update license
// ============================================
router.patch('/licenses/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, maxMachines } = req.body;

        const updates = [];
        const params = [id];

        if (status) {
            params.push(status);
            updates.push(`status = $${params.length}`);
        }

        if (maxMachines) {
            params.push(maxMachines);
            updates.push(`max_machines = $${params.length}`);
        }

        if (updates.length === 0) {
            return res.status(400).json({ error: 'No updates provided' });
        }

        updates.push('updated_at = NOW()');

        const result = await pool.query(
            `UPDATE licenses SET ${updates.join(', ')} WHERE id = $1 RETURNING *`,
            params
        );

        if (!result.rows[0]) {
            return res.status(404).json({ error: 'License not found' });
        }

        res.json({ success: true, license: result.rows[0] });

    } catch (error) {
        console.error('Error updating license:', error);
        res.status(500).json({ error: 'Failed to update license' });
    }
});

// ============================================
// POST /admin/licenses/:id/revoke - Revoke license
// ============================================
router.post('/licenses/:id/revoke', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE licenses SET status = 'revoked', updated_at = NOW()
             WHERE id = $1 RETURNING *`,
            [id]
        );

        if (!result.rows[0]) {
            return res.status(404).json({ error: 'License not found' });
        }

        res.json({
            success: true,
            message: 'License revoked',
            license: result.rows[0]
        });

    } catch (error) {
        console.error('Error revoking license:', error);
        res.status(500).json({ error: 'Failed to revoke license' });
    }
});

// ============================================
// POST /admin/licenses/:id/reactivate - Reactivate license
// ============================================
router.post('/licenses/:id/reactivate', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE licenses SET status = 'active', updated_at = NOW()
             WHERE id = $1 RETURNING *`,
            [id]
        );

        if (!result.rows[0]) {
            return res.status(404).json({ error: 'License not found' });
        }

        res.json({
            success: true,
            message: 'License reactivated',
            license: result.rows[0]
        });

    } catch (error) {
        console.error('Error reactivating license:', error);
        res.status(500).json({ error: 'Failed to reactivate license' });
    }
});

// ============================================
// DELETE /admin/machines/:id - Remove a machine
// ============================================
router.delete('/machines/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            'DELETE FROM activated_machines WHERE id = $1 RETURNING *',
            [id]
        );

        if (!result.rows[0]) {
            return res.status(404).json({ error: 'Machine not found' });
        }

        res.json({
            success: true,
            message: 'Machine removed',
            machine: result.rows[0]
        });

    } catch (error) {
        console.error('Error removing machine:', error);
        res.status(500).json({ error: 'Failed to remove machine' });
    }
});

// ============================================
// GET /admin/stats - Get license statistics
// ============================================
router.get('/stats', async (req, res) => {
    try {
        // Total licenses by tier
        const byTier = await pool.query(`
            SELECT tier, COUNT(*) as count
            FROM licenses
            GROUP BY tier
        `);

        // Total licenses by status
        const byStatus = await pool.query(`
            SELECT status, COUNT(*) as count
            FROM licenses
            GROUP BY status
        `);

        // Recent licenses (last 7 days)
        const recent = await pool.query(`
            SELECT DATE(created_at) as date, COUNT(*) as count
            FROM licenses
            WHERE created_at > NOW() - INTERVAL '7 days'
            GROUP BY DATE(created_at)
            ORDER BY date DESC
        `);

        // Total machines activated
        const machines = await pool.query(`
            SELECT COUNT(*) as count FROM activated_machines
        `);

        // Revenue estimate
        const revenue = await pool.query(`
            SELECT
                SUM(CASE WHEN tier = 'solo' THEN 14.99
                         WHEN tier = 'multiple' THEN 24.99
                         WHEN tier = 'enterprise' THEN 64.99
                         ELSE 0 END) as total
            FROM licenses
            WHERE status = 'active'
        `);

        res.json({
            byTier: byTier.rows,
            byStatus: byStatus.rows,
            recentPurchases: recent.rows,
            totalMachines: parseInt(machines.rows[0].count),
            estimatedRevenue: parseFloat(revenue.rows[0].total || 0).toFixed(2)
        });

    } catch (error) {
        console.error('Error getting stats:', error);
        res.status(500).json({ error: 'Failed to get statistics' });
    }
});

// ============================================
// POST /admin/licenses/:id/resend-email - Resend license email
// ============================================
router.post('/licenses/:id/resend-email', async (req, res) => {
    try {
        const { id } = req.params;

        const license = await pool.query(
            'SELECT * FROM licenses WHERE id = $1',
            [id]
        );

        if (!license.rows[0]) {
            return res.status(404).json({ error: 'License not found' });
        }

        const { email, license_key, tier } = license.rows[0];

        await sendLicenseEmail(email, license_key, tier);

        res.json({
            success: true,
            message: `License email resent to ${email}`
        });

    } catch (error) {
        console.error('Error resending email:', error);
        res.status(500).json({ error: 'Failed to resend email' });
    }
});

module.exports = router;
