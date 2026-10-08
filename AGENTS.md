# Hesably

## Repository Documentation

Before starting a new feature, sprint, migration, architectural change, or cross-platform flow, read the project documentation in this order. These documents are cumulative and should be treated as the source of truth for product and technical decisions:

1. `docs/feature-list.md` — MVP scope, roadmap, and non-functional requirements.
2. `docs/user-flow-mobile.md` — screen-by-screen Flutter mobile flows and edge cases.
3. `docs/user-flow-dashboard.md` — screen-by-screen Next.js dashboard flows and edge cases.
4. `docs/requirements-analysis.md` — product and business analysis.
5. `docs/architecture.md` — technical architecture, data model, RLS design, and AI/Gemini integration.
6. `docs/ai-extraction-spec.md` — AI extraction pipeline, prompts, validation rules, and JSON contract.
7. `docs/development-plan.md` — sprint plan and vertical-slice implementation order.
8. `docs/test-strategy.md` — testing strategy and coverage expectations.
9. `docs/GITFLOW_AND_CICD.md` — branching, pull requests, CI/CD, and deployment workflow.

If a referenced document does not exist, do not invent its contents. Treat that as an unfinished phase and follow the ordered documentation workflow before making decisions that depend on it.

When implementation and documentation disagree, stop and resolve the discrepancy using the project documentation rather than silently inventing a new behavior.

## Project Structure

- **Monorepo** with `apps/`, `supabase/`, and `docs/` at the repository root.
- `apps/mobile/` — Flutter mobile application for iOS and Android. This directory contains only the Flutter project.
- `apps/dashboard/` — Next.js web dashboard. It is a sibling of `apps/mobile/`, not nested inside it.
- `supabase/` — Supabase project containing database migrations, RLS policies, Storage configuration, Edge Functions, and related backend configuration.
- `docs/` — product requirements, architecture, AI extraction specifications, development plan, testing strategy, and CI/CD documentation.

Backend is **Supabase**. There is no separate custom backend. Both the mobile app and dashboard use the same Supabase project and data model.

## Architecture

### Mobile

- Flutter 3.x / Dart 3.x.
- Null safety, records, sealed classes, and idiomatic modern Dart where appropriate.
- Layered architecture: **Presentation → Domain → Data**.
- Supabase access belongs in the Data layer; UI code must not contain direct database implementation details.
- Keep business rules testable independently from widgets and platform code.

### Dashboard

- Next.js with the App Router.
- TypeScript.
- Tailwind CSS + shadcn/ui.
- Tremor for data visualization where appropriate.
- TanStack Query for server/data fetching and caching.
- Supabase JavaScript client for authentication and database access.
- Deployed through Vercel.

### Backend

- Supabase Postgres.
- Row Level Security (RLS).
- Supabase Auth.
- Supabase Storage.
- Supabase Edge Functions.

### AI

- Gemini API for multimodal receipt/invoice extraction.
- Gemini credentials are **server-side only**.
- The Gemini API key must never be embedded in Flutter, Next.js, browser code, source-controlled configuration, or other client-side code.
- All Gemini requests must go through a Supabase Edge Function.

Expected integration pattern:

```text
Mobile or Dashboard
        ↓
Supabase Edge Function
        ↓
Gemini API
        ↓
Validated structured JSON
        ↓
Client review/edit flow
        ↓
User confirmation
        ↓
Supabase transaction record
```

## Critical Data Integrity Rules

### AI extraction is never trusted as final data

AI output is a **draft**, not a fact.

- AI extraction results belong in `ai_extractions` or the structure explicitly defined by `docs/architecture.md`.
- An AI response must never directly create or update a final `transactions` row.
- A transaction may be persisted only after the user explicitly reviews and confirms the extracted data.
- The Review & Edit screen is the trust boundary between AI output and committed business data.
- Low-confidence or failed extraction must fall back to manual entry instead of forcing the user to accept unreliable data.

### Transaction type

`transactions.type` is intentionally limited to:

- `income`
- `expense`

Do not introduce values such as `sale`, `purchase`, `refund`, or similar into the type enum unless an explicit architectural/product decision is recorded in `docs/architecture.md`.

More specific business distinctions belong in the appropriate category or additional field defined by the architecture.

### MVP business ownership

- MVP supports **one business per user**.
- `businesses.owner_id` is unique unless `docs/architecture.md` explicitly changes this design.
- Do not implement multi-business UI, business switching, or a `business_members` table in MVP.
- New business-related records should remain keyed by `business_id` where appropriate so multi-business support can be introduced later without unnecessarily breaking the data model.

### Data isolation and security

- Prefer Supabase RLS over client-side or application-only authorization checks.
- Every business-owned table must have an RLS strategy before it is used in production code.
- Users must only be able to read/write records belonging to their authorized business/account.
- Receipt images must be stored in a **private** Supabase Storage bucket.
- Never expose service-role credentials to client applications.

