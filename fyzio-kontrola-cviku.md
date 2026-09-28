# Kontrola domácího cvičení (fyzioterapie) - zadání pro Claude Code

## Cíl
Fyzioterapeut natočí vzor cviku (jak se dělá správně). Pacient pak doma cvičí před kamerou telefonu a aplikace mu živě hlasem i na obrazovce říká, co dělá špatně ("Víc pokrč kolena", "Zvedni paže výš", "Zpomal"...). Vše běží v prohlížeči, video neopouští zařízení.

## Aktuální stav
- Funkční prototyp: jeden soubor `fyzio-kontrola-cviku.html` (přetáhni ho do projektu spolu s tímto MD).
- V souboru je zabudovaný vzor "Dřep (vzor z videa)" spočítaný z terapeutova videa (`IMG_4828.mov`, 47 s, na výšku, natočeno z boku, cvičící čelem doleva).
- Logika ověřená offline simulací v Pythonu (MediaPipe) - všech 6 simulovaných chyb zachyceno, u správného opakování žádný falešný pokyn.
- **Blokátor:** živá kamera zatím neotestovaná. Náhled v aplikaci Claude kameru nepustí, publikovaný claude.ai odkaz blokuje stažení modelu (CSP). Stránka musí běžet z vlastního https hostingu.

## Technologie
- MediaPipe Tasks Vision `@mediapipe/tasks-vision@0.10.14` z `cdn.jsdelivr.net` (ES modul + wasm).
- Model: `pose_landmarker_full.task` z `storage.googleapis.com/mediapipe-models/...` (full kvůli shodě s referencí; lite je rychlejší, zvážit na slabších telefonech).
- `runningMode: "VIDEO"`, GPU delegate s fallbackem na CPU.
- Hlas: `speechSynthesis`, `lang: "cs-CZ"`. Na iOS musí první `speak()` proběhnout přímo v handleru kliknutí (už je).
- Uložení vlastního vzoru: `localStorage` klíč `fyzio-ref-v2`.
- Font Onest (Google Fonts), barvy jako CSS tokeny, light/dark.

## Jak funguje detekce
1. **Úhly kloubů** (2D, v pixelech videa, 33 landmarků MediaPipe):
   - koleno: kyčel-koleno-kotník (23-25-27)
   - kyčel: rameno-kyčel-koleno (11-23-25)
   - rameno: kyčel-rameno-loket (23-11-13)
   - loket: rameno-loket-zápěstí (11-13-15)
   - trup: úhel spojnice kyčel -> rameno od svislice
2. **Strana těla:** z boku je vidět jen jedna strana. Každý snímek se vybere strana (L/R) s vyšší průměrnou visibility a klouby se počítají jen z ní. Díky tomu je jedno, kam je pacient otočený.
3. **Vyhlazení:** EMA 0.5 na úhlech, landmark se bere jen při visibility >= 0.5.
4. **Vzor:** z nahraných snímků se určí sledované klouby (vidět v >= 70 % snímků), hlavní kloub = největší rozsah (u dřepu kyčel, 171° -> 46°), start/far = výchozí a krajní poloha, a uloží se každý 2. snímek jako vektor úhlů (368 snímků).
5. **Porovnání (robustní nejbližší snímek):** pro živý snímek se najde snímek vzoru s nejmenším součtem odchylek, **bez 2 nejhorších kloubů** (při >= 4 viditelných). Chybný kloub tak neovlivní určení fáze pohybu a vyskočí jako odchylka.
6. **Chyba:** odchylka nad toleranci (posuvník 8-30°, výchozí 15°) trvající >= 400 ms. Hlásí se nejhorší kloub; aktuálně hlášený kloub se drží, dokud je chybný (proti míhání pokynů).
7. **Opakování** podle hlavního kloubu: odchod ze startu (n > 0.15) -> dno (n > 0.7) -> návrat (n < 0.1).
   - nedošel na dno: "Nedokončené opakování, jdi víc do pohybu"
   - dno dál než tolerance od vzoru: "Jdi víc do pohybu"
   - sestup rychlejší než 25 % času sestupu ve vzoru: "Zpomal" (vzor je velmi pomalý, ~4,7 s do 70 % rozsahu)
