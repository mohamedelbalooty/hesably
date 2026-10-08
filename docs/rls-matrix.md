# Row Level Security (RLS) Matrix

**Philosophy**: All database tables are strictly isolated by tenant (`business_id`). Clients only ever have the `authenticated` role. Service-role is never assumed for client interactions, and we do not trust client-side ownership checks.

## Actor: `authenticated` (Business Owner)

| Table | Operation | Allowed Condition (USING) | Denied Condition (WITH CHECK) |
|---|---|---|---|
| `businesses` | SELECT | `owner_id = auth.uid()` | N/A |
| `businesses` | INSERT | N/A (Often handled by Edge Function or allowed if `owner_id = auth.uid()`) | `owner_id != auth.uid()` |
| `businesses` | UPDATE | `owner_id = auth.uid()` | `owner_id != auth.uid()` |
| `businesses` | DELETE | `owner_id = auth.uid()` | N/A |
| `categories` | SELECT | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` | N/A |
| `categories` | INSERT | N/A | `business_id NOT IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` |
| `categories` | UPDATE | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` | `is_default = true` (Prevents users from renaming system defaults) |
| `categories` | DELETE | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` AND `is_default = false` | N/A |
| `transactions` | SELECT | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` | N/A |
| `transactions` | INSERT | N/A | `business_id NOT IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` |
| `transactions` | UPDATE | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` | `business_id NOT IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` |
| `transactions` | DELETE | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` | N/A |
| `ai_extractions` | SELECT | `business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` | N/A |
| `ai_extractions` | INSERT | N/A | `business_id NOT IN (SELECT id FROM businesses WHERE owner_id = auth.uid())` |
| `ai_extractions` | UPDATE | Denied entirely for clients (insert/update only from edge functions) | N/A |
| `ai_extractions` | DELETE | Denied entirely for clients (system purged) | N/A |

## Private Receipt Storage Behavior

- **Bucket**: `receipts` (Strictly Private bucket in Supabase Storage).
- **Object Path Convention**: `{business_id}/{uuid}.jpg` (Ensures folder-level tenant isolation).
- **Access Model**: RLS enabled on the `storage.objects` table.
  - **SELECT**: `bucket_id = 'receipts' AND (storage.foldername(name))[1] IN (SELECT id::text FROM businesses WHERE owner_id = auth.uid())`
  - **INSERT**: Same condition as SELECT.
  - **DELETE**: Same condition as SELECT.
- **Signed URL Strategy**: 
  - Since the bucket is private, raw URLs are inaccessible.
  - Clients must use `supabase.storage.from('receipts').createSignedUrl(path, 3600)` (or similar short-lived TTL) to securely render images in the UI.
- **Deletion Semantics**: 
  - Objects can be explicitly deleted by the user via the client if they delete a transaction (handled in the application layer).
  - Unlinked objects (e.g., abandoned AI drafts that were never saved) will be cleaned up by a backend lifecycle routine.