## Product Scope Rules

The MVP is a mobile-first receipt/invoice capture and bookkeeping assistant for small business owners in Egypt.

Primary MVP capabilities include:

- Phone OTP authentication.
- Business onboarding.
- Receipt capture through camera or gallery.
- Manual transaction entry.
- Gemini-assisted extraction.
- Review and edit before save.
- Income/expense transaction management.
- Categories and custom categories.
- Dashboard and reports.
- PDF and Excel/CSV export.
- Business settings and account management.

### Important scope constraints

- Arabic with RTL is the default UI language across mobile and dashboard.
- English is secondary and may be added where explicitly planned.
- MVP is lightweight and should work well on mid/low-spec Android devices.
- Avoid unnecessary animations and heavy client-side work.
- Full accounting/double-entry bookkeeping is out of scope for MVP.
- Payroll is out of scope for MVP.
- Multi-currency is out of scope for MVP.
- Direct government tax filing/submission is out of scope for MVP and requires legal/compliance review before Phase 2.
- Egypt e-invoice/e-receipt integration is Phase 2 or later.

Do not expand MVP scope without updating the relevant product documentation.

## Cross-Platform Consistency

The mobile app and dashboard operate on the same Supabase data model.

When implementing the same business capability on both platforms:

- Keep field definitions, enums, validation rules, and permissions consistent.
- Reuse the same underlying business semantics even when the UI differs.
- Do not create platform-specific database concepts without an explicit architectural reason.
- Mobile is the source of truth for account creation in MVP.
- Dashboard is a companion experience for reviewing data, reporting, and light management.
- Receipt camera capture and AI extraction remain mobile-focused for MVP unless the requirements explicitly change.

### Web authentication

Current MVP direction:

- Mobile authentication uses phone number + OTP.
- Dashboard authentication uses email magic link.
- Web access is enabled/linked from the mobile app.
- Dashboard must not provide an independent public self-signup flow for MVP.
- If a user attempts web access without a linked business account, show the documented blocked-login state rather than creating a new account.

Treat this as the current product direction and update the relevant docs before changing the authentication model.

## Development Workflow

Before implementing a new sprint or major feature:

1. Read the applicable product and technical docs in the order defined above.
2. Confirm prerequisite docs and earlier sprints are complete.
3. Inspect the existing code before introducing new abstractions.
4. Follow the established architecture and naming conventions.
5. Implement the smallest complete vertical slice needed for the current requirement.
6. Add or update tests for the changed behavior.
7. Run the appropriate validation commands.
8. Update documentation when a behavior, contract, schema, or architecture decision changes.

Do not implement future-phase functionality merely because it appears in the roadmap.

## Commands

### Mobile

