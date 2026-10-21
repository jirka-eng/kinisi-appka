# Kinisi Fyzioscanner – pokyny pro Claude Code

Webová appka pro kontrolu domácího cvičení: terapeut nahraje vzor cviku, pacient cvičí před kamerou telefonu
a appka mu hlasem říká, co dělá špatně. Detekce postavy běží v prohlížeči (MediaPipe), video pacienta neopouští telefon
(kromě volitelného záznamu se souhlasem).

Na projektu pracují Jirka (majitel repa, merguje) a kolegové z Kinisi. **S lidmi mluv česky, commity piš anglicky.**

## Kde co běží
- **Web:** GitHub Pages z větve `main` (root) → https://jirka-eng.github.io/kinisi-appka/ . Merge do `main` = nasazení.
- **Backend:** Supabase (EU), projekt `xpxapgwawwgxftawnqaw`, bezplatný plán (1 GB úložiště, projekt se po týdnu
  nečinnosti uspí). Veřejný klíč je v `kinisi-api.js`, data chrání Row Level Security.
- **Změny v databázi** jen jako nový soubor `supabase/migrations/NNN_nazev.sql`. Spouští ho Jirka v Supabase SQL editoru,
  ty ho do produkce sám nespouštěj.
- Railway se tohoto projektu netýká.

## Pravidla spolupráce
- Pracuj ve vlastní větvi a otevři **PR do `main`**. Merguje jen Jirka, sám nemerguj ani nepushuj do `main`.
- **Repo je veřejné** (kvůli bezplatnému GitHub Pages). Nedávej do něj nic citlivého: data pacientů, smlouvy, ceníky,
  hesla ani klíče. Podklady, které nejsou pro veřejnost, patří mimo repo (sdílený Disk).
- Velká videa do repa nepatří. Videa vzorů z knihovny jdou do Supabase úložiště `library`.

## Struktura
- `index.html` – appka pro pacienta i nahrávání vzoru (krok „1. Nahrát vzor“). Veškerá logika detekce je tady:
  `JOINTS` (hlídané klouby a hlášky), `computeAngles`, `buildReference` (vzor ze snímků), porovnání a počítání opakování.
- `terapeut.html` – přehled terapeuta: přihlášení e-mailem, pacienti, pozvánky (QR), sestavy cviků, výsledky.
- `kinisi-api.js` – napojení na Supabase (párování pacienta, ukládání cvičení, knihovna cviků).
- `refs/` – ručně vyladěné cviky v repu (`index.json` + jeden JSON na cvik), `media/` – jejich videa.
- `supabase/migrations/` – schéma databáze.
- `hlas/` – namluvené hlášky (Fyzioscanner hlas), viz `hlas/README.md`. Texty hlášek se řídí jazykovým manuálem Kinisi.
- `web/` – prodejní web Fyzioscanneru.
- `chodidla/` – scanner chodidla (druhá funkce): `oznacovani.html` je nástroj terapeutů na popis fotek nohou zezadu,
  plán a pravidla jsou v `chodidla/README.md`. Fotky chodidel a popisky jsou zdravotní data dětí, do repa nepatří.
- `vendor/`, `models/` – MediaPipe a model postavy (hostované lokálně, neměnit verze bez důvodu).
- `fyzio-kontrola-cviku.md` – původní zadání a popis detekce.

## Knihovna cviků
Appka spojuje dvě knihovny (`KinisiAPI.library()`):
1. **Repo** (`refs/index.json`): ručně vyladěné cviky se speciálními kontrolami (krk ve 3D, valgus kolen, hlasové texty).
2. **Server** (tabulka `exercises` + úložiště `library`, migrace `006_library.sql`): cviky zveřejněné z appky.
   Zapisovat smí jen e-maily v tabulce `library_editors` (přihlášení v `terapeut.html`), číst kdokoli.

Formát cviku (`ref`) je stejný v obou: `name`, `primary` (hlavní kloub), `start`/`far` (rozsah), `present` (hlídané klouby),
`frames` (úhly po snímcích, každý 2. snímek), `times`, `facing`, `refDesc`, `reps`, volitelně `settings`, `tips`, `video`.

## Hromadný import cviků (stovky videí)
- Vzor musí vzniknout **stejným výpočtem jako v appce** (`computeAngles` + `buildReference` v `index.html`).
  Logiku neopisuj do Pythonu, protože by se rozešla s appkou. Správná cesta je importní stránka v prohlížeči, která
  použije stejný kód (vytáhni ho do sdíleného modulu) a výsledky zveřejní přes `KinisiAPI.publishExercise`.
- Nejdřív **pilot na ~10 cvicích**, ať je ověří terapeut v appce, a teprve pak celá dávka.
- Ne každý cvik jde hlídat kamerou. Funguje to u pohybu celého těla s výrazným rozsahem v kloubu, kdy je vidět celá
  postava (ideálně z boku nebo šikmo zepředu). Cviky vleže, drobné pohyby nebo zakryté tělo `buildReference` odmítne
  nebo budou nespolehlivé. Takové cviky vypiš do seznamu s důvodem, nezveřejňuj je.
- **Úložiště:** bezplatný Supabase má na videa 1 GB. Před nahráním stovek videí spočítej velikost a domluv s Jirkou
  řešení (Supabase Pro nebo jiný hosting videí). Videa případně zmenši (např. 720p, krátký výřez 2–4 opakování).
- Id cviku: malá písmena, číslice a pomlčky (`^[a-z0-9-]{2,60}$`).

## Ověření změn
- Lokálně: `python3 -m http.server 8791` v kořeni repa a otevři `http://localhost:8791/`. Kamera vyžaduje https nebo localhost.
- U změn detekce vyzkoušej aspoň nahrané video vzoru (krok 1, „Nebo nahraj hotové video“) a cvičení proti němu.
