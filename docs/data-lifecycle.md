# Data Lifecycle Rules

This document defines the retention, cleanup, and state transitions for data within the Hesably system.

## Transactions
- **Creation**: Generated strictly by explicit user confirmation in the mobile app or dashboard (from an AI draft or manual entry).
- **Retention**: Indefinite. Transactions form the permanent financial ledger of the business.
- **Modification**: Fully editable by the user at any time (amount, date, category). Modifying a transaction updates its `updated_at` timestamp.
- **Deletion**: Hard-deleted upon user request (with explicit confirmation UI). Deleting a transaction does not soft-delete; the row is removed entirely.

## Receipt Files (Storage)
- **Creation**: Uploaded by the client *before* AI extraction is requested, or when manually attaching a receipt to a transaction.
- **Retention**: Tied to the lifecycle of the transaction.
- **Orphan Cleanup**: If a user uploads an image, requests an AI extraction, but never hits "Save" on the draft, the image remains in storage unlinked. 
  - **Rule**: A scheduled background job (e.g., `pg_cron` or scheduled Edge Function) will sweep the `receipts` bucket and delete any images older than 24 hours that do not appear in `transactions.receipt_image_path`.

## AI Extraction Drafts
- **Creation**: Inserted by the Edge Function whenever the Gemini API is called and returns a result.
- **State**: Transient. These are considered raw logs/drafts, not business ledger records.
- **Retention**: Kept for 30 days strictly for observability, debugging, and AI accuracy metrics.
- **Deletion**: Automatically hard-deleted by a daily `pg_cron` routine (e.g., `DELETE FROM ai_extractions WHERE created_at < NOW() - INTERVAL '30 days'`).

## Account / Business Deletion
- **Trigger**: User selects "Delete Account" in Settings.
- **Process**: 
  1. An Edge Function or a secure Postgres function is invoked.
  2. The function hard deletes the user's `businesses` record.
  3. Postgres `ON DELETE CASCADE` constraints automatically and immediately destroy all `categories`, `transactions`, and `ai_extractions` associated with that `business_id`.
  4. A cleanup routine sweeps the `receipts` storage bucket and deletes the folder `{business_id}/`.
  5. The `auth.users` identity record is deleted.
- **Retention**: Zero soft-deletion. Data is permanently erased upon account deletion to satisfy user privacy expectations for MVP.

## Exports
- **Creation**: On-the-fly generation triggered from the client (e.g., PDF generation using browser/device tools, or CSV via simple data formatting).
- **Retention**: Ephemeral. Exported documents are never stored persistently on the server; they are generated in memory and saved directly to the user's local device.

## Logs / Audit Data
- **Creation**: Basic `created_at` and `updated_at` timestamps on primary rows.
- **Scope**: Comprehensive audit trails (e.g., tracking historical values or "who changed what and when") are explicitly out of scope for the MVP since it is a single-user system.
- **Edge Function Logs**: Supabase standard log retention (typically 1-7 days depending on the project plan) is relied upon for debugging Gemini API failures. No long-term persistence of function execution logs is required.
