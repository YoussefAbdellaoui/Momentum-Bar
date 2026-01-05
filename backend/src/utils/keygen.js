/**
 * License Key Generator
 *
 * Generates unique, formatted license keys
 */

const crypto = require('crypto');

// Tier prefixes
const TIER_PREFIX = {
    solo: 'SOLO',
    multiple: 'MULTI',
    enterprise: 'TEAM'
};

/**
 * Generate a random alphanumeric string
 * @param {number} length - Length of string to generate
 * @returns {string} Random string (uppercase)
 */
function randomString(length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars: I, O, 0, 1
    let result = '';
    const bytes = crypto.randomBytes(length);
    for (let i = 0; i < length; i++) {
        result += chars[bytes[i] % chars.length];
    }
    return result;
}

/**
 * Generate a license key
 * Format: PREFIX-XXXXX-XXXXX-XXXXX
 *
 * @param {string} tier - License tier (solo, multiple, enterprise)
 * @returns {string} Formatted license key
 */
function generateLicenseKey(tier) {
    const prefix = TIER_PREFIX[tier] || 'SOLO';
    const segment1 = randomString(5);
    const segment2 = randomString(5);
    const segment3 = randomString(5);

    return `${prefix}-${segment1}-${segment2}-${segment3}`;
}

/**
 * Validate license key format
 * @param {string} key - License key to validate
 * @returns {boolean} True if format is valid
 */
function isValidKeyFormat(key) {
    const pattern = /^(SOLO|MULTI|TEAM|SEAT)-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$/;
    return pattern.test(key.toUpperCase().trim());
}

/**
 * Extract tier from license key
 * @param {string} key - License key
 * @returns {string|null} Tier name or null if invalid
 */
function getTierFromKey(key) {
    const prefix = key.split('-')[0].toUpperCase();
    const prefixToTier = {
        'SOLO': 'solo',
        'MULTI': 'multiple',
        'TEAM': 'enterprise',
        'SEAT': 'enterprise'
    };
    return prefixToTier[prefix] || null;
}

/**
 * Generate a hash for hardware ID verification
 * @param {string} input - Input string to hash
 * @returns {string} SHA-256 hash
 */
function generateHardwareHash(input) {
    return crypto.createHash('sha256').update(input).digest('hex');
}

module.exports = {
    generateLicenseKey,
    isValidKeyFormat,
    getTierFromKey,
    generateHardwareHash
};
