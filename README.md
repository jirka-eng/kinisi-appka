# Kinisi - kontrola domácího cvičení

Terapeut nahraje vzor cviku, pacient pak cvičí před kamerou telefonu a aplikace hlasem říká, co dělá špatně. Vše běží v prohlížeči, video neopouští zařízení.

- `index.html` - aplikace (hostovaná přes GitHub Pages)
- `vendor/mediapipe/` - MediaPipe Tasks Vision 0.10.14 (JS + wasm), hostováno lokálně
- `models/pose_landmarker_full.task` - model pro rozpoznání postavy
- `fyzio-kontrola-cviku.md` - zadání a popis logiky detekce
