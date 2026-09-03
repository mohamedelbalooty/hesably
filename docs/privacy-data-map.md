# Privacy and Data Map — Hesably

This document maps where user data lives, how it flows through the system, and its lifecycle. It ensures developers and architects understand the boundaries of data privacy within the Hesably platform.

## 1. Data Inventory and Storage Locations

| Data Category | Specific Data Elements | Primary Storage | Protection Mechanism |
|---|---|---|---|
| **Identity & Authentication** | Phone Number, Email Address, Hashed OTP/Tokens, Auth UUID | Supabase Auth (`auth.users`, `auth.identities`) | Managed entirely by Supabase internally. Not exposed to public schema. |
| **Business Profile** | Business Name, Business Type, Currency Preference | Postgres (`public.businesses`) | RLS (`owner_id = auth.uid()`) |
| **Financial Ledger** | Transaction Amount, Date, Type, Category, Vendor Name | Postgres (`public.transactions`, `public.categories`) | RLS via `business_id` join. |
| **Media / Artifacts** | Receipt and Invoice Images (JPEGs, PNGs) | Supabase Storage (`receipts` bucket) | Private bucket, Storage RLS, Short-lived Signed URLs. |
| **Transient AI Data** | Raw Gemini JSON responses, Request Metadata | Postgres (`public.ai_extractions`) | RLS. Hard-deleted automatically after 30 days. |

## 2. Data Flow Architecture

### Flow A: Mobile Account Creation
1. User enters phone number in Flutter app.
2. Flutter contacts Supabase Auth API.
3. Supabase uses an external SMS provider (e.g., Twilio) to send the OTP. *(Privacy Note: Phone number is shared securely with the SMS provider).*
4. User validates OTP; Supabase creates `auth.users` record.
5. User completes Business Setup; Flutter writes to `public.businesses`.

### Flow B: AI Receipt Extraction
1. User captures image in Flutter app and compresses it.
2. Flutter sends image to Supabase Edge Function.
3. Edge Function sends image + prompt to **Google Gemini API**. *(Privacy Note: Google's enterprise API terms state they do not use API data to train their foundation models. The data is processed ephemerally for the response).*
4. Gemini returns JSON. Edge Function writes audit log to `public.ai_extractions`.
5. Edge Function returns draft to Flutter. 
6. User reviews and saves. Flutter writes final financial data to `public.transactions` and uploads image to Supabase Storage.

## 3. Third-Party Data Processors

Hesably relies on the following sub-processors for the MVP:
1. **Supabase (Backend-as-a-Service):** Hosts the Postgres database, Auth system, Edge Functions, and Storage. (Infrastructure likely runs on AWS).
2. **SMS Gateway (e.g., Twilio/MessageBird):** Processes phone numbers to deliver OTPs.
3. **Email Gateway (e.g., Resend / Supabase Default):** Processes email addresses to deliver Magic Links.
4. **Google Cloud (Gemini API):** Processes receipt images and extracts text. Data is processed ephemerally per Google's enterprise API agreements.
5. **Vercel (Dashboard Hosting):** Hosts the Next.js web dashboard. Serverless functions process HTTP requests but do not store persistent data.

## 4. Data Lifecycle and Deletion

Hesably strictly honors data deletion and minimization principles.

### The "Right to be Forgotten"
When a user requests account deletion (via Mobile App Settings):
1. The client invokes a secure account deletion function or Edge Function.
2. The user's identity is deleted from `auth.users`.
3. **Database Cascade:** Due to `ON DELETE CASCADE` foreign keys, the deletion immediately removes the `businesses` record, which cascades to delete all `transactions`, `categories`, and `ai_extractions`.
4. **Storage Cleanup:** A database trigger, webhook, or Edge Function must listen for user deletion and issue a delete command to the Supabase Storage API to permanently wipe all images under the user's `{business_id}/` path.

### Transient Data Minimization
- **AI Extractions:** The `ai_extractions` table acts as a debug and metrics log. To prevent infinite accumulation of potentially sensitive receipt data, a `pg_cron` extension is configured to run daily:
  ```sql
  DELETE FROM ai_extractions WHERE created_at < NOW() - INTERVAL '30 days';
  ```
- **Unlinked Images:** If an image is uploaded for extraction but the user abandons the draft, the image object in Storage will become orphaned. A backend cron job should periodically clean up images in Storage that have no matching `receipt_image_path` in the `transactions` table.

## 5. Security and Privacy Boundaries

- **No Analytics Logging of PII:** Application analytics (e.g., Crashlytics, Vercel Analytics) must only log anonymous UUIDs and event names (e.g., `transaction_created`). They must *never* log transaction amounts, vendor names, or receipt images.
- **No Cross-Business Aggregation:** The MVP does not perform any machine learning or analytical aggregation across businesses. All features operate strictly within the silo of the single authenticated `business_id`.
