-- Sdílená knihovna cviků: vzor nahraný v aplikaci jde zveřejnit a hned ho vidí všichni (pacienti i terapeuti).
-- Cviky v repu (refs/index.json) zůstávají, aplikace obě knihovny spojí.
-- Číst smí kdokoli, zapisovat jen schválení editoři (tabulka library_editors, plní se ručně v Supabase).

create table public.library_editors (
  email text primary key check (email = lower(email))
);
alter table public.library_editors enable row level security;
revoke all on public.library_editors from anon, authenticated;

create or replace function public.is_library_editor() returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_therapist() and exists (select 1 from public.library_editors where email = lower(auth.jwt() ->> 'email'))
$$;
revoke all on function public.is_library_editor() from public, anon;
grant execute on function public.is_library_editor() to authenticated;

-- ref = celý vzor jako v refs/*.json (úhly po snímcích, klouby, nastavení přesnosti); video = cesta v úložišti "library"
create table public.exercises (
  id text primary key check (id ~ '^[a-z0-9-]{2,60}$'),
  name text not null check (length(name) between 1 and 120),
  description text check (length(description) <= 500),
  ref jsonb not null,
  video_path text,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.exercises enable row level security;
revoke all on public.exercises from anon, authenticated;
grant select on public.exercises to anon, authenticated;
grant insert, update, delete on public.exercises to authenticated;

create policy "anyone reads library" on public.exercises for select to anon, authenticated using (true);
create policy "editors insert" on public.exercises for insert to authenticated with check (public.is_library_editor());
create policy "editors update" on public.exercises for update to authenticated using (public.is_library_editor()) with check (public.is_library_editor());
create policy "editors delete" on public.exercises for delete to authenticated using (public.is_library_editor());

-- Videa vzorů: veřejně čitelná (ukázka vedle pacienta), zapisují jen editoři
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('library', 'library', true, 52428800, array['video/mp4', 'video/webm', 'video/quicktime'])
on conflict (id) do nothing;

create policy "editors write library videos" on storage.objects for insert to authenticated
  with check (bucket_id = 'library' and public.is_library_editor());
create policy "editors update library videos" on storage.objects for update to authenticated
  using (bucket_id = 'library' and public.is_library_editor());
create policy "editors delete library videos" on storage.objects for delete to authenticated
  using (bucket_id = 'library' and public.is_library_editor());

-- Editoři (další přidáte stejným řádkem s jejich přihlašovacím e-mailem)
insert into public.library_editors (email) values ('jirka@naboso.cz') on conflict do nothing;
