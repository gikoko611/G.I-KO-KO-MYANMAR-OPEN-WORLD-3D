# Roadmap and honest status (V2 PRO master prompt)

This file tracks the V2 PRO master prompt against what is actually in the source. "Done" means code exists in this repository; it does not mean the feature has been tested on a Redmi 9A. Only an on-device test can confirm FPS, RAM and touch behaviour.

## Completed implementation batches

### Batch 1: Redmi 9A foundation hardening

- LOW graphics preset is the first-launch default.
- Graphics indices are clamped and LOW rain particles are reduced.
- Crash-safe atomic save/settings writes with backup fallback.
- Cyber Neon Green + Midnight Gold UI foundation and branded splash.

### Batch 2: Mobile movement controls and CI gate

- Dedicated Crouch/Stand and first/third-person touch controls.
- Feature branches receive an APK artifact before review.
- CI rejects GDScript parse errors and rejects an accidental ARM64 payload.
- Myanmar UI text was deliberately deferred because Godot 3.5 complex-text shaping needs an on-device rendering test.

### Batch 3: Three save slots

- Three independent crash-safe local save slots.
- Main-menu slot picker and save summaries.
- Legacy single save migrates through slot 1.
- Current slot is used by manual save, 90-second autosave and Save & Quit.

## Status against the master prompt

| Prompt section | Status | Notes |
|---|---|---|
| 2. Godot 3.5.2 / GLES2 / ARMv7 export | Done in CI | CI exports armeabi-v7a and checks the APK payload. Phone installation still needs testing |
| 3. Regions | Partial | One river valley exists. Yangon urban, Bagan temple plains and Shan highlands are not built yet |
| 4. Player | Partial | Walk, run, jump, swim, crouch and first/third-person toggle exist. Touch/device test still required |
| 5. Farming (12 crops) | Done in source | Needs on-device balance test |
| 6. Survival | Done in source | Health, stamina, hunger, thirst, food, water and sleep exist |
| 7. NPC and animal AI | Partial | NPCs and animals exist; daily schedules and distance activation need deeper verification |
| 8. Vehicles | Partial | Several vehicles exist; tractor and dedicated fishing boat are missing |
| 9. Missions (20+) | Done in source | README lists 88 missions |
| 10. Day/night and weather | Done in source | Seasonal visuals remain limited |
| 12. UI | Partial | Branded theme and touch controls exist. Myanmar text is not shipped yet |
| 13. Save/load | Done in source | Three slots, atomic writes, backups and legacy slot-1 migration |
| 15. Audio | Placeholder | Audio is procedural synth; recorded Myanmar ambience is not present |
| 16. Optimisation | Partial | Chunk streaming, MultiMesh scatter and presets exist. Redmi 9A profiling is still required |
| Art | Placeholder | Visuals are procedural low-poly placeholders, not final AAA assets |

## Next implementation batches

1. Batch 4: Bagan-inspired temple plains as streamed world content.
2. Batch 5: tractor and dedicated fishing boat.
3. Batch 6: Shan-inspired highlands.
4. Batch 7: Yangon-inspired urban district.
5. Profile on the Redmi 9A after every batch and reduce the next batch if memory or frame time exceeds budget.

## Required phone test

1. Download the latest successful feature-branch APK artifact.
2. Install it on Xiaomi Redmi 9A without uninstalling the previous build.
3. Test splash, LOW default, three save slots, touch controls, first/third person and crouch.
4. Play for 15 minutes while moving between chunks and record crashes, visible stutter and approximate FPS.
5. Report the failing action and selected slot if a save does not restore correctly.
