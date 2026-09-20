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

-- Row Level Security: this app is a small private group reached only by
-- sharing the link, and it manages its own email/password login inside
-- the page (not Supabase Auth). To keep that working, the public "anon"
-- key needs read/write on these tables directly. That is the same trust
-- model as a shared spreadsheet: anyone with your Supabase URL + anon
-- key (both sit in your published HTML, visible to anyone who views the
-- page source) can read or write the ledger. Fine for a trusted group of
-- 8; if that ever stops being fine, move the writes behind Supabase Auth
-- + stricter policies, or a small server function.

alter table ikimina_config   enable row level security;
alter table ikimina_people     enable row level security;
alter table ikimina_accounts   enable row level security;
alter table ikimina_savings    enable row level security;
alter table ikimina_loans      enable row level security;
alter table ikimina_repayments enable row level security;
alter table ikimina_payouts    enable row level security;
alter table ikimina_fees       enable row level security;
alter table ikimina_events     enable row level security;

do $$
declare t text;
begin
  for t in select unnest(array[
    'ikimina_config','ikimina_people','ikimina_accounts','ikimina_savings',
    'ikimina_loans','ikimina_repayments','ikimina_payouts','ikimina_fees','ikimina_events'
  ])
  loop
    execute format('drop policy if exists "anon full access" on %I;', t);
    execute format(
      'create policy "anon full access" on %I for all using (true) with check (true);', t
    );
  end loop;
end $$;

-- Turn on realtime (live updates across every open tab/device) for each table.
alter publication supabase_realtime add table
  ikimina_config, ikimina_people, ikimina_accounts, ikimina_savings,
  ikimina_loans, ikimina_repayments, ikimina_payouts, ikimina_fees, ikimina_events;
