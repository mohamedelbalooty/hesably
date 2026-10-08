# Product Contract — Hesably

This document serves as the normalized, cross-platform product contract for Hesably. It aligns the mobile app, dashboard, backend, and AI extraction workflows into a single source of truth for semantics, rules, and boundaries.

## 1. Terminology Dictionary
- **Business:** A commercial entity managed by the User. Maps to a tenant in the system.
- **Transaction:** A single financial event (income or expense) logged by the business.
- **Draft Extraction:** Unverified data returned from the Gemini API that has not yet been confirmed by the user.
- **Category:** A classification for a transaction (e.g., Rent, Sales). Can be default (system-provided) or custom (user-created).
- **Sale / Purchase:** UI-specific terminology representing money received and money spent. Maps directly to the backend concepts of `income` and `expense`.
- **OTP:** One-Time Password sent via SMS for mobile authentication.
- **Magic Link:** An emailed login link used for web dashboard authentication.
- **Web Access Linking:** The process of attaching an email address to a mobile-created (phone) account to authorize web dashboard login.

## 2. Screen/Route Inventory (Mobile)
- **Splash Screen (`/splash`)**: Initial app load, session verification.
- **Phone Entry (`/auth/phone`)**: Input phone number to request OTP.
- **OTP Verification (`/auth/otp`)**: Input 6-digit SMS code.
- **Business Setup (`/onboarding/business`)**: One-time profile creation (Name, Type, Currency).
- **Home Dashboard (`/home`)**: High-level metrics, floating action button for new transactions.
- **Transaction Type Selector (`/transaction/type`)**: Choose Sale (Income) or Purchase (Expense).
- **Capture Screen (`/transaction/capture`)**: Camera / Gallery / Skip to manual options.
- **Processing State (`/transaction/processing`)**: Loading state during Edge Function AI extraction.
- **Review & Edit (`/transaction/edit`)**: Pre-filled form with AI draft data (or blank for manual). Flags low-confidence fields.
- **Transaction List (`/transactions`)**: Chronological list of transactions with search and filters.
- **Transaction Detail (`/transaction/:id`)**: Read-only view with receipt image, edit, and delete actions.
- **Reports (`/reports`)**: Summary cards, period selector, category breakdown, export functionality.
- **Settings (`/settings`)**: Profile editing, category management, enable web access, language toggle, logout.

## 3. Screen/Route Inventory (Dashboard)
- **Login (`/login`)**: Email input for Magic Link.
- **Dashboard Home (`/`)**: Summary cards, charts, and recent transaction list.
- **Transactions (`/transactions`)**: Comprehensive data table with sorting, filtering, and search.
- **Transaction Detail/Edit (`/transactions/:id`)**: Side panel/modal showing read-only details, image viewer, and inline edit/delete.
- **Reports (`/reports`)**: Period selector, detailed charts, direct PDF/Excel export.
- **Categories (`/categories`)**: Table of default and custom categories with usage counts and management controls.
- **Settings (`/settings`)**: Business profile, Web Access status, logout.

## 4. Shared Business Concepts
- **Data Isolation:** A user belongs to one business in the MVP. All application data is isolated at the business level, not the user level.
- **Categories:** Categories belong to a business (custom) or are global (default). Default categories can be hidden but never deleted. Custom categories can be fully managed.
- **Localization:** Arabic (RTL) is the primary required experience across both platforms.

## 5. Transaction Semantics
- **Database Type (`transactions.type`):** Strictly constrained to `income` or `expense`.
- **UI Mappings:**
  - "Sale" / "Income" (UI) → `type = 'income'` (DB)
  - "Purchase" / "Expense" (UI) → `type = 'expense'` (DB)
- **Document Distinctions:** If the UI requires further distinction for e-receipt vs. e-invoice features in the future, it must be handled via a `document_type` column or reserved categories, NOT by modifying the core `transactions.type` enum.

## 6. Required Fields and Validation Behavior
- **Business Profile:** Name (required), Type (required), Currency (defaults to EGP).
- **Transaction:** Type (required), Amount (required, > 0), Date (required), Category (required). Vendor/Customer name is optional. Receipt Image is required if captured, optional if entered manually.
- **Custom Category:** Name (required, unique per business).

## 7. Status/Lifecycle Values
- **AI Extraction Pipeline:** `processing` → `success` | `failure` (handled client-side, fallback to manual entry on failure).
- **Transaction Draft:** Held purely in client state or a transient logging table during the Review & Edit phase.
- **Committed Transaction:** Written to the `transactions` table. No soft-delete or draft status exists in the ledger for the MVP.

