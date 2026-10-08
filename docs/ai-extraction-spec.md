# AI Extraction Specification — Hesably

This document defines the architecture, contract, and operational rules for the Gemini API receipt/invoice extraction pipeline in Hesably. 

**Critical Rule:** AI output is *never* trusted as final business data. No transaction becomes confirmed until the user explicitly reviews and confirms it. The AI provides a *draft* extraction.

---

## 1. End-to-End Pipeline

The AI extraction follows a strict sequential pipeline crossing the mobile client, backend boundary, and Gemini API:

1. **Capture:** User captures an image (camera) or selects a photo (gallery) in the Flutter app.
2. **Compress & Upload:** The Flutter app compresses the image (e.g., `< 1MB`) and uploads it to a secure, private bucket in Supabase Storage or passes it directly to the Edge Function (depending on final implementation choice).
3. **Edge Function:** The Flutter app invokes a Supabase Edge Function securely (passing Auth context).
4. **Gemini Invocation:** The Edge Function attaches the server-side Gemini API key, constructs the multimodal prompt, and calls the Gemini API (`gemini-3.5-flash`).
5. **Server Validation:** The Edge Function parses the JSON response, validates it against a strict Zod schema, and scrubs hallucinated keys.
6. **Draft Extraction:** The Edge Function returns the validated JSON payload (the Draft Extraction) back to the Flutter app.
7. **Client Review:** The Flutter app populates the Review & Edit screen, highlighting low-confidence fields.
8. **User Confirmation:** The user edits incorrect values and taps "Save".
9. **Transaction:** A final `transactions` record is committed to the Supabase database.

---

## 2. Exact Structured JSON Contract

The Edge Function enforces structured JSON output using Gemini's JSON mode or function calling. The following contract is the exact schema returned to the client.

```json
{
  "is_receipt": true,
  "transaction_type": "expense",
  "date": "2026-08-27",
  "total_amount": 1450.50,
  "currency": "EGP",
  "vendor_customer_name": "Tech Hub Solutions",
  "suggested_category": "Office Supplies",
  "line_items": [
    {
      "description": "Wireless Keyboard",
      "quantity": 1,
      "unit_price": 800.00,
      "total_price": 800.00
    },
    {
      "description": "Mousepad",
      "quantity": 2,
      "unit_price": 325.25,
      "total_price": 650.50
    }
  ],
  "confidence_scores": {
    "overall": 0.95,
    "date": 0.98,
    "total_amount": 0.99,
    "vendor_customer_name": 0.85
  }
}
```

---

## 3. Field Types and Nullability

| Field | Type | Nullable | Description |
|---|---|---|---|
| `is_receipt` | `boolean` | No | `true` if the image is likely a receipt/invoice. `false` if it's a random image. |
| `transaction_type` | `string` | No | Must be `"income"` or `"expense"`. Defaults to `"expense"` if ambiguous. |
| `date` | `string` | Yes | ISO 8601 format `YYYY-MM-DD`. `null` if unreadable. |
| `total_amount` | `number` | Yes | Total value. Must be strictly positive. `null` if unreadable. |
| `currency` | `string` | Yes | ISO 4217 code (e.g., `EGP`, `USD`). |
| `vendor_customer_name` | `string` | Yes | The name of the shop, supplier, or customer. |
| `suggested_category` | `string` | Yes | A broad category suggestion (e.g., "Food", "Transport"). |
| `line_items` | `array` | Yes | List of extracted items. Can be an empty array `[]` or `null`. |
| `confidence_scores` | `object` | No | See section 4. |

*Note: Even required fields (like `date` and `total_amount` in the final DB schema) are nullable in the AI draft, because the user can manually fill them in if the AI fails.*

---

## 4. Confidence Score Format and Meaning

Confidence scores are floats between `0.0` and `1.0`. The UI uses these to flag fields requiring user attention.

- **`0.85 - 1.00` (High):** Display normally.
- **`0.50 - 0.84` (Medium):** Display with a subtle visual flag (e.g., yellow underline or icon) to encourage review.
- **`0.00 - 0.49` (Low):** Treat as highly suspect. Display with a strong visual warning or leave blank for the user to fill.

If a field is missing or `null`, its confidence is effectively `0.0`.

---

## 5. Validation Rules

The Edge Function must validate the following before returning to the client:
- **Date:** Must be a valid date in the past or present. Future dates should be clamped to today or rejected (set to `null`).
- **Totals:** `total_amount` must equal the sum of `line_items[].total_price` + taxes/fees (if the prompt calculates it). If there's a gross mismatch, flag `total_amount` confidence as Low.
- **Names:** Strip excessive whitespace and line breaks.
- **Transaction Type:** Strictly enum `'income' | 'expense'`.
- **Sanitization:** Strip dangerous HTML/SQL characters from text fields.

---

## 6. Language & Quality Handling

- **Arabic Receipts:** Gemini supports Arabic natively. The prompt must explicitly instruct the model to translate Arabic categories/items to the user's preferred language (or keep them in original Arabic, depending on UI state).
- **Mixed-Language:** Commonly receipts in Egypt have Arabic headers and English line items. The model handles this seamlessly.
- **Handwritten Receipts (Fawateer):** Frequently used in small businesses. Accuracy will be lower. The prompt must request the model to do its best, but confidence scores will naturally be lower.
- **Poor-Quality Images:** Blurry, torn, or crumpled receipts. If the model cannot extract a `total_amount` and `date`, it should flag `confidence_scores.overall < 0.5`.

