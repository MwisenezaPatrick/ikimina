-- Ikimina Savings & Loan — Supabase schema
-- Run this once in your Supabase project's SQL editor (SQL Editor -> New query -> paste -> Run).

create table if not exists ikimina_config (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_people (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_accounts (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_messages (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_savings (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_loans (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_repayments (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_payouts (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_fees (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists ikimina_events (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- The ledger retains its existing anon access model. Member accounts are
-- read-only to the browser, while messages and receipt files require a
-- Supabase Auth session whose email is in the account allowlist.

alter table ikimina_config   enable row level security;
alter table ikimina_people     enable row level security;
alter table ikimina_accounts   enable row level security;
alter table ikimina_savings    enable row level security;
alter table ikimina_loans      enable row level security;
alter table ikimina_repayments enable row level security;
alter table ikimina_payouts    enable row level security;
alter table ikimina_fees       enable row level security;
alter table ikimina_events     enable row level security;
alter table ikimina_messages   enable row level security;

do $$
declare t text;
begin
  drop policy if exists "anon full access" on ikimina_accounts;
  drop policy if exists "anon full access" on ikimina_messages;
  for t in select unnest(array[
    'ikimina_config','ikimina_people','ikimina_savings',
    'ikimina_loans','ikimina_repayments','ikimina_payouts','ikimina_fees','ikimina_events'
  ])
  loop
    execute format('drop policy if exists "anon full access" on %I;', t);
    execute format(
      'create policy "anon full access" on %I for all using (true) with check (true);', t
    );
  end loop;
end $$;

grant select, insert, update, delete on
  ikimina_config, ikimina_people, ikimina_savings, ikimina_loans,
  ikimina_repayments, ikimina_payouts, ikimina_fees, ikimina_events
to anon, authenticated;

-- Remove any legacy client-side password hashes before exposing allowlisted
-- email addresses for login discovery.
update ikimina_accounts
set data = data - 'passHash', updated_at = now()
where data ? 'passHash';

create unique index if not exists ikimina_accounts_email_unique
  on ikimina_accounts (lower(data->>'email'))
  where coalesce(data->>'email', '') <> '';

create or replace function public.ikimina_is_group_member()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.ikimina_accounts a
    where lower(a.data->>'email') = lower(auth.jwt()->>'email')
  );
$$;

revoke all on function public.ikimina_is_group_member() from public, anon;
grant execute on function public.ikimina_is_group_member() to authenticated;

drop policy if exists "anon can check member email" on ikimina_accounts;
create policy "anon can check member email" on ikimina_accounts
  for select to anon using (true);
drop policy if exists "members can read allowlist" on ikimina_accounts;
create policy "members can read allowlist" on ikimina_accounts
  for select to authenticated using (public.ikimina_is_group_member());
revoke insert, update, delete on ikimina_accounts from anon, authenticated;
grant select on ikimina_accounts to anon, authenticated;

-- Supabase Auth signup is permitted only for an address an officer has
-- previously added to ikimina_accounts.
create or replace function public.ikimina_authorize_signup()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not exists (
    select 1
    from public.ikimina_accounts a
    where lower(a.data->>'email') = lower(new.email)
  ) then
    raise exception 'This email is not authorized for the Ikimina group';
  end if;
  return new;
end;
$$;

drop trigger if exists ikimina_authorize_signup on auth.users;
create trigger ikimina_authorize_signup
  before insert on auth.users
  for each row execute function public.ikimina_authorize_signup();

-- Keep the allowlist and member contact record synchronized after an
-- authenticated user confirms an email change.
create or replace function public.ikimina_sync_auth_email()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare account_record record;
begin
  if new.email is distinct from old.email then
    for account_record in
      update public.ikimina_accounts
      set data = jsonb_set(data - 'passHash', '{email}', to_jsonb(new.email), true),
          updated_at = now()
      where lower(data->>'email') = lower(old.email)
      returning data->>'personId' as person_id
    loop
      update public.ikimina_people
      set data = jsonb_set(data, '{email}', to_jsonb(new.email), true),
          updated_at = now()
      where id = account_record.person_id;
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists ikimina_sync_auth_email on auth.users;
create trigger ikimina_sync_auth_email
  after update of email on auth.users
  for each row execute function public.ikimina_sync_auth_email();

drop policy if exists "members can read messages" on ikimina_messages;
create policy "members can read messages" on ikimina_messages
  for select to authenticated using (public.ikimina_is_group_member());
drop policy if exists "members can send own messages" on ikimina_messages;
create policy "members can send own messages" on ikimina_messages
  for insert to authenticated with check (
    public.ikimina_is_group_member()
    and data->>'senderAuthId' = auth.uid()::text
    and lower(data->>'senderEmail') = lower(auth.jwt()->>'email')
  );
revoke all on ikimina_messages from anon;
grant select, insert on ikimina_messages to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'ikimina-message-files', 'ikimina-message-files', false, 10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']
)
on conflict (id) do update set
  public = false, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "group members can view message files" on storage.objects;
create policy "group members can view message files" on storage.objects
  for select to authenticated using (
    bucket_id = 'ikimina-message-files'
    and public.ikimina_is_group_member()
  );
drop policy if exists "members can upload own message files" on storage.objects;
create policy "members can upload own message files" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'ikimina-message-files'
    and public.ikimina_is_group_member()
    and (storage.foldername(name))[1] = auth.uid()::text
  );
drop policy if exists "members can delete own message files" on storage.objects;
create policy "members can delete own message files" on storage.objects
  for delete to authenticated using (
    bucket_id = 'ikimina-message-files'
    and public.ikimina_is_group_member()
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Add each public table once so this section remains safe to rerun.
do $$
declare t text;
begin
  for t in select unnest(array[
    'ikimina_config','ikimina_people','ikimina_accounts','ikimina_savings',
    'ikimina_loans','ikimina_repayments','ikimina_payouts','ikimina_fees',
    'ikimina_events','ikimina_messages'
  ])
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
