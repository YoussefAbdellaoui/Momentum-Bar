/**
 * Public Announcements API
 */

const express = require('express');
const pool = require('../config/database');

const router = express.Router();

// ============================================
// GET /api/v1/announcements
// ============================================
router.get('/', async (req, res) => {
    try {
        const { limit = 10 } = req.query;

        const result = await pool.query(
            `SELECT id, title, body, type, link_url, starts_at, ends_at, min_app_version, max_app_version, created_at
             FROM announcements
             WHERE is_active = true
               AND (starts_at IS NULL OR starts_at <= NOW())
               AND (ends_at IS NULL OR ends_at >= NOW())
             ORDER BY starts_at DESC NULLS LAST, created_at DESC
             LIMIT $1`,
            [Math.min(parseInt(limit, 10) || 10, 50)]
        );

        res.json({ announcements: result.rows });
    } catch (error) {
        console.error('Error fetching announcements:', error);
        res.status(500).json({ error: 'Failed to fetch announcements' });
    }
});

module.exports = router;
