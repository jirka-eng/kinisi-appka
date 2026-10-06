# Import nahrávek hlasu Fyzioscanneru.
# Vezme složku s nahrávkami (WAV/MP3/M4A…), přiřadí je k větám podle názvu souboru ze scénáře
# (hlas/clips.json), sjednotí hlasitost, ořízne ticho, převede na MP3 do hlas/audio/
# a zapíše hlas/audio/manifest.json se seznamem hotových vět. Aplikace pak hotové věty
# přehrává místo hlasu telefonu.
#
# Spuštění:  python3 hlas/import_nahravky.py <složka-s-nahrávkami> [--ffmpeg /cesta/k/ffmpeg]
import json, os, re, subprocess, sys, unicodedata

def norm(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")

def main():
    args = sys.argv[1:]
    if not args: sys.exit(__doc__ or "python3 hlas/import_nahravky.py <slozka>")
    src = args[0]
    ff = args[args.index("--ffmpeg") + 1] if "--ffmpeg" in args else "ffmpeg"
    here = os.path.dirname(os.path.abspath(__file__))
    clips = json.load(open(os.path.join(here, "clips.json"), encoding="utf-8"))
    keys = {norm(k.replace("/", "_")): k for k in set(clips.values())}   # "korekce_napremte-pater" -> "korekce/napremte-pater"
    out_dir = os.path.join(here, "audio"); os.makedirs(out_dir, exist_ok=True)
    man_path = os.path.join(out_dir, "manifest.json")
    have = set(json.load(open(man_path))) if os.path.exists(man_path) else set()
    unknown = []
    for name in sorted(os.listdir(src)):
        base, ext = os.path.splitext(name)
        if ext.lower() not in (".wav", ".mp3", ".m4a", ".aac", ".ogg", ".flac", ".aiff", ".aif"): continue
        k = keys.get(norm(base))
        if not k: unknown.append(name); continue
        out = os.path.join(out_dir, k.replace("/", "_") + ".mp3")
        # mono, 44,1 kHz, ořez ticha na začátku i konci, sjednocená hlasitost (-16 LUFS), MP3 96 kb/s
        flt = ("silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
               "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.08,areverse,"
               "loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=0.05")
        subprocess.run([ff, "-v", "error", "-y", "-i", os.path.join(src, name), "-ac", "1", "-ar", "44100",
                        "-af", flt, "-c:a", "libmp3lame", "-b:a", "96k", out], check=True)
        have.add(k)
        print("✓", name, "->", os.path.relpath(out, here))
    json.dump(sorted(have), open(man_path, "w"), indent=1)
    missing = sorted(set(clips.values()) - have)
    print(f"\nHotovo: {len(have)} z {len(set(clips.values()))} vět. Chybí {len(missing)}.")
    if unknown: print("Nepřiřazené soubory (zkontrolovat název):", ", ".join(unknown))

if __name__ == "__main__":
    main()
