-- Sestava od terapeuta: co, kolikrát a jak často má pacient cvičit.
-- program = {"items":[{"ref":"drep","name":"Dřep","reps":10,"sets":2,"rest":30,"freq":{"times":1,"per":"day"},"precision":{"tol":15,"depth":true,"tempo":true}}]}
-- Upravovat ho smí jen terapeut (stávající pravidlo "therapist manages own patients"), pacient ho jen čte ("patient reads self").
alter table public.patients add column program jsonb not null default '{"items":[]}'::jsonb;

alter table public.sessions add column ref_id text;
alter table public.sessions add column target_reps integer;
alter table public.sessions add column target_sets integer;
