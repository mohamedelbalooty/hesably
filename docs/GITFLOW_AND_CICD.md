# GitFlow & CI/CD — Agent Reference

This document is the contract for how branches, CI checks, and deployments work in this repo. Follow it when implementing any task or feature.

---

## 1. Branching Model

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
| `main` | Production-ready releases | Production (DB & Edge Functions) |
| `develop` | Integration / staging | Staging (DB & Edge Functions) |
| `feature/*` | New features | — |
| `fix/*` | Bug fixes | — |
| `hotfix/*` | Urgent production fixes | Production |

**Environment Isolation**: 
- We strictly maintain two separate Supabase projects (Staging and Production).
- Staging and Production GitHub Action environments ensure secrets (e.g. `SUPABASE_STAGING_PROJECT_ID` vs `SUPABASE_PROJECT_ID`) are completely isolated. Production credentials are NEVER used in development or staging workflows.

---

## 2. GitHub Branch Protection Policies

The following protections are configured on the repository:

**`main` Branch:**
- Pull Request required before merging.
- Minimum 1 approving review required.
- Required status checks (CI validations) must pass.
- No direct pushes permitted.
- No force pushes permitted.

**`develop` Branch:**
- Pull Request required before merging.
- Required status checks (CI validations) must pass.
- No direct pushes permitted where practical.

---

## 3. Agent Workflow: Step by Step

When implementing any task, follow this exact sequence:

### 3.1 Branch off `develop`

```bash
git checkout develop
git pull origin develop
git checkout -b feature/short-description
```

### 3.2 Implement changes
- Flutter features: layered architecture in `apps/mobile`.
- Database changes: use `supabase-postgres-best-practices`.
- Node.js dependencies: Use **Node 24 LTS** (defined in `.nvmrc`).
- Run `flutter analyze` locally before committing.

### 3.3 Commit with clear messages
Prefix convention: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`.

### 3.4 Push and open a PR
Open a PR targeting `develop` (or `main` for hotfixes).

### 3.5 Wait for CI to pass
All CI checks must pass before merge.

### 3.6 Merge into `develop`
Once approved and CI is green, merge the PR. This triggers staging deployment.

### 3.7 Release to production
When `develop` is ready for production, open a PR from `develop` → `main`. Merge triggers production deployment.

---

## 4. CI Pipelines

### 4.1 Flutter CI (`.github/workflows/flutter-ci.yml`)
Triggers on: PRs and pushes to `main` and `develop`.
Working directory: `apps/mobile/`

| Job | What it does |
|-----|-------------|
| **Analyze** | `flutter analyze --fatal-infos` |
| **Test** | `flutter test --coverage` |
| **Build Android** | `flutter build apk --debug` (needs analyze + test) |
| **Build iOS** | `flutter build ios --no-codesign` (needs analyze + test) |

### 4.2 Dashboard CI (`.github/workflows/dashboard-ci.yml`)
Triggers on: PRs and pushes to `main` and `develop` when `apps/dashboard/**` changes.
Uses Node 24 LTS.

| Job | What it does |
|-----|-------------|
| **Lint & Build** | `npm ci`, `npm run lint`, `npm run build` |

### 4.3 Supabase Migrations (`.github/workflows/supabase-migrations.yml`)
Triggers on: PRs and pushes to `main`/`develop` when `supabase/**` files change.

| Job | Condition | Action |
|-----|-----------|--------|
| **Validate** | Always | `supabase db push --dry-run` AND `supabase test db` (starts local container for testing) |
| **Deploy Staging** | Push to `develop` | `supabase db push` → staging project |
| **Deploy Production** | Push to `main` | `supabase db push` → production project |

### 4.4 Supabase Edge Functions (`.github/workflows/supabase-functions.yml`)
Triggers on: PRs and pushes to `main`/`develop` when `supabase/functions/**` files change.
*Independent from DB deployment.*

| Job | Condition | Action |
|-----|-----------|--------|
| **Validate** | Always | `deno lint` and `deno test` (uses standard Deno tooling) |
| **Deploy Staging** | Push to `develop` | `supabase functions deploy` → staging project |
| **Deploy Production** | Push to `main` | `supabase functions deploy` → production project |

---

## 5. Deployment Flow Summary

Documented exact deployment lifecycle:

`feature/*`
↓
Pull Request
↓
CI Validation (DB Dry-Run, Deno Lint, Flutter Analyze, Dashboard Build)
↓
`develop`
↓
Staging deployment (DB Push, Functions Deploy, Vercel Staging)
↓
Staging smoke tests
↓
Pull Request `develop` → `main`
↓
CI Validation
↓
`main`
↓
Production deployment (DB Push, Functions Deploy, Vercel Prod)
↓
Production smoke tests
↓
Release Tagging (`v1.0.0` SemVer tags applied to `main`)

---

## 6. Rollback Strategy

Do not assume every database migration has a safe DOWN migration. Rollbacks are scoped by component:

- **Application (Flutter)**: No auto-rollback. Rollback requires a new branch/hotfix and app store submission.
- **Dashboard/Vercel**: Revert via Vercel dashboard ("Instant Rollback") or revert the PR in Git.
- **Edge Functions**: Deploy previous version from GitHub Actions by re-running an older successful job, or revert the Git commit.
- **Database Migrations**: Destructive migrations require explicit recovery scripts. For non-destructive issues, apply a new hotfix migration forward. Avoid running destructive down-migrations in production manually unless strictly necessary.
- **Configuration / Secrets**: Revert environment variables manually via Supabase/Vercel dashboards.

---

## 7. Backup and Recovery

- **Database Backup Strategy**: Supabase performs automatic daily backups. Point-In-Time Recovery (PITR) is recommended and expected for the Production project.
- **Restore / Recovery Procedure**: In the event of data loss, infrastructure restores are managed via the Supabase dashboard (reverting to a PITR timestamp).
- **Responsibilities**: Supabase handles infrastructure-level backups. The application team is responsible for logical data fixes (e.g., recovering accidentally deleted user rows via custom SQL scripts).
- **Development/Staging vs Production**: Staging data is considered ephemeral. Production is strictly backed up.
- **RPO / RTO Targets** *(Proposed)*: 
  - Recovery Point Objective (RPO): 24 hours (default) or 1 minute (PITR enabled).
  - Recovery Time Objective (RTO): 4 hours.

---

## 8. Secret Handling

- **Rule**: NEVER commit API keys, service-role keys, or JWT tokens to source control.
- GitHub Actions Secrets (e.g. `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID`) are used exclusively in the CI pipelines.
- Edge Function runtime secrets (e.g., `GEMINI_API_KEY`) are stored in Supabase Vault via `supabase secrets set`.

---

## 9. Quick Reference

| Action | Command |
|--------|---------|
| Start new feature | `git checkout develop && git checkout -b feature/name` |
| Run analysis | `cd apps/mobile && flutter analyze` |
| Run tests | `cd apps/mobile && flutter test` |
| Validate migrations | `cd supabase && supabase db push --dry-run && supabase test db` |
| Validate functions | `cd supabase/functions && deno lint` |
| Push branch | `git push -u origin feature/name` |
| Switch to develop | `git checkout develop` |
| Backport hotfix | `git checkout develop && git merge main` |