Run from `apps/mobile/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Use additional Flutter commands only when required by the task, such as `flutter build apk`, `flutter build appbundle`, or `flutter build ipa`.

### Dashboard

Run from `apps/dashboard/`:

```bash
npm install
npm run dev
npm run lint
npm run build
```

Do not assume a dashboard command exists if it is not present in `package.json`. Inspect the actual scripts before running or documenting additional commands.

### Supabase

Run from the repository root:

```bash
supabase start
supabase db push
supabase functions serve
```

Use `supabase init` only when initializing a new Supabase project scaffold, not as part of every development cycle.

## Database and Supabase Conventions

Before writing or changing any of the following, use the `supabase-postgres-best-practices` skill:

- Postgres schema.
- Tables and columns.
- Constraints and indexes.
- RLS policies.
- SQL functions/triggers.
- Database migrations.
- Storage/security rules that depend on database authorization.

When making database changes:

- Prefer explicit, reversible migrations.
- Keep RLS enabled on user/business-owned tables.
- Validate ownership and authorization at the database boundary.
- Avoid duplicating authorization logic unnecessarily in clients.
- Preserve backward compatibility unless the migration is explicitly intended to be breaking.

## AI / Gemini Conventions

Before changing AI extraction behavior:

- Read `docs/ai-extraction-spec.md` when it exists.
- Preserve the documented JSON contract.
- Validate model output server-side before returning it to clients.
- Handle malformed, incomplete, non-receipt, handwritten, blurry, or low-confidence inputs gracefully.
- Never expose Gemini credentials to clients.
- Never bypass the review/confirmation boundary.

If the extraction contract changes, update both the technical documentation and all affected clients/tests.

## Testing and Quality

Testing expectations should follow `docs/test-strategy.md` when present.

At minimum:

- Run `flutter analyze` for Dart/Flutter changes.
- Run relevant Flutter tests for mobile behavior.
- Run `npm run lint` for dashboard changes.
- Run the dashboard build when changes can affect production compilation.
- Test security-sensitive Supabase changes with the relevant RLS/migration validation strategy.
- Do not consider a feature complete if its critical happy path works but documented error states do not.

Prioritize tests around:

- Authentication and session handling.
- AI extraction and validation.
- Review/confirm/save workflow.
- Transaction calculations.
- RLS and business data isolation.
- Filtering/reporting/export behavior.
- Critical mobile and dashboard user flows.

## Error Handling Rules

User-facing failures must be recoverable and actionable.

Examples from the product flows include:

- OTP failure → inline error and resend after cooldown.
- Expired magic link → explain the issue and allow sending a new link.
- AI extraction failure → offer manual entry.
- Non-receipt image → explain that the image could not be interpreted and allow retry/manual entry.
- Empty dataset → provide a useful empty state, never a broken-looking screen.
- Delete transaction → require confirmation.

Avoid silent failures, dead-end screens, or generic error messages when a more actionable state is possible.

## UI and UX Conventions

- Arabic/RTL is the default product experience.
- UI must remain usable on small and low-end Android devices.
- Keep loading states visible during network/AI operations.
- Never make a network or AI operation appear as a frozen interface.
- Keep the primary transaction-creation action reachable in one tap from the main mobile experience.
- Maintain consistent terminology between mobile, dashboard, docs, and backend fields.

## Installed Skills

Key agent skills are in `.agents/skills/`. Use the relevant skill instead of improvising established implementation patterns.

### Flutter / Dart

- `flutter-expert`
- `flutter-add-widget-test`
- `flutter-add-integration-test`
- `flutter-apply-architecture-best-practices`
- `flutter-setup-declarative-routing`
- `flutter-setup-localization`
- `flutter-use-http-package`
- `flutter-implement-json-serialization`
- `flutter-build-responsive-layout`
- `flutter-fix-layout-issues`
- `flutter-add-widget-preview`

### Dart

- `dart-run-static-analysis`
- `dart-add-unit-test`
- `dart-generate-test-mocks`
- `dart-collect-coverage`
- `dart-fix-runtime-errors`
- `dart-use-ffigen`
- `dart-setup-ffi-assets`
- `dart-use-pattern-matching`
- `dart-use-primary-constructors`
- `dart-write-documentation`
- `dart-use-doc-examples`
- `dart-resolve-package-conflicts`
- `dart-migrate-to-checks-package`
- `dart-build-cli-app`

### Supabase

- `supabase`
- `supabase-postgres-best-practices`

### AI

- `ai-product`
- `gemini-api-dev`
- `gemini-api-integration`

### Other

- `clean-code`
- `frontend-developer`

Use `frontend-developer` for `apps/dashboard/` work when it provides relevant guidance.

## Branching Model

| Branch | Purpose | Deploys to |
|---|---|---|
| `main` | Production-ready code | Production Supabase |
| `develop` | Integration branch | Staging Supabase |
| `feature/*` | New features; branch from `develop` | — |
| `fix/*` | Bug fixes; branch from `develop` | — |
| `hotfix/*` | Urgent production fixes; branch from `main` | Production |

Flow:

```text
feature/* or fix/* → PR → develop → PR → main
hotfix/* → PR → main
```

Full workflow reference: `docs/GITFLOW_AND_CICD.md`.

Do not commit directly to `main` or `develop` unless the repository workflow explicitly allows it.

## CI/CD

Current CI/CD expectations:

- `.github/workflows/flutter-ci.yml` — runs `flutter analyze` and `flutter test` on PRs to `main`/`develop`, then builds Android APK and iOS without code signing.
- `.github/workflows/supabase-migrations.yml` — validates migrations on PRs and deploys to staging on `develop` push and production on `main` push.
- `.github/workflows/dashboard-ci.yml` — planned for Sprint 6 once `apps/dashboard/` exists; should cover lint/build, while Vercel's GitHub integration handles dashboard deployment.
- `.github/pull_request_template.md` — repository PR template.

Treat CI configuration files as authoritative over this summary if they differ.

## Security Rules

Never:

- Commit API keys, service-role keys, private signing credentials, or secrets.
- Put Gemini credentials in client code.
- Bypass RLS for convenience.
- Make private receipt storage public without an explicit product/security decision.
- Trust client-side ownership checks as the only authorization mechanism.
- Log sensitive credentials, authentication tokens, or private receipt contents unnecessarily.

When credentials/configuration are required, use the repository's documented environment/secret management approach.

## Change Management

When a change affects product behavior, database structure, API contracts, authentication, authorization, AI extraction, or CI/CD:

1. Update the relevant source-of-truth documentation.
2. Update affected implementation and tests.
3. Check all clients that depend on the changed contract.
4. Run the appropriate validation commands.
5. Mention any unresolved product or architecture decision rather than silently guessing.

Keep `AGENTS.md` aligned with the repository, but do not turn it into a copy of every product document. This file contains agent operating rules and the highest-value cross-cutting constraints; detailed requirements belong in `docs/`.
