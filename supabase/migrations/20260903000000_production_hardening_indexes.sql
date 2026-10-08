-- Production Hardening: Composite & Foreign Key Indexes for High-Frequency Queries
-- Resolves query performance for mobile reports, dashboard overview, and RLS lookups

-- 1. Accelerates transaction range queries and pagination (WHERE business_id = ? ORDER BY date DESC)
CREATE INDEX IF NOT EXISTS idx_transactions_business_date 
  ON public.transactions(business_id, date DESC);

-- 2. Accelerates income/expense category and sum calculations (WHERE business_id = ? AND type = ?)
CREATE INDEX IF NOT EXISTS idx_transactions_business_type 
  ON public.transactions(business_id, type);

-- 3. Accelerates frequent RLS check (WHERE owner_id = auth.uid())
CREATE INDEX IF NOT EXISTS idx_businesses_owner_id 
  ON public.businesses(owner_id);

-- 4. Accelerates active category lookups for category dropdowns
CREATE INDEX IF NOT EXISTS idx_categories_business_active 
  ON public.categories(business_id, is_active);
