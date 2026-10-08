-- Create receipts bucket
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

-- RLS for storage.objects in 'receipts' bucket

-- 1. Insert Policy
create policy "Users can upload receipts to their business folder"
on storage.objects for insert
with check (
    bucket_id = 'receipts'
    and auth.uid() = (select owner_id from public.businesses where id::text = (string_to_array(name, '/'))[1])
);

-- 2. Select Policy
create policy "Users can view receipts for their business"
on storage.objects for select
using (
    bucket_id = 'receipts'
    and auth.uid() = (select owner_id from public.businesses where id::text = (string_to_array(name, '/'))[1])
);

-- 3. Delete Policy
create policy "Users can delete receipts for their business"
on storage.objects for delete
using (
    bucket_id = 'receipts'
    and auth.uid() = (select owner_id from public.businesses where id::text = (string_to_array(name, '/'))[1])
);
