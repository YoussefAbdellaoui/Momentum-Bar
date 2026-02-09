/**
 * Adds email_jobs table for license email retry queue
 */

require('dotenv').config();

const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

const sql = `
CREATE TABLE IF NOT EXISTS email_jobs (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    license_key VARCHAR(50) NOT NULL,
    tier VARCHAR(20) NOT NULL CHECK (tier IN ('solo', 'multiple', 'enterprise')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sending', 'retry', 'sent', 'failed')),
    attempts INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 3,
    next_attempt_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_error TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_jobs_status ON email_jobs(status);
CREATE INDEX IF NOT EXISTS idx_email_jobs_next_attempt ON email_jobs(next_attempt_at);
CREATE INDEX IF NOT EXISTS idx_email_jobs_created_at ON email_jobs(created_at);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_email_jobs_updated_at ON email_jobs;
CREATE TRIGGER update_email_jobs_updated_at
    BEFORE UPDATE ON email_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
`;

async function migrate() {
    console.log('Adding email_jobs table...');
    try {
        await pool.query(sql);
        console.log('email_jobs table ready.');
    } catch (error) {
        console.error('Failed to add email_jobs table:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

migrate();
