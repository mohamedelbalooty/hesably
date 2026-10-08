-- Security Fixes Migration
-- Resolves VULN-001 (Transaction Reassignment) and VULN-002 (Category Tampering)

-- 1. Fix Transactions UPDATE policy by adding WITH CHECK clause
DROP POLICY IF EXISTS "Users can update their own business transactions" ON public.transactions;

CREATE POLICY "Users can update their own business transactions" 
ON public.transactions FOR UPDATE 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
)
WITH CHECK (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

-- 2. Fix Categories INSERT policy to prevent forging system default categories
DROP POLICY IF EXISTS "Users can insert categories to their business" ON public.categories;

CREATE POLICY "Users can insert categories to their business" 
ON public.categories FOR INSERT 
WITH CHECK (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
  AND is_default = false
);

-- 3. Fix Categories UPDATE policy by adding WITH CHECK clause
DROP POLICY IF EXISTS "Users can update their own business categories" ON public.categories;

CREATE POLICY "Users can update their own business categories" 
ON public.categories FOR UPDATE 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
)
WITH CHECK (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

-- 4. Add Category Integrity Trigger
-- Prevents escalating custom categories to is_default = true and prevents altering default category names/business_id
CREATE OR REPLACE FUNCTION public.check_category_integrity()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent changing is_default flag on any existing category
  IF NEW.is_default IS DISTINCT FROM OLD.is_default THEN
    RAISE EXCEPTION 'Cannot modify is_default status of a category';
  END IF;

  -- For default categories, prevent changing name or transferring business_id (only is_hidden can be changed)
  IF OLD.is_default = true THEN
    IF NEW.name IS DISTINCT FROM OLD.name THEN
      RAISE EXCEPTION 'Cannot rename default categories';
    END IF;
    IF NEW.business_id IS DISTINCT FROM OLD.business_id THEN
      RAISE EXCEPTION 'Cannot reassign default category business_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_category_integrity ON public.categories;

CREATE TRIGGER trg_check_category_integrity
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.check_category_integrity();
