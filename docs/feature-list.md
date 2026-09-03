# Feature List — Smart Invoice Assistant

**Project**: AI-powered receipt/invoice capture and bookkeeping app for small shop owners (Egypt market)
**Stack**: Flutter (frontend), Supabase (auth/database/storage), Gemini API (AI extraction)
**Target user**: Solo shop owner / small business owner with no dedicated accountant, mobile-first, manages the business mostly from their phone.

---

## Phase 1 — MVP (build first, in this order)

### 1. Authentication
- Phone number sign-up/login with OTP verification (Supabase Phone Auth + SMS provider).
- No email/password option in MVP — phone-only, to minimize friction for non-tech-savvy users.
- On first login: short onboarding — business name, business type (retail / restaurant / pharmacy / service / other), default currency (EGP).
- Session persistence (stay logged in between app opens).

### 2. Receipt Capture
- In-app camera capture (primary) + option to pick an existing photo from gallery.
- Basic image quality check before upload (blurry/too-dark warning, optional retake prompt).
- Support capturing both **sales receipts issued to customers** and **purchase invoices from suppliers** — user picks a type before/after capture (maps to Egypt's e-receipt vs e-invoice distinction later).

### 3. AI Data Extraction
- Send captured image to Gemini Vision API.
- Extract structured fields: date, total amount, vendor/customer name (if present), line items (if legible), suggested category.
- Return a confidence indicator per field (even a simple heuristic) so low-confidence fields are visually flagged for review.
- Handle extraction failure gracefully (blurry image, non-receipt image, handwritten receipt) — fall back to manual entry form, not a hard error.

### 4. Review & Edit Screen
- Show extracted fields pre-filled in an editable form.
- User must confirm/save before it's written to the database — no silent auto-save of unverified AI data.
- Ability to attach/keep the original photo linked to the record for later reference.
- Quick manual-entry path (skip AI entirely) for cases where a receipt isn't available (e.g., cash sale with no printed receipt).

### 5. Categories
- Predefined default categories relevant to small Egyptian retail/service businesses (e.g., Purchases/Stock, Rent, Salaries, Utilities, Transport, Sales, Other).
- AI suggests a category automatically; user can override.
- Ability to add custom categories.

### 6. Transaction List & Management
- Chronological list of all recorded transactions (income/expense), with thumbnail of receipt image.
- Filter by: date range, category, type (income/expense), amount range.
- Search by vendor/customer name.
- Edit or delete any past entry.
- Detail view per transaction showing all fields + original image.

### 7. Dashboard & Reports
- Home screen summary: total income, total expenses, net for current month (large, glanceable numbers).
- Breakdown by category (simple bar or list, not necessarily a fancy chart in MVP).
- Month-over-month comparison (e.g., "+15% expenses vs last month").
- Date range selector (this week / this month / custom range).

### 8. Export
- Export a report for a selected period as PDF (simple, shareable with an accountant).
- Export as Excel/CSV for users who want raw data.

### 9. Settings & Profile
- Edit business name/type.
- Manage categories (add/edit/delete custom ones).
- Language: Arabic (RTL) as primary/default UI language. English as secondary if time allows.
- Logout / delete account.

---

## Phase 2 — Post-MVP (after validating with real users)

- **Egyptian e-invoice / e-receipt system integration**: map recorded transactions to the format required by the Egyptian Tax Authority (ETA) e-invoice system (B2B) and e-receipt system (B2C); explore direct submission or at minimum export in ETA-compatible format.
- Multi-user access per business (e.g., owner + one employee, with restricted permissions).
- Recurring transaction templates (e.g., monthly rent auto-suggested).
- Low-stock / reorder suggestions based on purchase patterns (ties into inventory forecasting idea explored earlier).
- Push notifications: reminders to log daily sales, monthly report ready, unusual spending alert.
- Basic offline mode: capture receipts offline, sync + AI-process when back online.

## Phase 3 — Future / Vision

- WhatsApp-based receipt submission (forward a photo to a business number, get it auto-logged).
- Multi-branch support for businesses with more than one location.
- Simple loan/credit tracking (money owed to/by the business).
- AI-generated plain-language monthly business summary ("this month your rent went up but sales also grew, here's what that means").

---

## Non-Functional Requirements

- **Primary language**: Arabic, right-to-left (RTL) layout throughout.
- **Performance**: AI extraction result should return within a few seconds; show a clear loading state during processing, never a frozen screen.
- **Security**: Row Level Security in Supabase so each business owner can only ever query their own data. Receipt images stored in a private (non-public) storage bucket.
- **Data trust**: AI-extracted data is never saved without user confirmation (see Feature 4).
- **Low-end device friendly**: target users may have mid/low-spec Android phones — keep the app lightweight, avoid heavy animations that hurt performance.

## Explicitly Out of Scope for MVP

- Full accounting/double-entry bookkeeping.
- Payroll management.
- Multi-currency support.
- Direct government tax filing/submission (Phase 2 at earliest, and only after legal/compliance review).
