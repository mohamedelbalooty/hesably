-- 1. Create Enums
CREATE TYPE public.transaction_type AS ENUM ('income', 'expense');

-- 2. Create Categories Table
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(name) > 0),
    is_default BOOLEAN NOT NULL DEFAULT false,
    is_hidden BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(business_id, name)
);

CREATE INDEX idx_categories_business_id ON public.categories(business_id);

-- 3. Create Transactions Table
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    type public.transaction_type NOT NULL,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    date DATE NOT NULL,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    vendor_customer_name TEXT,
    receipt_image_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX idx_transactions_business_id ON public.transactions(business_id);
CREATE INDEX idx_transactions_date ON public.transactions(date);
CREATE INDEX idx_transactions_category_id ON public.transactions(category_id);

-- Trigger for transactions updated_at
CREATE TRIGGER handle_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- 4. Enable RLS and create policies
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Categories RLS
CREATE POLICY "Users can view their own business categories" 
ON public.categories FOR SELECT 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can insert categories to their business" 
ON public.categories FOR INSERT 
WITH CHECK (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can update their own business categories" 
ON public.categories FOR UPDATE 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can delete their own custom categories" 
ON public.categories FOR DELETE 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
  AND is_default = false
);

-- Transactions RLS
CREATE POLICY "Users can view their own business transactions" 
ON public.transactions FOR SELECT 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can insert transactions to their business" 
ON public.transactions FOR INSERT 
WITH CHECK (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can update their own business transactions" 
ON public.transactions FOR UPDATE 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can delete their own business transactions" 
ON public.transactions FOR DELETE 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);

-- 5. Trigger to seed default categories
CREATE OR REPLACE FUNCTION public.handle_new_business()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert default income categories
  INSERT INTO public.categories (business_id, name, is_default)
  VALUES 
    (NEW.id, 'Sales', true),
    (NEW.id, 'Services', true),
    (NEW.id, 'Other Income', true);
    
  -- Insert default expense categories
  INSERT INTO public.categories (business_id, name, is_default)
  VALUES 
    (NEW.id, 'Supplies', true),
    (NEW.id, 'Rent', true),
    (NEW.id, 'Utilities', true),
    (NEW.id, 'Maintenance', true),
    (NEW.id, 'Transportation', true),
    (NEW.id, 'Marketing', true),
    (NEW.id, 'Other Expense', true);
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind trigger to businesses table
CREATE TRIGGER on_business_created
  AFTER INSERT ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_business();
