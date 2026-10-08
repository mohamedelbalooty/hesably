alter table public.businesses enable row level security;

-- SELECT Policy
create policy "Users can view their own business."
on public.businesses for select
to authenticated
using (owner_id = auth.uid());

-- INSERT Policy
create policy "Users can insert their own business."
on public.businesses for insert
to authenticated
with check (owner_id = auth.uid());

-- UPDATE Policy
create policy "Users can update their own business."
on public.businesses for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());
