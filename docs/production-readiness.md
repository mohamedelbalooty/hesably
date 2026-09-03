# Production Readiness Audit

**Gate Status:** 🔴 **BLOCKED**

This document evaluates the readiness of Hesably MVP for production deployment across infrastructure, security, reliability, quality, product, and release processes.

---

## 1. Launch Gate Assessment

The project is currently **BLOCKED** from production rollout due to the following critical issues:

1. **Mobile Performance (OOM Risk):** Missing image compression and aggressive memory handling for `Image.file` on the Receipt Capture screen will lead to Out-Of-Memory (OOM) crashes on low/mid-spec Android devices. (Documented in `docs/performance-validation.md`)
2. **Quality Assurance Gaps:** Complete absence of Mobile Widget/Integration tests and automated Dashboard Playwright E2E tests in the CI pipeline. The existing E2E script (`run-e2e-flow.mjs`) is manual and hardcoded to localhost.
3. **No Network-Failure Graceful Degradation:** Mobile app does not properly handle network timeouts or offline constraints for AI capture, risking frozen loading states.

The project is conditionally **READY FOR STAGING** once the infrastructure secrets are populated in the environment.

---

## 2. Infrastructure

- **Staging/Production Separation:** ✅ Implemented via GitHub Actions (`supabase-migrations.yml` deploys to distinct `SUPABASE_PROJECT_ID` and `SUPABASE_STAGING_PROJECT_ID` environments).
- **Supabase Configuration:** ✅ Initialized.
- **Environment Variables & Secrets:** ✅ Edge Function retrieves `GEMINI_API_KEY` securely via `Deno.env`.
- **Storage Policies:** ✅ Receipts bucket RLS relies on the authenticated user's `business_id` in the folder path (`20260829000000_receipts_storage.sql`).
- **Migrations:** ✅ SQL migrations are clean, declarative, and CI-validated.

## 3. Security

- **RLS (Row Level Security):** ✅ Security fixes applied (`20260830000000_security_fixes.sql`). `WITH CHECK` conditions strictly enforce that `business_id` matches the authenticated `owner_id`.
- **Authentication:** ✅ OTP Phone Auth (Mobile) and Magic Link (Dashboard) are correctly isolated.
- **Account Linking:** ✅ `shouldCreateUser: false` implemented on Dashboard to block unlinked public signups.
- **Private Receipts:** ✅ Storage bucket is private.
- **Secret Exposure:** ✅ `GEMINI_API_KEY` is not present in client-side code; proxy through Edge Function is verified.
- **Logging:** ⚠️ Supabase logs capture extraction requests, but client-side error monitoring (Crashlytics/Sentry) is missing.

## 4. Reliability

- **Error Handling:** ⚠️ AI fallback to manual entry is architected, but mobile offline/timeout edge cases need robust handling.
- **Retry/Idempotency:** ✅ Edge Function employs an idempotency check (`X-Cache: HIT`) to prevent duplicate Gemini API billing for the same image upload. Rate limiting is active (20 req/min).
- **Backups/Recovery:** ⚠️ Relies on Supabase default automated backups (PITR depends on project tier).
- **Monitoring & Alerting:** 🔴 Missing. No alerts configured for Edge Function failures or high CPU utilization.

## 5. Quality

- **Unit Tests:** ✅ Mobile BLoC and Domain layers are well-tested (26/26 passing in `apps/mobile/test/features/`).
- **Widget Tests:** 🔴 Missing. No UI verification.
- **Integration Tests:** 🔴 Missing. Mobile flows cannot be verified automatically.
- **E2E / Browser Validation:** 🔴 Playwright tests missing. `run-e2e-flow.mjs` validates the Supabase database model but not the Next.js frontend UI.
- **Lint/Analyze/Build:** ✅ Configured for Flutter and Dashboard in GitHub Actions.

## 6. Product

- **MVP Scope Compliance:** ✅ Core journeys (Auth, Image Capture, AI Draft, Confirmation, Dashboard reporting) align with `feature-list.md`.
- **Critical Flows:** ✅ AI extraction output is treated as a draft and is explicitly confirmed before saving to the ledger.
- **Empty/Loading/Error States:** ⚠️ Network error states and image loading spinners need validation on devices.
- **Arabic RTL:** ✅ Maintained as the default UI locale.
- **Dashboard/Mobile Consistency:** ✅ Data models are tightly coupled via Supabase schema.

## 7. Release

- **Versioning:** ⚠️ Unified versioning strategy (e.g., semantic-release) is not configured.
- **Android/iOS/Web Readiness:** 🔴 Android is blocked by memory optimizations. Web needs Vercel deployment confirmation.
- **Migration Order:** ✅ Supabase migrations push before client deployments in CI/CD pipeline.
- **Rollback Plan:** 🔴 No defined data rollback strategy for destructive schema changes.

---

## Action Plan to Unblock Production

1. Implement `flutter_image_compress` or similar for receipt uploads to avoid OOM limits.
2. Add offline/timeout interceptors in Flutter HTTP client with UI error dialogues.
3. Migrate `run-e2e-flow.mjs` into a Playwright test suite and add UI assertions.
4. Add basic Mobile integration tests covering the end-to-end receipt capture flow.
