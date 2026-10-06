# Hlas Fyzioscanneru

- `scenar.py` – vytvoří scénář k namluvení (`Fyzioscanner_scenar_nahravani.xlsx`) a mapu věta → soubor (`clips.json`).
- `import_nahravky.py <složka>` – převezme nahrávky (WAV/MP3/M4A…, název podle sloupce Soubor, např. `korekce_napremte-pater.wav`),
  sjednotí hlasitost, ořízne ticho, uloží MP3 do `audio/` a zapíše `audio/manifest.json`.
- Aplikace přehraje namluvenou větu, a kde nahrávka chybí, použije hlas telefonu. Složené věty („3. Dokončete pohyb…“)
  skládá z kousků; úvod cviku přehraje z nahrávek, jen když jsou namluvené všechny jeho věty (nemíchá dva hlasy).
