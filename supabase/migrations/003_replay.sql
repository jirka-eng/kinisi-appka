-- Záznam pohybu pro přehrání terapeutem: jen body kostry, obrys zad a chyby v čase (žádné video).
-- {"fps":10,"w":720,"h":1280,"idx":[7,11,...],"f":[[x,y,...],...],"b":[[x,y,...]|null,...],"e":[["lumbar"],...],"m":[[s,"text"],...]}
-- Přístup řeší stávající pravidla tabulky sessions (pacient zapisuje svoje, terapeut čte svých pacientů).
alter table public.sessions add column replay jsonb;
