# Hesably

A cross-platform mobile dashboard backed by Supabase, with a web dashboard planned.

## Project Structure

```
hesably/
├── apps/
│   └── mobile/
│       └── dashboard/    # Flutter mobile app (iOS + Android)
├── supabase/             # Supabase project (DB, auth, storage, edge functions)
└── docs/
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.x / Dart 3.x |
| Backend | Supabase (Postgres, Auth, Edge Functions, Storage) |
| Web | TBD |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x+
- [Dart SDK](https://dart.dev/get-dart) 3.x+
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- A [Supabase project](https://supabase.com) (cloud or local via `supabase start`)

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/mohamedelbalooty/hesably.git
cd hesably
```

### 2. Set up Supabase (local dev)

```bash
supabase start
supabase db push
```

### 3. Run the Flutter app

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Development Commands

```bash
# Flutter
flutter pub get          # install dependencies
flutter analyze          # static analysis
flutter test             # run tests
flutter run              # run on connected device

# Supabase
supabase start           # start local stack
supabase db push         # apply migrations
supabase functions serve # serve edge functions locally
supabase gen types typescript --local > lib/types/database.ts  # generate DB types
```

## Branching & Workflow

| Branch | Purpose |
|--------|---------|
| `main` | Production |
| `develop` | Integration / staging |
| `feature/*` | New features (branch off `develop`) |
| `fix/*` | Bug fixes (branch off `develop`) |
| `hotfix/*` | Urgent fixes (branch off `main`) |

**Flow:** `feature/*` → PR to `develop` → PR to `main`

CI runs automatically on PRs: `flutter analyze` → `flutter test` → Android/iOS builds. Supabase migrations are validated on PRs and deployed on merge to `develop` (staging) or `main` (production).

## Contributing

1. Branch off `develop` for new work.
2. Run `flutter analyze` before committing.
3. Use RLS for all access control — prefer RLS over app-level auth checks.
4. Structure features in layers: UI → Logic → Data.
5. Open a PR using the provided template.

## License

TBD
