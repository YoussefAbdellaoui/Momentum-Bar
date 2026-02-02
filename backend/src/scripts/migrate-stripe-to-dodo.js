require('dotenv').config();

const pool = require('../config/database');

const renameColumnIfExists = async (client, table, from, to) => {
  const result = await client.query(
    `SELECT 1
     FROM information_schema.columns
     WHERE table_name = $1 AND column_name = $2`,
    [table, from]
  );

  if (result.rowCount === 0) {
    console.log(`Column ${table}.${from} does not exist, skipping rename.`);
    return false;
  }

  await client.query(`ALTER TABLE ${table} RENAME COLUMN ${from} TO ${to}`);
  console.log(`Renamed ${table}.${from} -> ${to}`);
  return true;
};

const columnExists = async (client, table, column) => {
  const result = await client.query(
    `SELECT 1
     FROM information_schema.columns
     WHERE table_name = $1 AND column_name = $2`,
    [table, column]
  );
  return result.rowCount > 0;
};

async function migrate() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const renamedSession = await renameColumnIfExists(client, 'licenses', 'stripe_session_id', 'dodo_payment_id');
    const renamedCustomer = await renameColumnIfExists(client, 'licenses', 'stripe_customer_id', 'dodo_customer_id');

    if (!renamedSession) {
      const hasDodoPayment = await columnExists(client, 'licenses', 'dodo_payment_id');
      if (!hasDodoPayment) {
        await client.query('ALTER TABLE licenses ADD COLUMN dodo_payment_id VARCHAR(255)');
        console.log('Added licenses.dodo_payment_id column');
      }
    }

    if (!renamedCustomer) {
      const hasDodoCustomer = await columnExists(client, 'licenses', 'dodo_customer_id');
      if (!hasDodoCustomer) {
        await client.query('ALTER TABLE licenses ADD COLUMN dodo_customer_id VARCHAR(255)');
        console.log('Added licenses.dodo_customer_id column');
      }
    }

    await client.query('DROP INDEX IF EXISTS idx_licenses_stripe_session');
    await client.query('CREATE INDEX IF NOT EXISTS idx_licenses_dodo_payment ON licenses(dodo_payment_id)');

    await client.query('COMMIT');
    console.log('Migration completed successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
