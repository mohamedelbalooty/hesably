# Requirements Analysis

## Executive Summary
Hesably is an AI-powered receipt and bookkeeping application tailored for small business owners in Egypt. The MVP focuses on a mobile-first experience allowing users to capture physical receipts, extract data via the Gemini Vision API, and track basic income and expenses. The backend leverages Supabase for auth, database, and edge functions. A Next.js web dashboard provides a companion view for larger screen reporting and management. The primary goal of the MVP is to provide a frictionless, culturally localized (Arabic RTL), and accurate data entry experience without the overhead of full double-entry accounting.

## Product Actors
- **Business Owner (Solo):** The primary and only actor in the MVP. Can authenticate via phone, set up a business profile, capture receipts, manually enter transactions, view reports, and manage categories. On the web dashboard, they can view and export data using a linked email address.
- *(Phase 2)* **Employee/Accountant:** A secondary user with restricted permissions (e.g., read-only or capture-only). Out of scope for MVP.

## Core Journeys
### Mobile (Source of Truth)
1. **Onboarding:** Phone OTP login -> Business profile creation (name, type, currency).
2. **Transaction Capture:** Select Sale/Purchase -> Camera/Gallery capture (or skip to manual) -> AI processing via Edge Function -> Review & Edit form -> Confirm & Save.
3. **Transaction Management:** Browse chronological list, filter by type/category/date, search, view details, edit, or delete.
4. **Reporting:** View high-level metrics (income/expense/net), category breakdown, and export to PDF/CSV.
5. **Settings:** Manage business profile, categories, and enable Web Access by linking an email.

### Dashboard (Companion)
1. **Authentication:** Email Magic Link login (blocked if email was not linked via mobile).
2. **Overview:** View summary cards, charts, and recent transactions.
3. **Data Management:** Filter, search, and view detailed transactions with full-size receipt images. Edit and delete entries.
4. **Reporting:** Generate richer charts and export data directly.

## Feature Dependency Map
- **Business Profile** depends on **Phone Authentication**.
- **AI Extraction** depends on **Image Capture** and **Supabase Edge Functions / Gemini API**.
- **Transaction Save** depends on **User Confirmation** (Review & Edit).
- **Dashboard Access** depends on **Web Access Linking** (Mobile settings).
- **Reports & Exports** depend on **Saved Transactions**.

## Business Rules
- **One Business Per User:** An account is tied to exactly one business in the MVP.
- **Data Trust Boundary:** AI extraction is considered a "draft." Unverified AI data must never be automatically committed to the main ledger.
- **Transaction Types:** Strictly limited to `income` and `expense` at the database level.
- **Localization:** Arabic (RTL) is the default and primary language.
- **Account Creation:** The mobile app is the sole source of truth for account creation. The dashboard cannot create new accounts.

## Data Entities
- **User (Auth):** Provided by Supabase Auth (identities for Phone and Email).
- **Business:** Stores business profile (name, type, currency, owner_id).
- **Category:** Defines transaction classifications (name, is_default, is_hidden, business_id).
- **Transaction:** The core ledger entry (amount, date, type, vendor/customer, category_id, receipt_image_url, business_id).
- **AI Extraction Draft:** Optional transient entity/table to log AI responses for debugging and analytics without polluting the ledger.

## External Integrations
- **Supabase Auth:** Phone OTP (requires SMS provider integration) and Email Magic Links.
- **Gemini Vision API:** Multimodal AI data extraction from receipts via Supabase Edge Functions.
- **Egypt ETA E-invoice/E-receipt:** *(Phase 2)* Out of scope for MVP, but data structures (Sale/Purchase) should be ready for future mapping.

## Trust/Security Boundaries
- **Supabase RLS:** All database queries must be filtered by `business_id` to ensure tenants cannot read or write each other's data.
- **Storage:** Receipt images must reside in a private bucket, accessible only via authenticated signed URLs or RLS-protected storage policies.
- **Gemini API:** Keys must be kept strictly server-side inside Supabase Edge Functions. The client never talks to Gemini directly.
- **Review Boundary:** The client application enforces that AI data is presented in an editable form and only saved upon explicit user action.

