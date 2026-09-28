-- Kinisi: terapeuti, pacienti a záznamy cvičení.
-- Terapeut = přihlášený uživatel (ne anonymní). Pacient = anonymní uživatel spárovaný pozvánkou.
-- Kdo co vidí, hlídá Row Level Security přímo v databázi. Video se nikdy neukládá, jen čísla.

create extension if not exists pgcrypto with schema extensions;

-- ---------- pomocné funkce ----------
create or replace function public.is_therapist() returns boolean
language sql stable as $$
  select auth.uid() is not null and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
$$;

-- ---------- pacienti ----------
create table public.patients (
  id uuid primary key default gen_random_uuid(),
  therapist_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (length(name) between 1 and 120),
  user_id uuid unique references auth.users(id) on delete set null,   -- telefon pacienta (anonymní účet)
  invite_code text unique,
  invite_expires timestamptz,
  created_at timestamptz not null default now()
);
create index on public.patients (therapist_id);

-- ---------- cvičení ----------
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  client_id bigint not null,                -- id záznamu v telefonu (kvůli opakovanému odeslání)
  exercise text not null,
  primary_joint text,
  started_at timestamptz not null,
  duration_s integer,
  reps integer not null default 0,
  incomplete integer not null default 0,
  good integer not null default 0,
  score integer,
  best_range integer,
  errors jsonb not null default '{}'::jsonb,
  pain smallint check (pain between 0 and 10),
  effort smallint check (effort between 0 and 2),
  created_at timestamptz not null default now(),
  unique (patient_id, client_id)
);
create index on public.sessions (patient_id, started_at);

-- ---------- přístupová práva ----------
alter table public.patients enable row level security;
alter table public.sessions enable row level security;
revoke all on public.patients, public.sessions from anon, authenticated;
grant select, insert, update, delete on public.patients to authenticated;
grant select, insert, update, delete on public.sessions to authenticated;

-- Terapeut: jen svoji pacienti
create policy "therapist manages own patients" on public.patients
  for all to authenticated
  using (public.is_therapist() and therapist_id = auth.uid())
  with check (public.is_therapist() and therapist_id = auth.uid());
-- Pacient: vidí jen svůj záznam (kvůli jménu)
create policy "patient reads self" on public.patients
  for select to authenticated
  using (user_id = auth.uid());

-- Terapeut: čte a maže cvičení svých pacientů
create policy "therapist reads sessions" on public.sessions
  for select to authenticated
  using (public.is_therapist() and exists (select 1 from public.patients p where p.id = patient_id and p.therapist_id = auth.uid()));
create policy "therapist deletes sessions" on public.sessions
  for delete to authenticated
  using (public.is_therapist() and exists (select 1 from public.patients p where p.id = patient_id and p.therapist_id = auth.uid()));
-- Pacient: zapisuje a čte jen svoje cvičení
create policy "patient reads own sessions" on public.sessions
  for select to authenticated
  using (exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid()));
create policy "patient inserts own sessions" on public.sessions
  for insert to authenticated
  with check (exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid()));
create policy "patient updates own sessions" on public.sessions
  for update to authenticated
  using (exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid()))
  with check (exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid()));

-- ---------- pozvánky ----------
-- Terapeut vytvoří jednorázový kód platný 14 dní (starý tím zneplatní).
create or replace function public.create_invite(p_patient uuid) returns text
language plpgsql security definer set search_path = public, extensions as $$
declare c text;
begin
  if not public.is_therapist() then raise exception 'not allowed'; end if;
  c := encode(extensions.gen_random_bytes(9), 'hex');
  update public.patients set invite_code = c, invite_expires = now() + interval '14 days'
   where id = p_patient and therapist_id = auth.uid();
  if not found then raise exception 'patient not found'; end if;
  return c;
end $$;

-- Telefon pacienta (přihlášený anonymně) kód uplatní a tím se spáruje.
create or replace function public.claim_invite(p_code text) returns table (patient_id uuid, patient_name text)
language plpgsql security definer set search_path = public as $$
declare p public.patients;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into p from public.patients
   where invite_code = p_code and invite_expires > now()
   for update;
  if not found then raise exception 'invalid invite'; end if;
  update public.patients set user_id = null where user_id = auth.uid() and id <> p.id;  -- telefon patří jen jednomu pacientovi
  update public.patients set user_id = auth.uid(), invite_code = null, invite_expires = null where id = p.id;
  return query select p.id, p.name;
end $$;

revoke all on function public.create_invite(uuid) from public, anon;
revoke all on function public.claim_invite(text) from public, anon;
grant execute on function public.create_invite(uuid) to authenticated;
grant execute on function public.claim_invite(text) to authenticated;
grant execute on function public.is_therapist() to authenticated;

-- Živé obnovení přehledu terapeuta, když pacient docvičí (RLS platí i tady)
alter publication supabase_realtime add table public.sessions;
