# Adversarial RLS & Security Threat Review

This document contains an adversarial security review of the proposed Hesably database architecture, RLS matrix, and data lifecycle. The goal is to identify concrete authorization failures and provide the minimum required fixes.

## 1. The `WITH CHECK` Definition Flaw (Complete Data Compromise)
- **Vulnerability**: The `rls-matrix.md` conceptualized "Denied Conditions" mapped to PostgreSQL's `WITH CHECK` clause using inverted logic (e.g., `business_id NOT IN (...)`).
- **Attack Scenario**: If a developer translates the matrix literally into SQL: `CREATE POLICY ... WITH CHECK (business_id NOT IN (SELECT id FROM businesses WHERE owner_id = auth.uid()))`, the policy physically allows a user to write data to **every business except their own**.
- **Minimum Fix**: Remove the "Denied Condition" mental model. Postgres `WITH CHECK` strictly defines the **Allowed** state. All INSERT and UPDATE policies must explicitly use: `WITH CHECK (business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid()))`.

## 2. Transaction Reassignment via UPDATE `USING` vs `WITH CHECK` Gap
- **Vulnerability**: An UPDATE requires both `USING` (can I see this row to update it?) and `WITH CHECK` (am I allowed to save the new state?).
- **Attack Scenario**: If an RLS policy only defines `USING` for UPDATE, an attacker can modify a transaction they own and change the `business_id` to a victim's UUID. The `USING` check passes (because the old row belongs to the attacker), and without a `WITH CHECK`, the row is successfully transferred to the victim's ledger.
- **Minimum Fix**: Ensure all UPDATE policies explicitly include `WITH CHECK (business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid()))` to prevent transferring records across tenant boundaries.

## 3. Edge Function Privilege Escalation (Forged `business_id`)
- **Vulnerability**: The Gemini integration relies on Supabase Edge Functions. If the Edge Function uses the Service Role key to bypass RLS (e.g., to log `ai_extractions`) and blindly trusts a `business_id` provided in the client's JSON payload.
- **Attack Scenario**: A malicious authenticated user sends a payload to the Edge Function with `business_id: <victim_uuid>`. The Edge Function, running as Admin, associates the extraction or receipt with the victim's business, polluting their ledger or overwriting their data.
- **Minimum Fix**: The Edge Function MUST instantiate the Supabase client using the user's Auth JWT (forwarding the `Authorization` header) so that RLS applies natively to Edge Function DB calls. If the Service Role MUST be used, the function must explicitly query `businesses` to verify `owner_id = auth.uid()` before acting on the `business_id`.

## 4. Default Category Tampering
- **Vulnerability**: The matrix specifies that default categories cannot be modified or deleted. 
- **Attack Scenario**: An attacker updates one of their *custom* categories (passing the `USING` clause) and sets `is_default = true`. Because the old row had `is_default = false`, the update succeeds. The attacker has now escalated their custom category into a system default, potentially causing UI crashes or bypassing future deletion rules.
- **Minimum Fix**: The `UPDATE` policy on `categories` must include `WITH CHECK (is_default = false)` to prevent users from escalating custom categories into system status. (Additionally, the UI must never send `is_default` in update payloads).

## 5. Storage Directory Traversal / Path Spoofing
- **Vulnerability**: The Storage RLS policy relies on `(storage.foldername(name))[1]` matching the user's `business_id`.
- **Attack Scenario**: An attacker attempts to upload a file using directory traversal characters (e.g., `victim-uuid/../attacker-uuid/receipt.jpg`) via a raw API request. If the storage policy evaluation misinterprets the path, they could write to or overwrite files in another tenant's bucket.
- **Minimum Fix**: Supabase storage normalizes paths, mitigating basic traversal, but the RLS `WITH CHECK` on INSERT must strictly enforce that the target folder exactly matches the user's resolved `business_id` without relying purely on client-provided paths.

## 6. Dashboard Session Persistence After Identity Unlinking
- **Vulnerability**: The dashboard uses Email Magic Links via Supabase Identity Linking.
- **Attack Scenario**: 
  1. A business owner links an email (e.g., an accountant's email) via the mobile app.
  2. The accountant logs into the web dashboard, receiving a valid JWT tied to the owner's `auth.uid()`.
  3. The owner unlinks the email via the mobile app.
  4. **The accountant's existing JWT remains valid** until it expires (up to 1 hour). They can continue to read/write transactions maliciously.
- **Minimum Fix**: Supabase Identity unlinking does not automatically kill active sessions for that identity. The application must either accept the 1-hour risk window as a documented business limitation, OR implement a `security_revocations` table checked via RLS or custom claims to explicitly block requests from unlinked identities.

## 7. `business_id` Enumeration via Foreign Key Errors
- **Vulnerability**: When inserting a transaction, the user must provide a `business_id`.
- **Attack Scenario**: If an attacker attempts to insert a row with `business_id = <target_uuid>`, they want to know if `<target_uuid>` exists. Depending on Postgres constraint evaluation order, a Foreign Key error might fire *before* RLS denies the row, returning an error that confirms the existence of the victim's business.
- **Minimum Fix**: Supabase RLS policies are evaluated before `INSERT` constraints, preventing this leakage. However, developers must ensure no custom Postgres functions defined as `SECURITY DEFINER` inadvertently leak existence via error messages when called directly via RPC.

## Summary Conclusion
The foundational decision to key all data by `business_id` is sound, but the literal translation of the proposed RLS rules contained critical logical flaws (e.g., inverted `WITH CHECK` logic, missing UPDATE checks). The Edge Function boundaries and Identity Linking lifecycle pose the highest realistic threat and require careful implementation to prevent cross-tenant compromise.
