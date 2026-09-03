# Architecture — Hesably

This document outlines the technical architecture for the Hesably MVP, covering the Flutter mobile app, Next.js web dashboard, Supabase backend, and Gemini AI integration.

## 1. Monorepo Architecture

The project is structured as a monorepo to ensure configuration, documentation, and backend schemas are versioned alongside client applications.

```
/hesably
  ├── apps/
  │   ├── mobile/         # Flutter application (iOS/Android)
  │   └── dashboard/      # Next.js application (Web)
  ├── supabase/           # Migrations, Edge Functions, local config
  └── docs/               # Project documentation
```

## 2. Flutter Architecture (apps/mobile/)

The mobile app follows a **Clean Architecture** layered approach to ensure business logic is testable and independent of the UI or backend implementation.

- **Presentation**: Contains UI widgets, routing, and state providers. Widgets are strictly responsible for rendering state and dispatching user actions.
- **Domain**: Contains business entities (e.g., `Transaction`, `Business`), repository interfaces, and use cases. This layer has zero dependencies on Flutter UI or Supabase SDKs.
- **Data**: Implements domain interfaces. Houses the Supabase client integrations, Data Transfer Objects (DTOs), and local mapping logic. **flutter_secure_storage** is used for caching and secure local storage of sensitive data (like user preferences or tokens, if needed).
- **Core / Shared**: Contains dependency injection, logging, theming, and constants.
- **State Management**: **Bloc/Cubit** is the recommended state management solution. It enforces a strict, predictable unidirectional data flow and cleanly separates presentation from business logic.
- **Routing Strategy**: **go_router** for declarative, path-based navigation and routing. This handles authentication redirects seamlessly (e.g., booting unauthenticated users to `/auth/phone`).
- **Localization**: **easy_localization** is used to easily enable and manage `ar` (Arabic, default RTL) and `en` (English) languages via JSON translation files.
- **Networking**: Official `supabase_flutter` SDK for Auth, Database, and Storage. 
- **Serialization**: `json_serializable` and `freezed` for immutable domain models and strictly typed JSON parsing.
- **Error/Result Handling**: Use Dart 3 sealed classes or a package like `fpdart` (Either types) to return explicit `Success` or `Failure` states from the Data layer, avoiding untyped try-catch blocks in the UI.

## 3. Next.js Architecture (apps/dashboard/)

The web dashboard is built as a companion app for larger-screen data management.

- **App Router**: Uses Next.js 14+ App Router (`/app`) for modern server-side rendering and routing.
- **Server/Client Boundaries**: 
  - Default to **React Server Components (RSCs)** for fetching and rendering data tables and reports to minimize client bundle size.
  - Use **Client Components** (`"use client"`) only for interactive elements (e.g., edit forms, charts, Magic Link auth form).
- **Data Fetching and Caching**: Use `@supabase/ssr` to fetch data securely in Server Components. For client-side interactivity (like optimistic updates during edits), use **TanStack Query**.
- **Authentication**: `@supabase/ssr` manages cookie-based sessions, allowing Next.js to verify the Magic Link token securely on both the server and the client.
- **Route Protection**: A Next.js Middleware (`middleware.ts`) intercepts requests to protected routes (`/transactions`, `/reports`) and redirects unauthenticated users to `/login`.
- **UI Architecture**: Tailwind CSS for layout and styling, combined with **shadcn/ui** for accessible, unstyled core components. **Tremor** is utilized for rendering financial charts (bar/donut) in the Reports tab.

## 4. Supabase Architecture

Supabase acts as the unified backend (BaaS) for both platforms.

- **Auth**: Configured with a Phone provider (e.g., Twilio) for mobile OTP and an Email provider for web Magic Links. Identity linking must be explicitly enabled.
- **Postgres Database**: The single source of truth. Enforces referential integrity (e.g., a `Transaction` must point to a valid `Category` and `Business`). 
- **Row Level Security (RLS)**: The primary security boundary. Every business-owned table must have an RLS policy ensuring the current user's Auth UUID matches the `owner_id` of the referenced `businesses` row.
- **Storage**: A `private` bucket for receipt images. RLS policies on `storage.objects` ensure only the business owner can upload, view, or delete their receipt images.
- **Edge Functions**: Deno-based serverless functions used specifically for secure integrations (like the Gemini API) that cannot be exposed to the client.

## 5. Gemini Integration Boundary

To protect API credentials and enforce data validation, Gemini is integrated via a server-side proxy.

- **Workflow**:
  1. **Client**: Captures receipt image, compresses it, and sends it to the Edge Function.
  2. **Edge Function**: Attaches the secure Gemini API Key, constructs the multimodal prompt, and calls the Gemini Vision API.
  3. **Validation**: The Edge Function validates the Gemini JSON response against the expected schema (using Zod or similar).
  4. **Draft Phase**: The validated JSON is returned to the client. It is *not* written to the `transactions` table.
  5. **Review & Confirm**: The client displays the draft. The user corrects it and taps "Save", which directly inserts the Confirmed Transaction into Postgres.
- **Secret Handling**: The Gemini API key is stored strictly in Supabase Secrets (`supabase secrets set`) and accessed via `Deno.env.get()`.
- **Timeout/Retry Limits**: Edge Functions have strict execution timeouts (typically 5-15 seconds depending on the plan). The mobile client should implement a timeout of 15 seconds. If a network transient error occurs, 1 automatic retry is permitted, but 4xx validation errors must not be retried.
- **Idempotency**: The client generates a UUID for the extraction request. The Edge function checks if this request is currently being processed to prevent duplicate API costs on network drops.

