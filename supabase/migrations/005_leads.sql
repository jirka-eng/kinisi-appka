-- Zájemci z prodejního webu (web/index.html). Kdokoli může zapsat, číst může jen správce v Supabase.
create table public.leads (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) between 1 and 120),
  email text not null check (length(email) between 3 and 200 and email like '%@%'),
  role text not null check (role in ('pacient','terapeut','klinika')),
  source text default 'web' check (length(source) <= 40),
  created_at timestamptz not null default now()
);
alter table public.leads enable row level security;
revoke all on public.leads from anon, authenticated;
grant insert on public.leads to anon, authenticated;
create policy "anyone can sign up" on public.leads for insert to anon, authenticated with check (true);