## 8. User/Business Ownership Rules
- The mobile app is the definitive source of account creation.
- The `businesses` table holds an `owner_id` mapping to the Supabase Auth UUID.
- All transactional and categorizational data is strictly keyed by `business_id`.
- RLS policies authorize read/write access only where the Auth UUID matches the `businesses.owner_id`.
- Dashboard users cannot create businesses; they must access existing ones.

## 9. Authentication/Account-Linking Flow
1. User registers/logs in via Phone OTP on the mobile app.
2. Supabase Auth generates User UUID (Phone Identity).
3. User navigates to Settings → Enable Web Access.
4. User enters their email address.
5. App triggers `supabase.auth.linkIdentity({ email })`.
6. User attempts dashboard login using this email.
7. Supabase Magic Link authenticates the user successfully under the exact same User UUID.
8. Unlinked emails attempting to log in will be blocked via UI (or routed to an "Access Denied - Go to Mobile App" empty state).

## 10. AI Draft vs. Confirmed Transaction Lifecycle
1. User captures physical receipt.
2. App invokes Supabase Edge Function to process image via Gemini Vision API.
3. Gemini returns a structured JSON Draft Extraction with confidence heuristics.
4. Client application surfaces the Draft on the Review & Edit screen, visually flagging low-confidence values.
5. **Trust Boundary:** The user must explicitly correct and tap "Save".
6. The Confirmed Transaction is committed to the database ledger. The unverified draft is discarded (or securely logged for analytics only).

## 11. Error-State Behavior
- **Network Offline (Mobile):** AI capture is explicitly blocked. Prompt: "Internet connection required for AI processing. Please connect or enter manually."
- **AI Extraction Failure (Blurry/Non-receipt):** Soft failure. Direct the user to the manual entry form with a notification: "Couldn't read this as a receipt, try again or enter manually." Do not force correction of garbage data.
- **OTP / Magic Link Failure:** Present a clear error and offer a "Resend" button after a standard cooldown.
- **Empty Datasets:** Views with no data must show actionable empty states (e.g., "Add your first transaction from the mobile app") rather than blank screens.

## 12. MVP Exclusions
The following features are rigorously excluded from Phase 1 (MVP):
- Double-entry bookkeeping ledgers.
- Direct ETA e-invoice / e-receipt API submission.
- Multi-user / employee roles.
- Multi-branch support.
- Offline queueing and syncing of transactions.
- Web-based receipt capture and AI extraction.
- Independent dashboard self-signup flows.

## 13. Cross-Platform Consistency Rules
- **Filters and Sorting:** Must be identical between mobile and dashboard (chronological by default).
- **Transaction Editing:** Editing a transaction on the web executes the exact same state updates as editing on mobile.
- **Category Hiding:** Hiding a default category on the dashboard hides it on mobile, and vice versa.
- **Destructive Actions:** Deleting a transaction requires an explicit confirmation dialog on both platforms.

---

## Contradictions Resolved by Documented Decision
1. **Sale/Purchase UI vs Backend Schema:** Resolved by strictly mapping UI labels to the database enum (`income`/`expense`).
2. **Offline Mode Scope:** Resolved by actively blocking offline AI capture in MVP to dramatically simplify state management, deferring background sync to Phase 2.
3. **Dashboard Authentication Strategy:** Resolved by enforcing Supabase Identity Linking from the mobile app, preventing fragmented accounts and honoring the mobile-first creation rule.
4. **Data Isolation (One Business per User):** Resolved by enforcing the `business_id` as the primary key on tenant tables instead of relying solely on `user_id`, guaranteeing a zero-migration path to Phase 2 multi-business support.

## Remaining Open Decisions
- **AI Model Selection:** Which Gemini 1.5 model (Flash vs. Pro) offers the correct balance of latency, cost, and accuracy for Arabic receipt OCR in production? (Recommendation: Flash for speed, falling back to Pro if evaluation fails).
- **Magic Link "New User" Handling:** Because Supabase Magic Links inherently sign up new users if the email doesn't exist, the dashboard must catch users who bypass mobile onboarding. **Decision Needed:** Should we handle this via a database trigger that rejects the auth request, or a frontend route guard that displays a "No Business Profile Found - Please use the mobile app" screen?

## Product-Contract Approval Checklist
- [ ] UI terminology mapping approved.
- [ ] Authentication linking flow approved.
- [ ] AI data boundary rules approved.
- [ ] MVP exclusions verified.
- [ ] Cross-platform parity rules accepted.
