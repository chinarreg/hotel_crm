# Hotel CRM Documentation

Project: Internal Hotel CRM for Radisson Blu Nagpur  
Framework: Ruby on Rails 8, PostgreSQL, Sidekiq, Redis, Bootstrap 5

## 1. Purpose
This application helps hotel operations teams manage:
- Members and membership lifecycle
- Vouchers and purchases
- Guest check-in/check-out imports from Opera CSV via IMAP
- WhatsApp campaign messaging (members, guests, or custom uploaded audience)
- Operational tracking through dashboard, import runs, and campaign status

The platform is designed for internal hotel usage (200-300 members currently), with multi-property support and cloud portability.

## 2. Quick Navigation
After opening the application root URL, you are redirected to `/admin`.

Main menu items:
- Dashboard
- Members
- Vouchers
- Purchases
- Guest Imports
- Import Runs
- Promotion Campaigns
- Settings
- Sidekiq

## 3. Dashboard
Path: `/admin`

Dashboard cards show:
- Total members
- Active members
- Issued vouchers
- Completed imports (last 7 days)
- Campaign total
- Messages sent
- Messages failed
- Messages pending

Use this screen for daily operational overview.

## 4. Members Management
Path: `/admin/members`

### What you can do
- Create, view, edit, delete members
- Search by name, email, phone, membership number
- Filter by status (`active` / `expired`)

### Member fields
- Full name (required)
- Phone (optional, unique when present)
- Email (optional, unique when present)
- Membership number (required, unique)
- Membership start date (required)
- Membership expiry date (required)
- Status (`active`/`expired`)
- Property (optional, for multi-property support)

## 5. Voucher Tracking
Path: `/admin/vouchers`

### What you can do
- Create, view, edit, delete vouchers
- Search by voucher code or member name
- Filter by voucher status

### Voucher fields
- Member (required)
- Voucher code (required, unique)
- Issued date (required)
- Expiry date (required)
- Status (`issued`, `redeemed`, `expired`)
- Property (optional)

## 6. Purchase Tracking
Path: `/admin/purchases`

### What you can do
- Create, view, edit, delete purchases
- Search by member name
- Filter by payment mode

### Purchase fields
- Member (required)
- Amount (required, must be greater than 0)
- Purchased date (required)
- Payment mode (`cash`, `card`, `upi`, `bank_transfer`)
- Property (optional)

## 7. Guest Import Flow (Opera CSV via IMAP)
This flow is asynchronous and production-safe.

### Step 1: Configure IMAP in Settings
Path: `/admin/settings`

Required settings:
- `imap_host`
- `imap_port` (typically `993`)
- `imap_username`
- `imap_password` (encrypted in DB)
- `imap_folder` (example: `INBOX`)

### Step 2: Configure CSV mapping
`csv_mapping_json` defines how incoming headers map to CRM fields.

Example:
```json
{
  "full_name": "guest_name",
  "phone": "phone",
  "email": "email",
  "checkin_date": "checkin",
  "checkout_date": "checkout"
}
```

### Step 3: Hourly fetch job runs
- `ImapFetchJob` fetches unread emails from configured folder via SSL
- CSV attachments are saved to `tmp/imports`
- Processed messages are marked seen only on success
- Idempotent attachment naming prevents duplicate processing

### Step 4: CSV import jobs run
- `CsvImportJob` processes each file
- `Imports::CsvImportService` parses rows, normalizes phone numbers, computes row fingerprints, and upserts guest stays idempotently
- Bad rows are skipped and counted; row-level warnings are logged

### Monitoring import status
- Guest records: `/admin/guest_stays`
- Import execution history: `/admin/import_runs`

## 8. Promotion Campaigns (Bulk WhatsApp)
Path: `/admin/promotion_campaigns`

### Audience options
- `members`
- `guests`
- `custom_upload` (CSV/XLS/XLSX)

### Create campaign
Path: `/admin/promotion_campaigns/new`

Input:
- Name
- Template name
- Audience type
- Optional contacts file (required for `custom_upload`)
- Variables input (comma-separated; supports placeholders)

Example variables:
- `Hello {{name}}`
- `Offer valid till Sunday`

### Processing flow
1. Campaign is created as `queued`
2. Recipients are built and de-duplicated by phone
3. `ProcessPromotionCampaignJob` sends messages through `WhatsappService`
4. Per-recipient status tracked as `pending`, `sent`, or `failed`
5. Attempt count and last error are stored
6. Campaign totals update automatically

### Rate limiting
Set env var `WHATSAPP_RATE_LIMIT_PER_MINUTE` (default: `60`).

## 9. Settings Management
Path: `/admin/settings`

All configurable runtime credentials are DB-managed (no hardcoding):
- `whatsapp_api_key` (encrypted)
- `whatsapp_phone_id`
- `imap_host`
- `imap_port`
- `imap_username`
- `imap_password` (encrypted)
- `imap_folder`
- `csv_mapping_json`

Behavior:
- Sensitive fields are masked in UI
- Leaving sensitive field blank keeps existing secret
- Values cached for fast reads
- Thread-safe writes via mutex

Helper methods used internally:
- `AppSetting.get("key")`
- `AppSetting.set("key", value)`

