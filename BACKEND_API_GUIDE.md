# MomentumBar License Backend API Guide

## Overview

This guide explains how to build a backend API to handle:
1. Dodo Payments processing
2. License key generation
3. Email delivery with activation keys
4. License activation and validation

---

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Dodo      │────▶│  Your API   │────▶│  Database   │
│  Payments   │     │  (Backend)  │     │ (PostgreSQL)│
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │
       │                   ▼
       │            ┌─────────────┐
       │            │   Email     │
       │            │  (Resend/   │
       │            │  SendGrid)  │
       │            └─────────────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│   User      │◀────│  License    │
│  (Browser)  │     │   Email     │
└─────────────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│ MomentumBar │────▶ Your API (activate/validate)
│    (App)    │
└─────────────┘
```

---

## Tech Stack Recommendation

- **Runtime**: Node.js or Python
- **Framework**: Express.js (Node) or FastAPI (Python)
- **Database**: PostgreSQL (or Supabase for managed)
- **Payments**: Dodo Payments checkout links
- **Email**: Resend, SendGrid, or AWS SES
- **Hosting**: Railway, Render, Fly.io, or Vercel

---

## Database Schema

### PostgreSQL Tables

```sql
-- Licenses table
CREATE TABLE licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key VARCHAR(24) UNIQUE NOT NULL,
    tier VARCHAR(20) NOT NULL CHECK (tier IN ('solo', 'multiple', 'enterprise')),
    email VARCHAR(255) NOT NULL,
    dodo_customer_id VARCHAR(255),
    dodo_payment_id VARCHAR(255),
    max_machines INT NOT NULL DEFAULT 1,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activated machines table
CREATE TABLE activated_machines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_id UUID REFERENCES licenses(id) ON DELETE CASCADE,
    hardware_id VARCHAR(64) NOT NULL,
    machine_name VARCHAR(255),
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_validated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reactivations_used INT DEFAULT 0,
    UNIQUE(license_id, hardware_id)
);

-- Indexes
CREATE INDEX idx_licenses_key ON licenses(license_key);
CREATE INDEX idx_licenses_email ON licenses(email);
CREATE INDEX idx_machines_hardware ON activated_machines(hardware_id);
```

---

## License Key Generation

```javascript
// Node.js example
const crypto = require('crypto');

function generateLicenseKey(tier) {
    const prefix = {
        'solo': 'SOLO',
        'multiple': 'MULTI',
        'enterprise': 'TEAM'
    }[tier] || 'SOLO';

    // Generate 3 groups of 5 random alphanumeric characters
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const groups = [];

    for (let g = 0; g < 3; g++) {
        let group = '';
        for (let i = 0; i < 5; i++) {
            group += chars.charAt(crypto.randomInt(chars.length));
        }
        groups.push(group);
    }

    return `${prefix}-${groups.join('-')}`;
    // Output: SOLO-A1B2C-D3E4F-G5H6I
}
```

```python
# Python example
import secrets
import string

def generate_license_key(tier: str) -> str:
    prefix_map = {
        'solo': 'SOLO',
        'multiple': 'MULTI',
        'enterprise': 'TEAM'
    }
    prefix = prefix_map.get(tier, 'SOLO')

    chars = string.ascii_uppercase + string.digits
    groups = [
        ''.join(secrets.choice(chars) for _ in range(5))
        for _ in range(3)
    ]

    return f"{prefix}-{'-'.join(groups)}"
```

---

## API Endpoints

### 1. Dodo Payments Webhook (receives payment events)

```
POST /webhooks/dodo
```

This endpoint receives Dodo Payments webhook events when a payment succeeds.

### 2. Activate License

```
POST /api/v1/license/activate
Content-Type: application/json

{
    "licenseKey": "SOLO-XXXXX-XXXXX-XXXXX",
    "hardwareID": "abc123...",
    "machineName": "MacBook Pro 16"
}

