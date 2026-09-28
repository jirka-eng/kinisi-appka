-- Videozáznam cvičení (s vyznačenou kostrou a chybami). Nahrává se jen se souhlasem pacienta.
-- Soukromé úložiště "replays", cesta: <patient_id>/<client_id>.<mp4|webm>
alter table public.sessions add column video_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('replays', 'replays', false, 52428800, array['video/mp4', 'video/webm'])
on conflict (id) do nothing;

-- Pacient (telefon) nahrává a čte jen do složky svého pacienta
create policy "patient writes own replays" on storage.objects for insert to authenticated
  with check (bucket_id = 'replays' and (storage.foldername(name))[1] in (select id::text from public.patients where user_id = auth.uid()));
create policy "patient updates own replays" on storage.objects for update to authenticated
  using (bucket_id = 'replays' and (storage.foldername(name))[1] in (select id::text from public.patients where user_id = auth.uid()));
create policy "patient reads own replays" on storage.objects for select to authenticated
  using (bucket_id = 'replays' and (storage.foldername(name))[1] in (select id::text from public.patients where user_id = auth.uid()));
-- Terapeut čte a maže záznamy jen svých pacientů
create policy "therapist reads replays" on storage.objects for select to authenticated
  using (bucket_id = 'replays' and public.is_therapist() and (storage.foldername(name))[1] in (select id::text from public.patients where therapist_id = auth.uid()));
create policy "therapist deletes replays" on storage.objects for delete to authenticated
  using (bucket_id = 'replays' and public.is_therapist() and (storage.foldername(name))[1] in (select id::text from public.patients where therapist_id = auth.uid()));
