# Roadmap and honest status (V2 PRO master prompt)

This file tracks the V2 PRO master prompt against what is actually in the
source. "Done" means code exists in this repo; it does **not** mean it has
been tested on a Redmi 9A. Only an on-device test can confirm FPS and RAM.

## Batch 1: Redmi 9A foundation hardening (this branch)

| Change | File | Why |
|---|---|---|
| LOW graphics is the default on first launch and for old saves | `scripts/autoload/game_state.gd` | Prompt requires LOW as default on Redmi 9A |
| Graphics index clamped everywhere | `scripts/autoload/game_state.gd` | A bad value in a save could crash `view_radius()` with an out-of-range index |
| LOW rain particles 250 -> 180 | `scripts/autoload/game_state.gd` | Lower GPU fill cost on Helio G25 |
| Crash-safe saves: write .tmp, verify JSON, keep .bak, then swap | `scripts/autoload/save_manager.gd` | Old code wrote straight over the save; a kill mid-write lost progress |
| Auto-fallback to backup save if the main save is damaged | `scripts/autoload/save_manager.gd` | No lost progress after a crash |
| Settings written with the same safe method | `scripts/autoload/save_manager.gd` | Same reason |
| Splash now reads G.I / MYANMAR OPEN WORLD 3D / POWERED BY I KO KO, tap to skip | `scripts/ui/splash.gd` | Old splash resized fonts with DynamicFont, but Godot 3.5's default font is a BitmapFont, so its title text never drew |
| Cyber Neon Green + Midnight Gold theme, 48 px minimum button height | `scripts/ui/ui_theme.gd` | Prompt UI theme and touch-friendly buttons |

## Status against the master prompt

| Prompt section | Status | Notes |
|---|---|---|
| 2. Godot 3.5.2 / GLES2 / ARMv7 export | Done | CI exports armeabi-v7a only and verifies `lib/armeabi-v7a/libgodot*.so` |
| 3. Regions | Partial | One river valley (village, town, rice fields, river, lake, pagoda). Yangon urban, Bagan temple plains and Shan highlands are not built yet |
| 4. Player | Partial | Walk, run, jump, swim, survival stats exist. Crouch and a first-person toggle need checking/adding |
| 5. Farming (12 crops) | Done in source | Needs on-device balance test |
| 6. Survival | Done in source | |
| 7. NPC and animal AI | Partial | Daily schedules and distance-based activation need verification |
| 8. Vehicles | Partial | Tractor and fishing boat missing |
| 9. Missions (20+) | Done in source | README lists 88 missions |
| 10. Day/night, weather | Done in source | Seasonal visuals limited |
| 12. UI | Partial | Theme updated in batch 1. Myanmar-language text needs a bundled font with Myanmar glyphs (for example Noto Sans Myanmar, OFL licence); the default Godot font has none |
| 13. Save/load | Improved in batch 1 | Single slot. Multiple slots planned |
| 15. Audio | Placeholder | All audio is procedural synth; no recorded ambience yet |
| 16. Optimisation | Partial | Chunk streaming, MultiMesh scatter and presets exist. Needs profiling on the phone |
| Art | Placeholder | All visuals are procedural low-poly placeholders |

## Next batches

1. Batch 2: bundle Noto Sans Myanmar (subset) and switch UI text to Myanmar; crouch and first-person toggle.
2. Batch 3: multiple save slots (3 slots) on the main menu.
3. Batch 4: Bagan temple plains region as new streamed chunks.
4. Batch 5: tractor and fishing boat.
5. Batch 6: Shan highlands, then Yangon urban district.

## How to test this branch on the phone

1. Open the Actions tab, pick **Android Build**, choose **Run workflow** and select this branch.
2. Download the APK artifact and install it on the Redmi 9A.
3. Check: splash text shows, Settings opens on Low, save then force-close the app, reopen and Continue.
4. Report FPS (Settings or a screen recorder) and any crash back so the next batch can fix it.
