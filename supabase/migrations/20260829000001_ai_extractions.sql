CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE TABLE IF NOT EXISTS public.ai_extractions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    receipt_image_path text NOT NULL,
    raw_response jsonb NOT NULL,
    status text NOT NULL CHECK (status IN ('processing', 'success', 'failure')),
    created_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ai_extractions_business_id ON public.ai_extractions(business_id);
CREATE INDEX IF NOT EXISTS idx_ai_extractions_created_at ON public.ai_extractions(created_at);

ALTER TABLE public.ai_extractions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own ai extractions"
    ON public.ai_extractions
    FOR INSERT
    WITH CHECK (business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can view their own ai extractions"
    ON public.ai_extractions
    FOR SELECT
    USING (business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    ));

-- Create a daily cron job to delete extractions older than 30 days
SELECT cron.schedule(
    'purge-old-ai-extractions',
    '0 0 * * *', -- Every day at midnight
    $$ DELETE FROM public.ai_extractions WHERE created_at < NOW() - INTERVAL '30 days' $$
);
