# Database Design

## Enums
### `transaction_type`
- `income`
- `expense`

## Tables

### 1. `businesses`
- **Purpose**: Represents the tenant (the single business owned by the user in the MVP).
- **Columns & Types**:
  - `id` (uuid, default gen_random_uuid())
  - `owner_id` (uuid)
  - `name` (text)
  - `business_type` (text)
  - `currency` (text, default 'EGP')
  - `created_at` (timestamptz, default now())
  - `updated_at` (timestamptz, default now())
- **Required/Nullability**: All fields NOT NULL except `business_type`.
- **Primary Key**: `id`
- **Foreign Keys**: `owner_id` references `auth.users(id)` ON DELETE CASCADE
- **Unique Constraints**: `owner_id` (enforces MVP 1-business-per-user rule)
- **Check Constraints**: `char_length(currency) > 0`
- **Indexes**: `idx_businesses_owner_id` on `owner_id`
- **Timestamps**: `created_at`, `updated_at` (maintained via trigger)
- **Deletion Behavior**: Deleting a user in Auth cascades to this table. Deleting a business cascades to all child data.
- **Ownership Key**: `owner_id`
- **Audit Considerations**: Basic `updated_at` tracking for profile changes.

### 2. `categories`
- **Purpose**: Lookup table for transaction classifications.
- **Columns & Types**:
  - `id` (uuid, default gen_random_uuid())
  - `business_id` (uuid)
  - `name` (text)
  - `is_default` (boolean, default false)
  - `is_hidden` (boolean, default false)
  - `created_at` (timestamptz, default now())
- **Required/Nullability**: All fields NOT NULL.
- **Primary Key**: `id`
- **Foreign Keys**: `business_id` references `businesses(id)` ON DELETE CASCADE
- **Unique Constraints**: Unique (`business_id`, `name`) to prevent duplicate categories within a business.
- **Check Constraints**: `char_length(name) > 0`
- **Indexes**: `idx_categories_business_id` on `business_id`
- **Timestamps**: `created_at`
- **Deletion Behavior**: Custom categories are hard-deleted. Default categories are protected by RLS and can only be marked `is_hidden`.
- **Ownership Key**: `business_id`
- **Audit Considerations**: None required for MVP.

### 3. `transactions`
- **Purpose**: The core financial ledger entry.
- **Columns & Types**:
  - `id` (uuid, default gen_random_uuid())
  - `business_id` (uuid)
  - `type` (transaction_type)
  - `amount` (numeric)
  - `date` (date)
  - `category_id` (uuid)
  - `vendor_customer_name` (text, nullable)
  - `receipt_image_path` (text, nullable)
  - `created_at` (timestamptz, default now())
  - `updated_at` (timestamptz, default now())
- **Required/Nullability**: `id`, `business_id`, `type`, `amount`, `date`, `category_id`, `created_at`, `updated_at` NOT NULL.
- **Primary Key**: `id`
- **Foreign Keys**: 
  - `business_id` references `businesses(id)` ON DELETE CASCADE
  - `category_id` references `categories(id)` ON DELETE RESTRICT (prevents deleting a category that is in use)
- **Unique Constraints**: None.
- **Check Constraints**: `amount > 0`
- **Indexes**: 
  - `idx_transactions_business_id` on `business_id`
  - `idx_transactions_date` on `date`
  - `idx_transactions_category_id` on `category_id`
- **Timestamps**: `created_at`, `updated_at`
- **Deletion Behavior**: Hard-deleted by owner. Deletion should eventually trigger cleanup of the unreferenced `receipt_image_path` in Storage.
- **Ownership Key**: `business_id`
- **Audit Considerations**: Log `updated_at` on modification.

### 4. `ai_extractions`
- **Purpose**: Transient log of Gemini Vision API extraction drafts for debugging and metrics.
- **Columns & Types**:
  - `id` (uuid, default gen_random_uuid())
  - `business_id` (uuid)
  - `receipt_image_path` (text)
  - `raw_response` (jsonb)
  - `status` (text)
  - `created_at` (timestamptz, default now())
- **Required/Nullability**: All fields NOT NULL.
- **Primary Key**: `id`
- **Foreign Keys**: `business_id` references `businesses(id)` ON DELETE CASCADE
- **Unique Constraints**: None.
- **Check Constraints**: `status` IN ('processing', 'success', 'failure')
- **Indexes**: 
  - `idx_ai_extractions_business_id` on `business_id`
  - `idx_ai_extractions_created_at` on `created_at`
- **Timestamps**: `created_at`
- **Deletion Behavior**: Automatically purged after a set timeframe (e.g., 30 days) via `pg_cron`.
- **Ownership Key**: `business_id`
- **Audit Considerations**: Used purely for system auditing of AI accuracy.

## Migration Order Proposal
1. `001_create_enums.sql` (transaction_type)
2. `002_create_businesses.sql`
3. `003_create_categories.sql`
4. `004_create_transactions.sql`
5. `005_create_ai_extractions.sql`
6. `006_setup_rls.sql`
7. `007_storage_buckets_and_policies.sql`

## Schema Decisions Requiring Approval
1. **Category Seeding**: Should default categories be seeded into the `categories` table upon business creation via a Postgres function/trigger, or maintained globally with `business_id = NULL`? *(Proposal: Seed directly into each business to vastly simplify RLS and foreign key logic).*
2. **Category Deletion Constraint**: The foreign key `ON DELETE RESTRICT` ensures a category cannot be deleted if transactions use it. This forces the UI to provide a "reassign transactions" step before allowing custom category deletion. Are we okay with this strictness for MVP?
