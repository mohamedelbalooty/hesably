# Observability and Reliability — Hesably

This document defines the observability strategy, reliability mechanisms, and service-quality targets for the Hesably MVP. It aligns with the architecture, security, and AI extraction specifications to ensure a stable, trackable, and safe user experience.

## 1. Logging and Diagnostics

### 1.1 Structured Logs
All backend logs (Supabase Edge Functions, database triggers) and client telemetry (Firebase Crashlytics, Vercel Analytics) must use structured JSON logging where possible to enable efficient querying and filtering.
- **Required Fields**: `timestamp`, `level` (INFO, WARN, ERROR), `service` (mobile, dashboard, edge-function), and contextual IDs like `business_id` (if authenticated).

### 1.2 Request/Correlation IDs
- **`extraction_id`**: A client-generated UUID created when the user initiates a receipt capture. This ID flows from the mobile app to the Edge Function and into the Supabase `ai_extractions` table. It must be included in all logs related to a single extraction attempt to trace the full lifecycle across boundaries.

### 1.3 Security & Privacy in Logging
**Critical Rule**: Logging must *never* expose sensitive data.
- **Do NOT log**: Plain-text receipt contents, raw base64 image data, Gemini API keys, Supabase Service Role keys, Auth JWT tokens, user phone numbers, or email addresses.
- **Diagnostic Storage**: Diagnostic data related to receipts must only be stored in the `ai_extractions` audit table and the secure `receipts` storage bucket. Both are subject to a strict 30-day retention policy via `pg_cron` hard-deletion.

## 2. Error Handling & Taxonomy

### 2.1 Error Taxonomy
Errors across the stack are categorized to determine the correct retry and fallback behavior:
- **Client Transient Errors**: Network drops or timeouts before reaching the backend.
- **Backend Transient Errors**: Edge Function timeouts, Gemini API 503/5xx errors, or Supabase database connection issues.
- **Validation/Client Errors (4xx)**: Malformed payloads, invalid image types, overly large images (failing the `< 1MB` rule), or unauthorized access (401).
- **AI Processing Errors**: Gemini safety filter blocks (`FinishReason.SAFETY`), unparseable AI responses, or "Not a receipt" detections.
- **Business Logic Errors**: E.g., attempting to delete a category that is actively used by transactions.

### 2.2 User-Safe Error Messages
User-facing failures must be recoverable and actionable. Silent failures, dead-end screens, or raw technical error strings are not permitted.
- **OTP Failure**: "We couldn't send the code. Please wait a moment and try again."
- **Magic Link Expired**: "This link has expired. Please request a new one."
- **AI Timeout/Failure**: "AI processing took too long. Please enter manually."
- **Non-Receipt Image**: "Couldn't read this as a receipt. Please try again or enter manually."
- **Network Error**: "Please check your connection and try again."
- **Empty Dataset**: Provide a useful empty state illustration/message rather than a broken or blank screen.

## 3. Resilience Policies

### 3.1 Timeout Policy
- **Edge Function Limit**: 15 seconds maximum execution time.
- **Mobile Client HTTP Timeout**: 15 seconds for AI extraction requests.
- **Fallback**: If a timeout occurs, the UI falls back gracefully to manual entry.

### 3.2 Retry Policy
- **Transient Errors (5xx, Timeout, Network Drop)**: The mobile app may automatically retry *once* if the request fails before reaching the 15-second user-facing limit.
- **Validation Errors (4xx, Gemini Policy Block)**: The app must *never* auto-retry. Fall back to manual entry immediately.

### 3.3 Idempotency
- The client-generated `extraction_id` (UUID) ensures idempotency.
- If the app retries a network-dropped request, it sends the same `extraction_id`.
- The Edge Function must check if this request is currently being processed (or already succeeded) to prevent double-processing and duplicate Gemini API billing.

## 4. AI Extraction Lifecycle & Metrics

### 4.1 AI Extraction Lifecycle States
As recorded in the `ai_extractions` table (`status` column):
1. **`processing`**: Request received by Edge Function, waiting on Gemini API.
2. **`success`**: Validated draft successfully returned to the client.
3. **`failure`**: Timeout, validation error, safety block, or Gemini failure.

*Note: The user-facing lifecycle (Confirmed / Discarded) lives in the client state and `transactions` table.*

### 4.2 Key Performance Indicators (KPIs) & Service-Quality Targets

| Metric | Definition | MVP Target | Status |
|---|---|---|---|
| **Extraction Latency** | Time from client upload to receiving validated JSON. | p90 < 10 seconds | *Proposed, non-binding* |
| **Upload Failure Rate** | Percentage of images that fail to upload to Storage/Edge Function. | < 1% | *Proposed, non-binding* |
| **AI Error Rate** | Rate of Edge Function timeouts or Gemini 5xx errors. | < 2% | *Proposed, non-binding* |
| **Low-Confidence Rate** | Percentage of extractions returning `overall < 0.5` or `is_receipt = false`. | < 15% | *Proposed, non-binding* |
| **Transaction Confirmation Rate**| Percentage of successful AI drafts that are eventually saved to `transactions`. | > 80% | *Proposed, non-binding* |

## 5. Cost & Usage Tracking

### 5.1 AI Usage/Cost Tracking
- AI extraction is the most expensive operational component.
- **Usage Tracking**: The `ai_extractions` table provides a baseline for total attempts and prompt versions used.
- **Rate Limiting**: Implemented per `user_id` on the Edge Function (e.g., max 20 extractions per minute, 500 per day) to prevent malicious budget exhaustion or looping bugs.

## 6. Alerts & Diagnostics

### 6.1 Production Alerts
*Proposed, non-binding targets for MVP operations:*
- **High Error Rate**: Alert if Edge Function 5xx rate exceeds 5% over a 15-minute window.
- **Latency Spike**: Alert if p90 extraction latency exceeds 15 seconds over a 10-minute window.
- **Auth Failure Spike**: Alert if OTP or Magic Link failure rates spike above 10%.
- **Budget Exhaustion**: Alert if Gemini API usage approaches 80% of the daily/monthly budget limit.

### 6.2 Dashboard/Admin Diagnostic Needs
For operational support, admins need the ability to query (via direct SQL or a secure internal tool, preserving RLS and privacy):
- Count of `ai_extractions` per status (`processing`, `success`, `failure`) to monitor system health.
- Rate of manual entry vs. AI extraction.
- Total Active Businesses (tenant count) and transaction volume.
- App crash reports and non-fatal exceptions (via Firebase Crashlytics).
