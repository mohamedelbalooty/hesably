-- Sprint 5 RPCs

-- 1. Account Deletion RPC
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete the user from auth.users. 
  -- The ON DELETE CASCADE on public.businesses.owner_id will handle removing all user data.
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- 2. Financial Summary RPC
CREATE OR REPLACE FUNCTION public.get_financial_summary(p_business_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS TABLE (
  total_income NUMERIC,
  total_expense NUMERIC,
  net NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Security check: user must own the business
  IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND owner_id = auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN QUERY
  WITH sums AS (
    SELECT 
      COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as income,
      COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as expense
    FROM public.transactions
    WHERE business_id = p_business_id
      AND date >= p_start_date
      AND date <= p_end_date
  )
  SELECT 
    income as total_income, 
    expense as total_expense, 
    (income - expense) as net
  FROM sums;
END;
$$;

-- 3. Category Breakdown RPC
CREATE OR REPLACE FUNCTION public.get_category_breakdown(p_business_id UUID, p_start_date DATE, p_end_date DATE, p_type public.transaction_type)
RETURNS TABLE (
  category_id UUID,
  category_name TEXT,
  total_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Security check: user must own the business
  IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND owner_id = auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN QUERY
  SELECT 
    t.category_id,
    c.name as category_name,
    SUM(t.amount) as total_amount
  FROM public.transactions t
  JOIN public.categories c ON t.category_id = c.id
  WHERE t.business_id = p_business_id
    AND t.type = p_type
    AND t.date >= p_start_date
    AND t.date <= p_end_date
  GROUP BY t.category_id, c.name
  ORDER BY total_amount DESC;
END;
$$;