8. Mluví se max. jednou za 1,8 s, stejný pokyn max. jednou za 4 s.

## Co zjistila simulace
- Počítání trupu z obou stran nefungovalo z boku (druhá strana má visibility ~0.05) -> opraveno výběrem strany.
- Při 2 chybách současně (trup + kyčel jsou provázané) pokyny přeskakovaly -> opraveno vynecháním 2 nejhorších kloubů a držením hlášeného kloubu.
- Tempo musí být nastavitelné per cvik, jinak každý normální pacient slyší "Zpomal".
- Nejde zachytit: kulatá záda, rotace, kolena do X (valgus) z boku, drobné pohyby.
- Mluvený komentář ve vzorovém videu nebyl zpracován (chybělo ASR). Pravidla z něj je potřeba doplnit ručně.

## Úkoly pro Claude Code
1. **Hosting a živý test (priorita):** připravit projekt pro statický hosting s https (GitHub Pages / Netlify / Vercel), ověřit kameru v Safari na iPhonu i v Chrome na Androidu.
2. **Hosting modelu u sebe:** stáhnout `pose_landmarker_full.task` a wasm do projektu, ať to nezávisí na Google CDN.
3. **Nastavení per cvik:** tolerance, tempo (zapnout/vypnout, poměr), které klouby hlídat, vlastní texty pokynů.
4. **Sdílení vzoru terapeut -> pacient:** export vzoru jako JSON / odkaz / QR kód; pacient ho načte bez nahrávání.
5. **Kontrola úhlu kamery:** před startem ověřit, že je pacient z boku a celý v záběru (visibility kotníků a hlavy, poměr šířky ramen).
6. **Záznam pro terapeuta:** po cvičení souhrn (počet opakování, nejčastější chyby, časy) a export.
7. **Víc cviků:** knihovna vzorů, výběr cviku, volitelně čelní pohled s levou/pravou stranou zvlášť (asymetrie, valgus kolen).
8. **Testovací pipeline v Pythonu** (viz níže) jako regresní test: vzorové video + syntetické chyby -> očekávané pokyny.

## Simulace v Pythonu (jak byla ověřena logika)
- `pip install mediapipe==0.10.14 opencv-python-headless` (starší wheel má přibalený `pose_landmark_full.tflite`, běží offline přes `mp.solutions.pose`, `model_complexity=1`).
- Video dekódovat přes ffmpeg na 30 fps, 540x960 (rotace se aplikuje automaticky), landmarky uložit do JSON.
- Vzor = snímky 21,5-46 s (index 645-1380 při 30 fps).
- Syntetický pacient: forward kinematika od kotníku (bérec, stehno, trup, paže) nad snímky vzoru, chyby vnesené rotací segmentů:
  - nepokrčená kolena: bérec o 28° blíž svislici
  - vzpřímený trup: trup (a vše nad ním) o 30° blíž svislici
  - padající paže: paže o 40° dolů
  - dřep napůl: max. fáze 0.22
  - moc rychle: sestup 1,2 s
- Očekávané výstupy: "Víc pokrč kolena", "Víc se předkloň", "Zvedni paže výš", "Nedokončené opakování...", "Zpomal", u správného "Výborně" bez dalších pokynů.

## Formát vzoru (JSON)
```json
{
  "name": "Dřep (vzor z videa)",
  "primary": "hip",
  "start": 171.2,
  "far": 46.4,
  "present": ["knee", "hip", "sh", "el", "trunk"],
  "frames": [[175.1, 171.0, 12.3, 160.2, 4.1], "..."],
  "refDesc": 4.7,
  "reps": 1
}
```
`frames[i][m]` = úhel kloubu `present[m]` ve stupních. Celá data jsou v HTML v konstantě `DEFAULT_REF`.

## Pravidla pro texty
- Česky, krátké rozkazovací pokyny (do 5 slov), vhodné pro hlas.
- Nepoužívat dlouhé pomlčky, jen spojovník "-".

## Poznámky k produktu
- Pro reálné pacienty jde o zdravotnický software (MDR) a zdravotní data (GDPR) - zpracovávat lokálně, video neukládat ani neodesílat.