## Error States
- **AI Extraction Failure (Low confidence/blur):** Gracefully falls back to the manual entry form. Never forces the user to correct garbage data.
- **Offline Capture:** Blocked in MVP. Explicit message prompts the user to connect to the internet or use manual entry later.
- **OTP/Magic Link Failure:** Provide clear resend capabilities with cooldown timers.
- **Unlinked Dashboard Login:** Block access with a message directing the user to enable web access on their mobile app.

## MVP Boundary
**In Scope:**
- Phone OTP, one business per user.
- AI receipt capture (mobile only).
- Income/expense tracking with categories.
- Basic reporting and PDF/CSV export.
- Companion Next.js dashboard (read/edit/reporting).

**Out of Scope (Phase 2/3):**
- Full double-entry accounting, payroll, multi-currency.
- Multi-user / multi-branch support.
- Offline sync capabilities.
- ETA e-invoice submission.
- Web-based AI receipt capture or public web signups.

## Contradictions and Assumptions

### 1. UI Terminology vs Backend Schema
- **Source Requirement:** `user-flow-mobile.md` asks for "Sale/Income" vs "Purchase/Expense" selection. `AGENTS.md` strictly limits `transactions.type` to `income` and `expense`.
- **Conflict:** A "Sale" needs to be distinguishable from general "Income" for future ETA e-receipt compliance, but the core type is limited.
- **Recommended Decision:** Retain `income` and `expense` as the strict database `type`. Distinguish Sales and Purchases using standard system `categories` (e.g., a locked Category for "Sales") or introduce an optional `document_type` field (e.g., `receipt`, `invoice`).
- **Impact:** Keeps the database enum simple and strictly accounting-based, while satisfying the product UI needs.

### 2. MVP Offline Behavior
- **Source Requirement:** `user-flow-mobile.md` states "Queue locally... (or, for true MVP, simply block with a clear message... decide based on Phase 1 vs Phase 2 scope)". `feature-list.md` lists offline mode in Phase 2.
- **Conflict:** Implementing local queueing and sync is a significant engineering effort that jeopardizes MVP timelines.
- **Recommended Decision:** Strictly block AI capture when offline during the MVP. Show a clear error: "Internet connection required for AI processing. Please connect or enter manually." Defer all local queueing to Phase 2.
- **Impact:** Greatly simplifies state management and network error handling in Phase 1.

### 3. Mobile Phone Auth vs Dashboard Magic Link
- **Source Requirement:** MVP uses phone-only auth on mobile, but email magic links on the dashboard.
- **Conflict:** A user authenticated via phone on mobile needs an email identity to access the dashboard, but there is no native email/password flow.
- **Recommended Decision:** Leverage Supabase Identity Linking. The user logs in via phone on mobile. To enable web access, they input an email, and the app calls `supabase.auth.linkIdentity({ email })`. The dashboard then authenticates via this linked email.
- **Impact:** Requires careful implementation of identity linking and confirmation flows, but perfectly matches the product requirements.

### 4. One-Business-per-User vs Future-Proof Data Isolation
- **Source Requirement:** `AGENTS.md` states MVP supports one business per user, but tables should be keyed by `business_id` to prepare for multi-business.
- **Conflict:** If there's only one business per user, `user_id` might seem sufficient for RLS.
- **Recommended Decision:** Explicitly model the `business_id` on all tenant-specific tables (`transactions`, `categories`). Create a Postgres function or rely on an `owner_id` in the `businesses` table to resolve RLS policies. Do not use `user_id` on the `transactions` table directly.
- **Impact:** Slightly more complex RLS upfront, but zero data migration needed for Phase 2 multi-business.

## Open Decisions
- **AI Extraction Model:** Should we use Gemini 1.5 Flash (faster, cheaper) or Gemini 1.5 Pro (more accurate)? Flash is recommended for MVP latency constraints.
- **Dashboard Deployment:** Verify if Vercel is the confirmed deployment target for the Next.js app, as hinted in `AGENTS.md`.

## Definition of a Successful MVP
The MVP is successful if a non-technical Egyptian shop owner can download the app, log in via OTP, snap a photo of an Arabic receipt, have the total and date extracted accurately within 5 seconds, save it, and view their monthly net income on both their phone and their companion web dashboard.

---

**STATUS: GO FOR PHASE 2 (ARCHITECTURE)**
