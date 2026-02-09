const pool = require('../config/database');
const { sendLicenseEmail } = require('./email');

const DEFAULT_MAX_ATTEMPTS = 3;

const computeNextAttempt = (attempts) => {
    const delays = [5 * 60, 30 * 60, 2 * 60 * 60]; // seconds
    const index = Math.min(attempts - 1, delays.length - 1);
    return new Date(Date.now() + delays[index] * 1000);
};

async function enqueueLicenseEmail(email, licenseKey, tier, options = {}) {
    const maxAttempts = options.maxAttempts || DEFAULT_MAX_ATTEMPTS;
    const nextAttemptAt = options.nextAttemptAt || new Date();

    await pool.query(
        `INSERT INTO email_jobs (email, license_key, tier, status, attempts, max_attempts, next_attempt_at)
         VALUES ($1, $2, $3, 'pending', 0, $4, $5)`,
        [email, licenseKey, tier, maxAttempts, nextAttemptAt]
    );
}

async function claimJobs(limit = 5) {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const result = await client.query(
            `SELECT *
             FROM email_jobs
             WHERE status IN ('pending', 'retry')
               AND next_attempt_at <= NOW()
             ORDER BY created_at ASC
             LIMIT $1
             FOR UPDATE SKIP LOCKED`,
            [limit]
        );

        const ids = result.rows.map((row) => row.id);
        if (ids.length > 0) {
            await client.query(
                `UPDATE email_jobs
                 SET status = 'sending',
                     attempts = attempts + 1
                 WHERE id = ANY($1::int[])`,
                [ids]
            );
        }

        await client.query('COMMIT');
        return result.rows;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

async function processQueue() {
    const jobs = await claimJobs(5);
    if (jobs.length === 0) return;

    await Promise.all(jobs.map(async (job) => {
        try {
            await sendLicenseEmail(job.email, job.license_key, job.tier);
            await pool.query(
                `UPDATE email_jobs
                 SET status = 'sent', sent_at = NOW(), last_error = NULL
                 WHERE id = $1`,
                [job.id]
            );
        } catch (error) {
            const nextAttempt = computeNextAttempt(job.attempts + 1);
            const isFinal = job.attempts + 1 >= job.max_attempts;
            await pool.query(
                `UPDATE email_jobs
                 SET status = $2,
                     next_attempt_at = $3,
                     last_error = $4
                 WHERE id = $1`,
                [
                    job.id,
                    isFinal ? 'failed' : 'retry',
                    isFinal ? null : nextAttempt,
                    String(error.message || error)
                ]
            );
        }
    }));
}

function startEmailQueue() {
    if (process.env.EMAIL_QUEUE_DISABLED === 'true') {
        console.log('Email queue disabled by EMAIL_QUEUE_DISABLED=true');
        return;
    }

    const intervalSeconds = Number(process.env.EMAIL_QUEUE_INTERVAL || 60);
    setInterval(() => {
        processQueue().catch((error) => {
            console.error('Email queue processing error:', error);
        });
    }, intervalSeconds * 1000);

    processQueue().catch((error) => {
        console.error('Email queue startup error:', error);
    });
}

module.exports = {
    enqueueLicenseEmail,
    processQueue,
    startEmailQueue
};
