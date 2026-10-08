begin;

select plan(5);

-- Setup: create test users
insert into auth.users (id, instance_id, aud, role, email) 
values 
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'user1@test.com'),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'user2@test.com');

-- Switch to authenticated role
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);

-- Test 1: User 1 can insert their own business
select lives_ok(
    $$ insert into public.businesses (owner_id, name, type) values ('00000000-0000-0000-0000-000000000001', 'User 1 Business', 'Retail') $$,
    'User 1 can insert their own business'
);

-- Test 2: User 1 tries to create another business for user1 (should fail unique constraint)
select throws_ok(
    $$ insert into public.businesses (owner_id, name, type) values ('00000000-0000-0000-0000-000000000001', 'User 1 Business 2', 'Retail') $$,
    '23505',
    NULL,
    'User 1 cannot create a second business'
);

-- Test 3: User 1 tries to create business for user2 (should fail RLS)
select throws_ok(
    $$ insert into public.businesses (owner_id, name, type) values ('00000000-0000-0000-0000-000000000002', 'User 2 Business', 'Retail') $$,
    '42501',
    'new row violates row-level security policy for table "businesses"',
    'User 1 cannot insert a business for User 2'
);

-- Test 4: User 1 can update their own business
select lives_ok(
    $$ update public.businesses set name = 'User 1 Updated' where owner_id = '00000000-0000-0000-0000-000000000001' $$,
    'User 1 can update their own business'
);

-- Switch to User 2
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-000000000002", "role": "authenticated"}', true);

-- Test 5: User 2 tries to read user1's business
select is_empty(
    $$ select * from public.businesses where owner_id = '00000000-0000-0000-0000-000000000001' $$,
    'User 2 cannot view User 1s business'
);

select * from finish();

rollback;