## 6. Shared Contracts and Type Generation

- **Supabase CLI**: Used to generate TypeScript definitions (`supabase gen types typescript`) which are imported into the Next.js app to ensure type-safe database queries.
- **Dart Mapping**: Since native Dart type generation from Supabase is limited, the database schema contract is manually mapped to Freezed models in Flutter, guided by the TS definitions.
- **AI Contract**: The expected JSON output from Gemini must be strictly defined in a JSON Schema or Zod schema within the Edge Function to prevent hallucinated keys from crashing the mobile client.

## 7. Environment Strategy

- **Local**: Developers use `supabase start` for a local Postgres instance, Auth, and Storage. Both Flutter and Next.js connect to `localhost:54321`.
- **Staging**: A dedicated Supabase staging project. The `develop` branch deploys here. Used for QA and integration testing.
- **Production**: The live Supabase project. The `main` branch deploys here.
- Vercel environments directly map to these branches for dashboard deployments.

## 8. Observability Boundaries

- **Mobile (Flutter)**: Firebase Crashlytics for fatal/non-fatal crash reporting and unhandled exception logging.
- **Web (Next.js)**: Vercel Analytics and standard error boundaries.
- **Backend**: Supabase Edge Function logs and Postgres `pg_stat_statements` for query performance monitoring.

## 9. Performance Considerations (Low-end Android)

- **Image Compression**: Raw camera images can exceed 10MB. The Flutter app MUST compress images locally (e.g., using `flutter_image_compress`) to < 1MB before uploading to the Edge Function to ensure fast transmission and avoid OOM (Out of Memory) crashes on low-end devices.
- **UI Rendering**: Avoid complex opacity animations and heavy blurs. Rely on standard Material 3 transitions.
- **Pagination**: The `/transactions` endpoint must implement cursor-based or offset pagination to prevent excessive memory consumption when the ledger grows.

## 10. Scalability Considerations (MVP Boundaries)

- **Do not over-engineer**: We are strictly using Supabase as a BaaS. No custom microservices, no separate GraphQL layers, and no complex event-sourcing.
- **Database Indexing**: Add B-tree indexes to foreign keys (`business_id`, `category_id`) and frequently filtered columns (`date`, `type`) in the initial migration.
- **Simple RLS**: Keep RLS policies performant by avoiding deep `JOIN`s in the policy logic. A direct lookup of the active `business_id` is preferred.

---

## Architecture Decisions

1. **Supabase as Unified Backend**: Handled Auth, DB, and Storage. No custom Node.js/Python backend for MVP.
2. **Edge Functions for AI**: Gemini integration isolated in a Deno Edge Function to protect secrets and validate schema.
3. **Flutter Clean Architecture + Bloc/Cubit**: Enforces strict unidirectional data flow, separation of concerns, and testability.
4. **Next.js App Router + RSCs**: Optimized for speed and minimal client bundle size for the dashboard.
5. **Client-side Compression**: Images compressed on mobile *before* network transmission.

## Rejected Alternatives

- **Firebase**: Rejected in favor of Supabase due to the strict relational requirements of accounting ledgers (transactions, categories, businesses) which are poorly suited to NoSQL documents.
- **Direct Gemini Client Integration**: Rejected due to the critical security risk of embedding API keys in a compiled mobile app.
- **Next.js API Routes for AI Proxy**: Rejected because routing mobile AI requests through the dashboard's Vercel backend introduces unnecessary latency and a secondary backend dependency. Edge Functions keep backend logic centralized in Supabase.

## Known Risks

- **Edge Function Cold Starts / Timeouts**: Gemini Vision API calls can occasionally take > 10 seconds. Supabase Edge Functions on lower tiers may timeout. We must monitor latency and handle timeouts gracefully in the UI.
- **Identity Linking Edge Cases**: Supabase Identity Linking (Phone + Email) requires careful frontend handling. If a user creates an account on Web first (which MVP aims to prevent), it could create an orphaned email user.
- **Arabic OCR Quality**: Gemini's performance on handwritten or low-quality Arabic receipts in the wild must be validated; failure rates could increase manual entry frequency.

## Open Decisions

- **Image Storage Strategy**: Should the compressed image sent to the Edge Function be saved to the Storage bucket *by the Edge Function*, or should the client upload the image directly to Storage and just pass the URL to the Edge Function? (Client upload via signed URL/RLS is generally faster and avoids hitting Edge Function payload limits).
- **Exact Schema for AI Output**: The precise JSON keys and structures for the Gemini extraction need to be finalized in `docs/ai-extraction-spec.md`.

## Implementation Prerequisites

1. Initialize Monorepo structure (`apps/mobile`, `apps/dashboard`, `supabase/`).
2. Create baseline Supabase migrations (Tables, FKs, RLS).
3. Setup `supabase init` and `.env` local environments.
4. Establish CI/CD pipelines (GitHub Actions) for Flutter linting and Supabase migration validation.
5. Create `docs/ai-extraction-spec.md` to finalize the AI JSON contract.

---

**STATUS: GO FOR IMPLEMENTATION PREPARATION**
