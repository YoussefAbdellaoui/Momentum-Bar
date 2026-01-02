/**
 * Database Initialization Script
 *
 * Run with: npm run db:init
 *
 * Creates the necessary tables for the licensing system
 */

require('dotenv').config();

const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

const schema = `
-- Licenses table
CREATE TABLE IF NOT EXISTS licenses (
    id SERIAL PRIMARY KEY,
    license_key VARCHAR(50) UNIQUE NOT NULL,
    tier VARCHAR(20) NOT NULL CHECK (tier IN ('solo', 'multiple', 'enterprise')),
    email VARCHAR(255) NOT NULL,
    max_machines INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'revoked')),
    stripe_session_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activated machines table
CREATE TABLE IF NOT EXISTS activated_machines (
    id SERIAL PRIMARY KEY,
    license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
    hardware_id VARCHAR(64) NOT NULL,
    machine_name VARCHAR(255),
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_validated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(license_id, hardware_id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_licenses_email ON licenses(email);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);
CREATE INDEX IF NOT EXISTS idx_licenses_stripe_session ON licenses(stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_machines_hardware ON activated_machines(hardware_id);
CREATE INDEX IF NOT EXISTS idx_machines_license ON activated_machines(license_id);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to licenses table
DROP TRIGGER IF EXISTS update_licenses_updated_at ON licenses;
CREATE TRIGGER update_licenses_updated_at
    BEFORE UPDATE ON licenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
`;

async function initDatabase() {
    console.log('Initializing database...');
    console.log('Connection:', process.env.DATABASE_URL?.replace(/:[^:@]+@/, ':****@'));

    try {
        await pool.query(schema);
        console.log('Database initialized successfully!');
        console.log('');
        console.log('Tables created:');
        console.log('  - licenses');
        console.log('  - activated_machines');
        console.log('');
        console.log('You can now start the server with: npm start');
    } catch (error) {
        console.error('Failed to initialize database:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

initDatabase();
