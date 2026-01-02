/**
 * License API Routes
 *
 * Endpoints for license activation, validation, and deactivation
 */

const express = require('express');
const pool = require('../config/database');
const { generateHardwareHash } = require('../utils/keygen');

const router = express.Router();

// ============================================
// POST /api/v1/license/activate
// Activate a license on a machine
// ============================================
router.post('/activate', async (req, res) => {
    try {
        const { licenseKey, hardwareId, machineName } = req.body;

        if (!licenseKey || !hardwareId) {
            return res.status(400).json({
                success: false,
                error: 'License key and hardware ID are required'
            });
        }

        // Find the license
        const licenseResult = await pool.query(
            'SELECT * FROM licenses WHERE license_key = $1',
            [licenseKey.toUpperCase().trim()]
        );

        if (!licenseResult.rows[0]) {
            return res.status(404).json({
                success: false,
                error: 'Invalid license key'
            });
        }

        const license = licenseResult.rows[0];

        // Check if license is revoked
        if (license.status === 'revoked') {
            return res.status(403).json({
                success: false,
                error: 'This license has been revoked'
            });
        }

        // Check if this machine is already activated
        const existingMachine = await pool.query(
            'SELECT * FROM activated_machines WHERE license_id = $1 AND hardware_id = $2',
            [license.id, hardwareId]
        );

        if (existingMachine.rows[0]) {
            // Machine already activated - return success with existing data
            return res.json({
                success: true,
                message: 'Machine already activated',
                license: {
                    tier: license.tier,
                    email: license.email,
                    maxMachines: license.max_machines,
                    activatedMachines: await getActivatedCount(license.id),
                    expiresAt: null // Lifetime license
                }
            });
        }

        // Check machine limit
        const activatedCount = await getActivatedCount(license.id);
        if (activatedCount >= license.max_machines) {
            return res.status(403).json({
                success: false,
                error: `Machine limit reached (${license.max_machines} allowed). Deactivate another machine first.`,
                activatedMachines: activatedCount,
                maxMachines: license.max_machines
            });
        }

        // Activate the machine
        await pool.query(
            `INSERT INTO activated_machines (license_id, hardware_id, machine_name)
             VALUES ($1, $2, $3)`,
            [license.id, hardwareId, machineName || 'Unknown Mac']
        );

        // Update license status to active if it was pending
        if (license.status === 'pending') {
            await pool.query(
                "UPDATE licenses SET status = 'active', updated_at = NOW() WHERE id = $1",
                [license.id]
            );
        }

        res.json({
            success: true,
            message: 'License activated successfully',
            license: {
                tier: license.tier,
                email: license.email,
                maxMachines: license.max_machines,
                activatedMachines: activatedCount + 1,
                expiresAt: null // Lifetime license
            }
        });

    } catch (error) {
        console.error('Activation error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to activate license'
        });
    }
});

// ============================================
// POST /api/v1/license/validate
// Validate a license (phone home check)
// ============================================
router.post('/validate', async (req, res) => {
    try {
        const { licenseKey, hardwareId } = req.body;

        if (!licenseKey || !hardwareId) {
            return res.status(400).json({
                valid: false,
                error: 'License key and hardware ID are required'
            });
        }

        // Find the license
        const licenseResult = await pool.query(
            'SELECT * FROM licenses WHERE license_key = $1',
            [licenseKey.toUpperCase().trim()]
        );

        if (!licenseResult.rows[0]) {
            return res.json({
                valid: false,
                error: 'Invalid license key'
            });
        }

        const license = licenseResult.rows[0];

        // Check if revoked
        if (license.status === 'revoked') {
            return res.json({
                valid: false,
                error: 'License has been revoked'
            });
        }

        // Check if this hardware ID is activated
        const machineResult = await pool.query(
            'SELECT * FROM activated_machines WHERE license_id = $1 AND hardware_id = $2',
            [license.id, hardwareId]
        );

        if (!machineResult.rows[0]) {
            return res.json({
                valid: false,
                error: 'This machine is not activated for this license'
            });
        }

        // Update last validated timestamp
        await pool.query(
            'UPDATE activated_machines SET last_validated = NOW() WHERE id = $1',
            [machineResult.rows[0].id]
        );

        res.json({
            valid: true,
            license: {
                tier: license.tier,
                email: license.email,
                maxMachines: license.max_machines,
                activatedMachines: await getActivatedCount(license.id)
            }
        });

    } catch (error) {
        console.error('Validation error:', error);
        res.status(500).json({
            valid: false,
            error: 'Failed to validate license'
        });
    }
});

// ============================================
// POST /api/v1/license/deactivate
// Deactivate a machine from a license
// ============================================
router.post('/deactivate', async (req, res) => {
    try {
        const { licenseKey, hardwareId } = req.body;

        if (!licenseKey || !hardwareId) {
            return res.status(400).json({
                success: false,
                error: 'License key and hardware ID are required'
            });
        }

        // Find the license
        const licenseResult = await pool.query(
            'SELECT * FROM licenses WHERE license_key = $1',
            [licenseKey.toUpperCase().trim()]
        );

        if (!licenseResult.rows[0]) {
            return res.status(404).json({
                success: false,
                error: 'Invalid license key'
            });
        }

        const license = licenseResult.rows[0];

        // Delete the machine activation
        const deleteResult = await pool.query(
            'DELETE FROM activated_machines WHERE license_id = $1 AND hardware_id = $2 RETURNING *',
            [license.id, hardwareId]
        );

        if (!deleteResult.rows[0]) {
            return res.status(404).json({
                success: false,
                error: 'Machine not found for this license'
            });
        }

        res.json({
            success: true,
            message: 'Machine deactivated successfully',
            remainingMachines: await getActivatedCount(license.id)
        });

    } catch (error) {
        console.error('Deactivation error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to deactivate machine'
        });
    }
});

// ============================================
// GET /api/v1/license/info/:key
// Get license info (for displaying in app)
// ============================================
router.get('/info/:key', async (req, res) => {
    try {
        const { key } = req.params;

        const licenseResult = await pool.query(
            'SELECT tier, email, max_machines, status, created_at FROM licenses WHERE license_key = $1',
            [key.toUpperCase().trim()]
        );

        if (!licenseResult.rows[0]) {
            return res.status(404).json({ error: 'License not found' });
        }

        const license = licenseResult.rows[0];
        const activatedCount = await pool.query(
            'SELECT COUNT(*) FROM activated_machines am JOIN licenses l ON am.license_id = l.id WHERE l.license_key = $1',
            [key.toUpperCase().trim()]
        );

        res.json({
            tier: license.tier,
            email: license.email,
            maxMachines: license.max_machines,
            activatedMachines: parseInt(activatedCount.rows[0].count),
            status: license.status,
            purchaseDate: license.created_at
        });

    } catch (error) {
        console.error('Info error:', error);
        res.status(500).json({ error: 'Failed to get license info' });
    }
});

// Helper function to get activated machine count
async function getActivatedCount(licenseId) {
    const result = await pool.query(
        'SELECT COUNT(*) FROM activated_machines WHERE license_id = $1',
        [licenseId]
    );
    return parseInt(result.rows[0].count);
}

module.exports = router;
