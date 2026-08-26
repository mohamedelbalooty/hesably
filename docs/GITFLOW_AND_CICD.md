# GitFlow & CI/CD — Agent Reference

This document is the contract for how branches, CI checks, and deployments work in this repo. Follow it when implementing any task or feature.

---

## Branching Model

```
main ─────────────────────────────────── production
  │
  └── develop ─────────────────────────── staging
        │
        ├── feature/login-screen
        ├── feature/push-notifications
        └── fix/splash-crash
```

| Branch | Purpose | Deploys to |
|--------|---------|------------|
| `main` | Production-ready releases | Production Supabase |
| `develop` | Integration / staging | Staging Supabase |
| `feature/*` | New features | — |
| `fix/*` | Bug fixes | — |
| `hotfix/*` | Urgent production fixes | Production |

**Flow:** `feature/*` → PR → `develop` → PR → `main`

---

## Agent Workflow: Step by Step

When implementing any task, follow this exact sequence:

### 1. Branch off `develop`

```bash
git checkout develop
git pull origin develop
git checkout -b feature/short-description
```

**Branch naming:**
- `feature/<name>` — new functionality
- `fix/<name>` — bug fix
- `hotfix/<name>` — urgent production fix

Keep names short, kebab-case, descriptive: `feature/user-profile-screen`, `fix/crash-on-login`

### 2. Implement changes

Work within the branch. Follow repo conventions:
- Flutter features: layered architecture (UI → Logic → Data)
- Database changes: use `supabase-postgres-best-practices` skill
- Run `flutter analyze` locally before committing

### 3. Commit with clear messages

```
feat: add user profile screen
fix: resolve crash on login with empty email
chore: update Supabase migration for profiles table
```

Prefix convention: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

### 4. Push and open a PR

```bash
git push -u origin feature/short-description
```

Open a PR targeting `develop` (or `main` for hotfixes). Use the PR template at `.github/pull_request_template.md`.

### 5. Wait for CI to pass

CI runs automatically on PRs. All checks must pass before merge.

### 6. Merge into `develop`

Once approved and CI is green, merge the PR. This triggers staging deployment.

### 7. Release to production

When `develop` is ready for production, open a PR from `develop` → `main`. Merge triggers production deployment.

---

## CI Pipelines

### Flutter CI (`.github/workflows/flutter-ci.yml`)

Triggers on: PRs and pushes to `main` and `develop`.

| Job | What it does | Working directory |
|-----|-------------|-------------------|
| **Analyze** | `flutter analyze --fatal-infos` | `apps/mobile/dashboard` |
| **Test** | `flutter test --coverage` | `apps/mobile/dashboard` |
| **Build Android** | `flutter build apk --debug` (needs analyze + test) | `apps/mobile/dashboard` |
| **Build iOS** | `flutter build ios --no-codesign` (needs analyze + test) | `apps/mobile/dashboard` |

**Order:** analyze + test run in parallel → builds run after both pass.

### Supabase Migrations (`.github/workflows/supabase-migrations.yml`)

Triggers on: PRs and pushes to `main`/`develop` when `supabase/**` files change.

| Job | Condition | Action |
|-----|-----------|--------|
| **Validate** | Always | `supabase db push --dry-run` |
| **Deploy Staging** | Push to `develop` | `supabase db push` → staging project |
| **Deploy Production** | Push to `main` | `supabase db push` → production project |

**Required secrets:** `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID`, `SUPABASE_STAGING_PROJECT_ID`

---

## Pre-Commit Checklist

Before committing, verify locally:

```bash
# From apps/mobile/dashboard/
flutter analyze --fatal-infos   # must pass with zero issues
flutter test                    # all tests must pass
```

For database changes:
```bash
# From repo root
supabase db push --dry-run      # validate migration without applying
```

---

## PR Requirements

Every PR must:

1. **Target the correct branch** — `develop` for features/fixes, `main` for hotfixes
2. **Pass all CI checks** — analyze, test, build
3. **Use the PR template** — fill in description, type, changes, checklist
4. **Include tests** — for new features and bug fixes
5. **Review RLS policies** — if any database schema or policy changes exist

---

## Deployment Summary

| Event | Target | What deploys |
|-------|--------|-------------|
| PR to `develop` | — | CI validation only |
| Merge to `develop` | Staging | Supabase migrations auto-deploy |
| PR to `main` | — | CI validation only |
| Merge to `main` | Production | Supabase migrations auto-deploy |

Flutter app builds are CI-only (no auto-deploy to stores). App store releases are manual.

---

## Hotfix Process

For urgent production fixes:

```bash
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug-fix
# fix the issue
git commit -m "fix: critical bug description"
git push -u origin hotfix/critical-bug-fix
# open PR → main
```

After merge to `main`, backport the fix to `develop`:

```bash
git checkout develop
git merge main
git push origin develop
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Start new feature | `git checkout develop && git checkout -b feature/name` |
| Run analysis | `cd apps/mobile/dashboard && flutter analyze` |
| Run tests | `cd apps/mobile/dashboard && flutter test` |
| Validate migrations | `supabase db push --dry-run` |
| Push branch | `git push -u origin feature/name` |
| Switch to develop | `git checkout develop` |
| Backport hotfix | `git checkout develop && git merge main` |
