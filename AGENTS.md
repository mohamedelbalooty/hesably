# Hesably

## Architecture

- **Monorepo** with `apps/`, `supabase/`, and `docs/` at the root.
- `apps/mobile/dashboard/` — Flutter mobile app (target: iOS + Android). Web dashboard may also live here or in a sibling directory.
- `supabase/` — Supabase project (DB, auth, storage, edge functions). Currently empty scaffold.
- Backend: **Supabase** (Postgres, RLS, Auth, Edge Functions, Storage).

## Tech stack

- **Flutter 3.x / Dart 3.x** — null safety, records, sealed classes.
- **Supabase** — `supabase_flutter` client, Postgres with RLS, Edge Functions.
- Web dashboard: TBD (React/Next.js or Flutter web).

## Commands

No code exists yet. Once the Flutter project is initialized:

```bash
# From apps/mobile/dashboard/
flutter pub get
flutter analyze
flutter test
flutter run
```

For Supabase (from repo root):

```bash
supabase init
supabase start        # local dev
supabase db push      # apply migrations
supabase functions serve
```

## Installed skills

Key agent skills are in `.agents/skills/`. Use them via the `skill` tool when relevant:

- **Flutter/Dart**: `flutter-expert`, `flutter-add-widget-test`, `flutter-add-integration-test`, `flutter-apply-architecture-best-practices`, `flutter-setup-declarative-routing`, `flutter-setup-localization`, `flutter-use-http-package`, `flutter-implement-json-serialization`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-add-widget-preview`
- **Dart**: `dart-run-static-analysis`, `dart-add-unit-test`, `dart-generate-test-mocks`, `dart-collect-coverage`, `dart-fix-runtime-errors`, `dart-use-ffigen`, `dart-setup-ffi-assets`, `dart-use-pattern-matching`, `dart-use-primary-constructors`, `dart-write-documentation`, `dart-use-doc-examples`, `dart-resolve-package-conflicts`, `dart-migrate-to-checks-package`, `dart-build-cli-app`
- **Supabase**: `supabase`, `supabase-postgres-best-practices`
- **AI**: `ai-product`, `gemini-api-dev`, `gemini-api-integration`
- **Other**: `clean-code`, `frontend-developer`

## Branching model

| Branch | Purpose | Deploys to |
|--------|---------|------------|
| `main` | Production-ready | Production Supabase |
| `develop` | Integration branch | Staging Supabase |
| `feature/*` | New features, branch off `develop` | — |
| `fix/*` | Bug fixes, branch off `develop` | — |
| `hotfix/*` | Urgent fixes, branch off `main` | Production |

**Flow:** `feature/*` → PR into `develop` → PR into `main`

## CI/CD

- `.github/workflows/flutter-ci.yml` — runs `flutter analyze` + `flutter test` on PRs to `main`/`develop`, then builds Android APK and iOS (no codesign).
- `.github/workflows/supabase-migrations.yml` — validates migrations on PRs; auto-deploys to staging on `develop` push, production on `main` push.
- PR template at `.github/pull_request_template.md`.

## Conventions

- Use `supabase-postgres-best-practices` skill before writing or changing any Postgres schema, RLS policies, migrations, or SQL.
- Prefer RLS over application-level auth checks.
- Use `flutter-apply-architecture-best-practices` when structuring new features (layered: UI → Logic → Data).
- Run `flutter analyze` before committing Dart changes.