Response (success):
{
    "success": true,
    "license": {
        "tier": "solo",
        "licenseKey": "SOLO-XXXXX-XXXXX-XXXXX",
        "email": "user@example.com",
        "purchaseDate": "2024-01-15T10:30:00Z",
        "maxMachines": 1,
        "activeMachines": [
            {
                "id": "abc123...",
                "machineName": "MacBook Pro 16",
                "activatedDate": "2024-01-15T12:00:00Z"
            }
        ],
        "signature": "..."
    }
}

Response (error):
{
    "success": false,
    "error": "Machine limit reached",
    "errorCode": "LIMIT_REACHED"
}
```

### 3. Validate License

```
POST /api/v1/license/validate
Content-Type: application/json

{
    "licenseKey": "SOLO-XXXXX-XXXXX-XXXXX",
    "hardwareID": "abc123..."
}

Response:
{
    "valid": true,
    "license": { ... }
}
```

### 4. Deactivate Machine

```
POST /api/v1/license/deactivate
Content-Type: application/json

{
    "licenseKey": "SOLO-XXXXX-XXXXX-XXXXX",
    "hardwareID": "abc123..."
}

Response:
{
    "success": true,
    "message": "Machine deactivated"
}
```

---

## Complete Backend Implementation (Node.js + Express)

### Project Structure

```
license-api/
├── package.json
├── .env
├── src/
│   ├── index.js          # Entry point
│   ├── config/
│   │   └── database.js   # DB connection
│   ├── routes/
│   │   ├── webhooks.js   # Dodo Payments webhooks
│   │   └── license.js    # License endpoints
│   ├── services/
│   │   ├── license.js    # License logic
│   │   └── email.js      # Email sending
│   └── utils/
│       └── keygen.js     # Key generation
└── README.md
```

### package.json

```json
{
  "name": "momentumbar-license-api",
  "version": "1.0.0",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "dodopayments": "^1.52.5",
    "resend": "^2.1.0",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
```

### .env

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/momentumbar

# Dodo Payments
DODO_PAYMENTS_API_KEY=dodo_test_...
DODO_PAYMENTS_WEBHOOK_KEY=whk_...
DODO_PAYMENTS_ENVIRONMENT=test_mode
DODO_PRODUCT_SOLO=prod_...
DODO_PRODUCT_MULTIPLE=prod_...
DODO_PRODUCT_ENTERPRISE=prod_...

# Email (Resend)
RESEND_API_KEY=re_...
FROM_EMAIL=licenses@momentumbar.app
```

### src/index.js

```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const webhooksRouter = require('./routes/webhooks');
const licenseRouter = require('./routes/license');

const app = express();

// Dodo Payments webhooks need raw body
app.use('/webhooks/dodo', express.raw({ type: 'application/json' }));

// Other routes use JSON
app.use(express.json());
app.use(cors());

// Routes
app.use('/webhooks', webhooksRouter);
app.use('/api/v1/license', licenseRouter);

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`License API running on port ${PORT}`);
});
```

### src/config/database.js

```javascript
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: false }
        : false
});

module.exports = pool;
```

### src/utils/keygen.js

```javascript
const crypto = require('crypto');

function generateLicenseKey(tier) {
    const prefixes = {
        'solo': 'SOLO',
        'multiple': 'MULTI',
        'enterprise': 'TEAM'
    };
    const prefix = prefixes[tier] || 'SOLO';

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const groups = [];

    for (let g = 0; g < 3; g++) {
        let group = '';
        for (let i = 0; i < 5; i++) {
            const randomIndex = crypto.randomInt(0, chars.length);
            group += chars[randomIndex];
        }
        groups.push(group);
    }

    return `${prefix}-${groups.join('-')}`;
}

module.exports = { generateLicenseKey };
```

### src/services/email.js

```javascript
const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

async function sendLicenseEmail(email, licenseKey, tier) {
    const tierNames = {
        'solo': 'Solo',
        'multiple': 'Multiple',
        'enterprise': 'Enterprise'
    };

    const tierName = tierNames[tier] || 'Solo';

    try {
        await resend.emails.send({
            from: process.env.FROM_EMAIL,
            to: email,
            subject: 'Your MomentumBar License Key',
            html: `
                <h1>Thank you for purchasing MomentumBar!</h1>

                <p>Here is your <strong>${tierName}</strong> license key:</p>

                <div style="background: #f4f4f4; padding: 20px; border-radius: 8px; font-family: monospace; font-size: 24px; text-align: center; margin: 20px 0;">
                    ${licenseKey}
                </div>

                <h2>How to activate:</h2>
                <ol>
                    <li>Open MomentumBar</li>
                    <li>Go to Settings → License</li>
                    <li>Enter your license key</li>
                    <li>Click "Activate"</li>
                </ol>

                <p>If you have any questions, reply to this email.</p>

                <p>Best regards,<br>The MomentumBar Team</p>
            `
        });

        console.log(`License email sent to ${email}`);
        return true;
    } catch (error) {
        console.error('Failed to send email:', error);
        return false;
    }
}

module.exports = { sendLicenseEmail };
```

### src/services/license.js

```javascript
const pool = require('../config/database');
const { generateLicenseKey } = require('../utils/keygen');

async function createLicense(email, tier, dodoCustomerId, dodoPaymentId) {
    const licenseKey = generateLicenseKey(tier);

    const maxMachines = {
        'solo': 1,
        'multiple': 3,
        'enterprise': 6
    }[tier] || 1;

    const result = await pool.query(
        `INSERT INTO licenses
         (license_key, tier, email, dodo_customer_id, dodo_payment_id, max_machines)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [licenseKey, tier, email, dodoCustomerId, dodoPaymentId, maxMachines]
    );

    return result.rows[0];
}