## 10. Security Controls
Implemented controls:
- Lockbox encryption for sensitive settings in DB
- Parameter filtering for secrets in logs (`imap_password`, `whatsapp_api_key`, etc.)
- SSL enforced in production (`force_ssl`, `assume_ssl`)
- Structured JSON-style logging for critical services and jobs
- Unique constraints and DB validations for idempotency

Important note:
- The current app does not include user authentication/authorization screens yet. Since this is internal software, deploy behind network/VPN or add auth before wider exposure.

## 11. Health and Operations Endpoints
- Rails liveness: `/up`
- Sidekiq/Redis health: `/health/sidekiq`
- Sidekiq web UI: `/sidekiq`

`/health/sidekiq` returns:
- status
- redis ping result
- default queue latency
- timestamp

## 12. Background Jobs and Queues
Configured job queues:
- `critical`
- `default`
- `low`

Main jobs:
- `ImapFetchJob` (hourly fetch + enqueue CSV imports)
- `CsvImportJob`
- `ProcessPromotionCampaignJob`
- `SendPromotionJob`
- `SendBirthdayJob`
- `SendAnniversaryJob`

Retries and dead job handling:
- Per-job retry settings enabled
- Sidekiq dead job and error handlers emit structured logs

## 13. Data Model Summary
Core entities:
- `Property`
- `Member`
- `Voucher`
- `Purchase`
- `GuestStay`
- `ImportRun`
- `AppSetting`
- `PromotionCampaign`
- `CampaignRecipient`

Highlights:
- Unique keys: membership number, voucher code, import checksum (scoped), row fingerprint
- Foreign keys present for relational integrity
- Check constraints for counters and date validity

## 14. Daily Operations SOP
1. Open dashboard and review KPI cards.
2. Check `/admin/import_runs` for failed imports.
3. Review `/admin/promotion_campaigns` for failed recipients.
4. Fix settings if needed at `/admin/settings`.
5. Retry campaign/import by re-queueing from operational process.
6. Monitor `/sidekiq` queue health.

## 15. Troubleshooting
### Import is not happening
- Verify IMAP settings in `/admin/settings`
- Confirm unread email has CSV attachment
- Check `ImapFetchJob` in Sidekiq and logs
- Check `/admin/import_runs` for error runs

### Campaign stuck or failing
- Verify WhatsApp credentials in settings
- Check recipient data has valid phone numbers
- Review campaign `last_error` and recipient errors
- Check Sidekiq retries/dead jobs in `/sidekiq`

### Duplicate guest records concern
- Import is idempotent via row fingerprint and file checksum logic
- Re-running same file should not create duplicate guest stays

## 16. Environment Variables (Production)
Minimum expected vars:
- `RAILS_ENV=production`
- `DATABASE_URL` (PostgreSQL)
- `REDIS_URL`
- `LOCKBOX_MASTER_KEY`
- `RAILS_MASTER_KEY` (if credentials are used)
- `BASIC_AUTH_USERNAME`
- `BASIC_AUTH_PASSWORD`

Recommended:
- `BACKGROUND_JOBS_ENABLED=true`
- `WHATSAPP_PROVIDER=meta`
- `WHATSAPP_RATE_LIMIT_PER_MINUTE=60`
- `WHATSAPP_OPEN_TIMEOUT=5`
- `WHATSAPP_READ_TIMEOUT=10`
- `WHATSAPP_WRITE_TIMEOUT=10`
- `WHATSAPP_RETRY_COUNT=3`
- `IMAP_OPEN_TIMEOUT=10`
- `IMAP_READ_TIMEOUT=30`

## 17. Deployment Notes (Fly.io and DigitalOcean)
Application is cloud-portable by design:
- Uses env var based configuration (`DATABASE_URL`, `REDIS_URL`, etc.)
- No cloud vendor specific business logic
- Dockerized runtime with production asset precompile

For Fly.io:
- Build from `Dockerfile`
- Run migrations on release
- Ensure health checks hit `/up` and `/health/sidekiq`

For DigitalOcean migration:
- Reuse same container image pattern
- Set same env vars and managed PostgreSQL/Redis URLs
- No application code changes required

Demo mode for Render free:
- Set `BACKGROUND_JOBS_ENABLED=false` to run without Sidekiq worker.
- Campaigns are saved as draft and not enqueued.
- Admin UI shows a warning banner that background jobs are disabled.

Foreground demo processing mode:
- Set `BACKGROUND_JOBS_ENABLED=false` and `SYNC_PROCESSING=true`.
- Promotion campaigns are processed immediately in the web request (no Sidekiq required).

## 18. Test Coverage and Quality Status
Current automated test suite includes:
- Model specs
- Service specs
- Job specs
- Request specs
- Factories via FactoryBot
- Edge and failure scenario coverage

Latest run status: `86 examples, 0 failures`.

## 19. Recommended Client Usage Policy
- Restrict admin URL to internal network/VPN
- Rotate WhatsApp and IMAP credentials periodically
- Keep DB backups daily
- Monitor Sidekiq queue backlog and dead jobs
- Review import and campaign failures every day

## 20. Support Handover Checklist
Before go-live, confirm:
- Settings are configured in `/admin/settings`
- Sidekiq worker process is running
- Redis and PostgreSQL are reachable
- Health endpoints return OK
- Test IMAP fetch with a sample CSV mail
- Test one internal WhatsApp campaign
