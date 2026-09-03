# Security Design — Hesably

This document outlines the security architecture and controls for the Hesably MVP, covering authentication, data protection, integration security, and operational controls.

## 1. Authentication
Hesably uses Supabase Auth as the primary identity provider.
- **Mobile (Primary):** Phone number with SMS OTP. This is the only allowed entry point for new account creation.
- **Dashboard (Secondary):** Email with Magic Link. Access is exclusively granted to accounts that have linked an email via the mobile app.

## 2. Session Management
- **Mobile:** Supabase Flutter SDK manages session tokens securely on the device.
- **Dashboard:** `@supabase/ssr` manages cookie-based sessions. Cookies must be configured with `HttpOnly`, `Secure`, and `SameSite=Lax` to protect against XSS and CSRF attacks during Server-Side Rendering (SSR).

## 3. Phone OTP Abuse and Rate Limiting
- **Client-Side:** Enforce a strict UI cooldown timer (e.g., 60 seconds) between OTP requests.
- **Server-Side:** Rely on Supabase Auth's built-in rate limits for SMS providers (e.g., Twilio) to prevent toll fraud and SMS pumping attacks.

## 4. Dashboard Magic-Link Authentication
- Magic Links are the sole authentication method for the web dashboard.
- **Constraint:** Open signup via the dashboard is strictly prohibited in the MVP. Middleware must reject or redirect unlinked users attempting to authenticate solely via web.

## 5. Account Linking
- To enable web access, users must explicitly link an email address from the authenticated mobile app (`supabase.auth.linkIdentity()`).
- This ensures the Auth UUID remains consistent across both phone (mobile) and email (web) identities, maintaining referential integrity in the `businesses` table.

## 6. Row Level Security (RLS)
- **Tenant Isolation:** All business data is isolated using Postgres RLS.
- **Enforcement:** Every query against tenant tables (`businesses`, `categories`, `transactions`, `ai_extractions`) must validate that the `business_id` resolves to a business where `owner_id = auth.uid()`.
- Client requests rely entirely on the `authenticated` role; service-role keys are never used in client apps.

## 7. Storage Access
- **Private Buckets:** Receipt images are stored in a strictly private `receipts` bucket.
- **Path Isolation:** Object paths are structured as `{business_id}/{uuid}.jpg` to guarantee folder-level tenant isolation.
- **Storage RLS:** RLS policies on `storage.objects` ensure users can only upload, read, or delete files within their authorized `{business_id}` path.

## 8. Signed URLs
- Because the `receipts` bucket is private, raw public URLs are disabled.
- Clients must generate short-lived Signed URLs (e.g., TTL of 3600 seconds) via the Supabase SDK to render images in the UI.

## 9. Gemini Secret Storage
- The `GEMINI_API_KEY` is an ultra-sensitive secret.
- **Storage:** Stored exclusively in Supabase Secrets vault (`supabase secrets set`).
- **Exposure:** Never hardcoded in source control. Never embedded in Flutter or Next.js client bundles.

## 10. Edge Function Authorization
- The Supabase Edge Function proxying Gemini API requests must reject unauthenticated traffic.
- **Validation:** The function must parse the incoming Authorization header and verify the JWT using the Supabase client before executing any AI logic.

## 11. Input Validation
- **Backend/AI:** The Edge Function must use strict schema validation (e.g., Zod) on the JSON payload returned by Gemini before passing it to the client. Hallucinated keys or malformed structures are stripped or rejected.
- **Client/Database:** Postgres enforces strict types, NOT NULL constraints, and `CHECK` constraints (e.g., `amount > 0`).

## 12. Upload Validation
- The Edge Function (or direct storage upload policy) must validate that the incoming payload is a valid image before processing it for AI extraction.

## 13. File-Type and Size Restrictions
- **Client-Side Compression:** The Flutter app *must* compress images to `< 1MB` locally.
- **Backend Limits:** Supabase Storage bucket configurations should reject files larger than a reasonable threshold (e.g., 5MB max) and restrict MIME types to `image/jpeg`, `image/png`, `image/webp`.

## 14. Abuse and Cost Controls
- AI extraction is the most expensive operation.
- **Rate Limiting:** Implement per-user rate limiting on the Edge Function (e.g., max 20 extractions per minute, max 500 per day) to prevent budget exhaustion from malicious scripts or looping bugs.
- Requests hitting the Edge Function must be idempotent using a client-generated UUID to prevent double-billing on network retries.

## 15. Logging and Sensitive-Data Leakage
- **No PII in Logs:** Ensure Edge Function logs and application crash reports do not capture plain-text receipt data, user phone numbers, or Auth tokens.
- **Audit Table:** Raw AI responses are logged to the `ai_extractions` table for debugging. A `pg_cron` routine explicitly purges this data after 30 days to limit exposure.

## 16. Account Deletion
- Hesably honors the right to be forgotten.
- **Cascade:** Deleting the user from Supabase Auth must cascade to delete the `businesses` record, which cascades to `transactions`, `categories`, and `ai_extractions`.
- **Storage:** Application logic or a backend trigger must explicitly delete the user's files from the `receipts` bucket upon account deletion.

## 17. Data Export
- Export features (PDF/Excel) are generated dynamically based on the user's authorized data.
- The dashboard and mobile app execute these queries using standard RLS-protected endpoints, ensuring users can only export their own ledger.

## 18. Browser Security (Dashboard)
- Next.js must be configured with secure HTTP headers in `next.config.js`:
  - `Content-Security-Policy` (CSP)
  - `X-Frame-Options: DENY`
  - `X-Content-Type-Options: nosniff`
  - `Referrer-Policy: strict-origin-when-cross-origin`

## 19. Dependency and Security Scanning
- CI/CD pipelines (GitHub Actions) must include automated vulnerability scanning for Dart/Flutter (`flutter pub outdated`/`audit`) and Node.js (`npm audit`) dependencies.

## 20. Production Secret Management
- Local development uses `.env` (ignored by git).
- Staging/Production environments manage secrets strictly through Vercel Environment Variables (Dashboard) and Supabase Vault/Dashboard (Database/Edge Functions).

---

## Prioritized Security Checklist

### Critical (Blockers for Launch)
- [ ] RLS policies applied and tested on all tables (`businesses`, `transactions`, `categories`, `ai_extractions`).
- [ ] Storage RLS applied; bucket set to strictly Private.
- [ ] Gemini API Key stored in Supabase Secrets, NOT in client code.
- [ ] Edge Function validates Auth JWT before invoking Gemini.
- [ ] Dashboard middleware enforces authentication; no unlinked web signups allowed.

### High (Resolve Quickly)
- [ ] Next.js SSR session cookies configured as `HttpOnly`, `Secure`.
- [ ] Edge Function implements strict JSON schema validation on Gemini output.
- [ ] Flutter app enforces local image compression (< 1MB) before upload.
- [ ] Storage bucket restricted to specific image MIME types and file sizes.
- [ ] Phone OTP cooldown enforced in mobile UI.

### Medium (Best Practices)
- [ ] `pg_cron` automated 30-day purge configured for `ai_extractions`.
- [ ] Idempotency keys used for AI extraction requests.
- [ ] Edge Function rate limiting per `user_id` to prevent Gemini budget exhaustion.
- [ ] Next.js configured with strict Security Headers (CSP, X-Frame-Options).

### Low (Ongoing / Phase 2)
- [ ] Automated dependency vulnerability scanning in CI/CD.
- [ ] Formal anomaly detection on transaction velocity.
