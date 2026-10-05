# App Store screenshots — Habit Core

6.9" iPhone, 1260×2736 PNG (no alpha), en + pl. Same pipeline as WalletLog, green palette.

1. `./capture.sh` — builds the Debug app on the iPhone 17 Pro Max simulator, seeds localized demo
   data (`UI_TESTING_SEED_DATA`, see `Habit Core/Debug/ScreenshotMode.swift`), sets the 9:41
   status bar and captures `raw/<screen>_<lang>.png` plus real widget renders
   (`raw/widget_*_<lang>.png`, made with `ImageRenderer`).
2. `node generator/generate.js [lang] [screen]` — composites captions, the real iPhone frame and
   the glow background into `final/NN_<screen>_<lang>.png` (headless Google Chrome).

Captions live in `generator/generate.js`. `raw/` is regenerable and not committed.