---

## 7. Non-Receipt Detection

If the user uploads a selfie or a picture of a cat, Gemini should return:
```json
{
  "is_receipt": false,
  "transaction_type": "expense",
  "confidence_scores": { "overall": 0.0, "date": 0.0, "total_amount": 0.0, "vendor_customer_name": 0.0 }
}
```
*Client Behavior:* The UI immediately stops the flow and shows: "Couldn't read this as a receipt. Please try again or enter manually."

---

## 8. Partial Extraction

It is completely acceptable for the AI to extract only the Total Amount and fail on the Date or Vendor. 
The client UI must accept partial payloads. Missing fields are left blank in the form for the user to complete.

---

## 9. Timeout Behavior

- **Edge Function:** Configured with a 15-second timeout execution limit.
- **Client App:** Implements a 15-second timeout on the HTTP request.
- **Fallback:** If a timeout occurs, the UI falls back gracefully: "AI processing took too long. Please enter manually."

---

## 10. Retry Behavior

- **Transient Errors (5xx, Timeout, Network Drop):** The mobile app may automatically retry *once* if the request fails before reaching the 15s user-facing limit.
- **Validation Errors (4xx, Gemini Policy Block):** The app must *never* auto-retry. Fallback to manual entry immediately.

---

## 11. Duplicate Request / Idempotency

- The mobile app generates a unique `extraction_id` (UUID) for each capture event.
- If the app retries a network-dropped request, it sends the same `extraction_id`.
- The Edge Function can optionally use this to prevent double-processing and double-billing on the Gemini API.

---

## 12. Rate and Usage Protection

- **Auth Requirement:** The Edge Function verifies the Supabase Auth JWT. Unauthenticated requests are rejected (401).
- **Rate Limiting:** Implement a basic rate limit per `user_id` (e.g., max 20 extractions per minute, 500 per day) to prevent abuse from draining the Gemini API budget.

---

## 13. Prompt/Version Tracking Strategy

- Prompts are defined as code in the Edge Function repository.
- E.g., `const SYSTEM_PROMPT_V1 = "...";`
- When updating a prompt to fix edge cases, bump the version (e.g., `V2`).
- Include the prompt version in the Edge Function's telemetry/logs to track accuracy over time.

---

## 14. Raw Response Retention Policy

- The raw response and image path are stored in the `ai_extractions` table for debugging and evaluation.
- **Purge Rule:** A `pg_cron` job automatically hard-deletes records in `ai_extractions` older than 30 days to comply with data minimization and reduce storage costs.

---

## 15. Draft Extraction Lifecycle

1. **Created:** Returned to the client.
2. **Confirmed:** User taps "Save". Data goes into `transactions`.
3. **Rejected/Discarded:** User taps "Back" or explicitly clears the form. Data is lost. The AI draft state is deliberately stateless on the backend (except for the audit log in `ai_extractions`).

---

## 16. Observability and Diagnostics

- Log the request latency to the Gemini API.
- Log the prompt version used.
- Log failures (e.g., Gemini 503, safety filter blocks) to Supabase Edge Function logs.
- Do *not* log PII or raw base64 images to standard text logs; rely on the `ai_extractions` table and Storage bucket.

---

## 17. Security and Secret Handling

- The `GEMINI_API_KEY` is strictly managed via Supabase Secrets: `supabase secrets set GEMINI_API_KEY="AIza..."`.
- It is accessed in Deno via `Deno.env.get("GEMINI_API_KEY")`.
- It is never exposed in the Dart/Flutter code or Next.js client bundles.
- Images uploaded for extraction must use a private bucket where RLS policies restrict access only to the authenticated business owner.

---

## Test Scenarios & Known Limitations

### Test Scenarios
1. **Happy Path:** Clear, printed supermarket receipt in Arabic. Expect high confidence and all fields populated.
2. **Handwritten (Fatoora):** Scribbled Arabic on a generic invoice pad. Expect missing line items, lower confidence on vendor name.
3. **Non-Receipt:** Picture of a laptop keyboard. Expect `is_receipt: false`.
4. **Multi-page/Long Receipt:** A very long pharmacy receipt. Ensure context window limit handles the image appropriately (using `gemini-3.5-flash` handles this easily).
5. **Blurry Image:** Intentional motion blur. Expect partial data or `is_receipt: false`.
6. **Safety Filter Trigger:** An image containing a receipt next to something that triggers Gemini's safety filters. Ensure Edge Function handles the Gemini `FinishReason.SAFETY` block gracefully without crashing.

### Known Model Limitations
- **Handwriting Recognition:** While Gemini is excellent at OCR, highly stylized or messy cursive Arabic can result in hallucinated characters.
- **Date Formatting:** Dates written as `12/03` might be interpreted as Dec 3 or March 12. The prompt should instruct the model to assume local formats (Egypt uses DD/MM).
- **Latency Spikes:** Occasional cold starts or Gemini API congestion can cause 5-10s latency. The UI must accommodate this without freezing.