async function getLicenseByKey(licenseKey) {
    const result = await pool.query(
        'SELECT * FROM licenses WHERE license_key = $1 AND status = $2',
        [licenseKey, 'active']
    );
    return result.rows[0];
}

async function getActivatedMachines(licenseId) {
    const result = await pool.query(
        'SELECT * FROM activated_machines WHERE license_id = $1',
        [licenseId]
    );
    return result.rows;
}

async function activateMachine(licenseId, hardwareId, machineName) {
    // Check if already activated
    const existing = await pool.query(
        'SELECT * FROM activated_machines WHERE license_id = $1 AND hardware_id = $2',
        [licenseId, hardwareId]
    );

    if (existing.rows.length > 0) {
        // Already activated - update last_validated
        await pool.query(
            'UPDATE activated_machines SET last_validated = NOW() WHERE id = $1',
            [existing.rows[0].id]
        );
        return { alreadyActivated: true, machine: existing.rows[0] };
    }

    // Get license to check machine limit
    const license = await pool.query(
        'SELECT * FROM licenses WHERE id = $1',
        [licenseId]
    );

    if (!license.rows[0]) {
        throw new Error('License not found');
    }

    // Count current machines
    const machineCount = await pool.query(
        'SELECT COUNT(*) FROM activated_machines WHERE license_id = $1',
        [licenseId]
    );

    if (parseInt(machineCount.rows[0].count) >= license.rows[0].max_machines) {
        throw new Error('LIMIT_REACHED');
    }

    // Activate new machine
    const result = await pool.query(
        `INSERT INTO activated_machines (license_id, hardware_id, machine_name)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [licenseId, hardwareId, machineName]
    );

    return { alreadyActivated: false, machine: result.rows[0] };
}

async function deactivateMachine(licenseId, hardwareId) {
    const result = await pool.query(
        'DELETE FROM activated_machines WHERE license_id = $1 AND hardware_id = $2 RETURNING *',
        [licenseId, hardwareId]
    );
    return result.rows[0];
}

module.exports = {
    createLicense,
    getLicenseByKey,
    getActivatedMachines,
    activateMachine,
    deactivateMachine
};
```

### src/routes/webhooks.js

```javascript
const express = require('express');
const DodoPayments = require('dodopayments');
const licenseService = require('../services/license');
const emailService = require('../services/email');

const router = express.Router();
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

router.post('/dodo', async (req, res) => {
    let event;

    try {
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

    if (event.type === 'payment.succeeded') {
        const payload = event?.data || event?.payload?.data || {};
        const payment = payload?.object || payload;
        const email = payment?.customer?.email || payment?.customer_email;
        const metadata = payment?.metadata || payment?.object?.metadata || {};
        const productId = payment?.product_id || payment?.items?.[0]?.product_id;
        const tier = metadata.tier || PRODUCT_TO_TIER[productId] || 'solo';

        try {
            const license = await licenseService.createLicense(
                email,
                tier,
                payment?.customer?.customer_id || payment?.customer?.id,
                payment?.payment_id || payment?.id
            );

            console.log(`License created: ${license.license_key} for ${email}`);

            await emailService.sendLicenseEmail(
                email,
                license.license_key,
                tier
            );
        } catch (error) {
            console.error('Error processing payment:', error);
            // Don't return error to the webhook - log and handle manually
        }
    }

    res.json({ received: true });
});

module.exports = router;
```

### src/routes/license.js

```javascript
const express = require('express');
const licenseService = require('../services/license');

const router = express.Router();

// Activate license
router.post('/activate', async (req, res) => {
    try {
        const { licenseKey, hardwareID, machineName } = req.body;

        if (!licenseKey || !hardwareID) {
            return res.status(400).json({
                success: false,
                error: 'Missing required fields',
                errorCode: 'INVALID_REQUEST'
            });
        }

        // Find license
        const license = await licenseService.getLicenseByKey(licenseKey);

        if (!license) {
            return res.status(404).json({
                success: false,
                error: 'License not found or revoked',
                errorCode: 'INVALID_KEY'
            });
        }

        // Try to activate machine
        try {
            const result = await licenseService.activateMachine(
                license.id,
                hardwareID,
                machineName || 'Unknown Mac'
            );

            // Get all machines for response
            const machines = await licenseService.getActivatedMachines(license.id);

            return res.json({
                success: true,
                license: {
                    tier: license.tier,
                    licenseKey: license.license_key,
                    email: license.email,
                    purchaseDate: license.purchase_date,
                    maxMachines: license.max_machines,
                    activeMachines: machines.map(m => ({
                        id: m.hardware_id,
                        machineName: m.machine_name,
                        activatedDate: m.activated_at
                    })),
                    signature: '' // Add RSA signature if needed
                }
            });

        } catch (error) {
            if (error.message === 'LIMIT_REACHED') {
                return res.status(403).json({
                    success: false,
                    error: 'Maximum machines reached for this license',
                    errorCode: 'LIMIT_REACHED'
                });
            }
            throw error;
        }

    } catch (error) {
        console.error('Activation error:', error);
        return res.status(500).json({
            success: false,
            error: 'Internal server error',
            errorCode: 'SERVER_ERROR'
        });
    }
});

// Validate license
router.post('/validate', async (req, res) => {
    try {
        const { licenseKey, hardwareID } = req.body;

        const license = await licenseService.getLicenseByKey(licenseKey);

        if (!license) {
            return res.json({ valid: false, message: 'License not found' });
        }

        const machines = await licenseService.getActivatedMachines(license.id);
        const isActivated = machines.some(m => m.hardware_id === hardwareID);

        if (!isActivated) {
            return res.json({ valid: false, message: 'Machine not activated' });
        }

        return res.json({
            valid: true,
            license: {
                tier: license.tier,
                licenseKey: license.license_key,
                email: license.email,
                purchaseDate: license.purchase_date,
                maxMachines: license.max_machines,
                activeMachines: machines.map(m => ({
                    id: m.hardware_id,
                    machineName: m.machine_name,
                    activatedDate: m.activated_at
                })),
                signature: ''
            }
        });

    } catch (error) {
        console.error('Validation error:', error);
        return res.json({ valid: false, message: 'Validation failed' });
    }
});

// Deactivate machine
router.post('/deactivate', async (req, res) => {
    try {
        const { licenseKey, hardwareID } = req.body;

        const license = await licenseService.getLicenseByKey(licenseKey);

        if (!license) {
            return res.status(404).json({
                success: false,
                message: 'License not found'
            });
        }

        await licenseService.deactivateMachine(license.id, hardwareID);

        return res.json({
            success: true,
            message: 'Machine deactivated successfully'
        });

    } catch (error) {
        console.error('Deactivation error:', error);
        return res.status(500).json({
            success: false,
            message: 'Deactivation failed'
        });
    }
});

module.exports = router;
```

---

## Dodo Payments Setup

### 1. Create Products in Dodo Payments Dashboard

Create 3 products and copy their product IDs:

| Product | Price | Product ID |
|---------|-------|------------|
| MomentumBar Solo | $14.99 (one-time) | prod_xxx |
| MomentumBar Multiple | $24.99 (one-time) | prod_yyy |
| MomentumBar Enterprise | $64.99 (one-time) | prod_zzz |

### 2. Create Checkout Links

Dodo Payments provides a hosted checkout link per product:

```
https://checkout.dodopayments.com/buy/{product_id}
```

Append the required redirect URL (and optional quantity) after purchase:

```
https://checkout.dodopayments.com/buy/{product_id}?quantity=1&redirect_url=https://momentumbar.app/success
```

### 3. Setup Webhook

1. Go to Dodo Payments dashboard → Webhooks
2. Add endpoint: `https://your-api.com/webhooks/dodo`
3. Select event: `payment.succeeded` (optionally `payment.failed`)
4. Copy the webhook key to your `.env`

---

## Deployment

### Option 1: Railway (Recommended for beginners)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Add PostgreSQL
railway add --plugin postgresql

# Deploy
railway up
```

### Option 2: Render

1. Create new Web Service
2. Connect your GitHub repo
3. Set environment variables
4. Add PostgreSQL database
5. Deploy

### Option 3: Docker

```dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY src ./src

EXPOSE 3000
CMD ["node", "src/index.js"]
```

---

## Update Your App

Once deployed, update `LicenseAPIClient.swift`:

```swift
// Change from:
private let baseURL = "https://api.momentumbar.app/v1"

// To your actual API URL:
private let baseURL = "https://your-railway-app.up.railway.app/api/v1"
```

---

## Testing

### Test with Dodo Payments

- Use Dodo Payments test mode and a test checkout link.
- Send a test `payment.succeeded` webhook from the Dodo Payments dashboard.

### Test Activation Flow

```bash
# Test activation
curl -X POST http://localhost:3000/api/v1/license/activate \
  -H "Content-Type: application/json" \
  -d '{
    "licenseKey": "SOLO-XXXXX-XXXXX-XXXXX",
    "hardwareID": "test123",
    "machineName": "Test Mac"
  }'
```

---

## Security Checklist

- [ ] Use HTTPS in production
- [ ] Validate Dodo Payments webhook signatures
- [ ] Rate limit API endpoints
- [ ] Use parameterized SQL queries (done)
- [ ] Store secrets in environment variables
- [ ] Add request logging for debugging
- [ ] Consider adding RSA signature to licenses

---

## Summary

1. **Setup Dodo Payments** - Create products and checkout links
2. **Deploy API** - Use Railway, Render, or your preferred host
3. **Configure Webhook** - Point Dodo Payments to your `/webhooks/dodo` endpoint
4. **Update App** - Change the `baseURL` in `LicenseAPIClient.swift`
5. **Test** - Use Dodo Payments test mode to verify the flow

The flow will be:
1. User clicks "Purchase" on your website
2. Dodo Payments checkout handles payment
3. Dodo Payments sends webhook to your API
4. API creates license and sends email
5. User enters key in MomentumBar app
6. App calls your API to activate
