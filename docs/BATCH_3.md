# Batch 3: Three crash-safe save slots

## Implemented

- Added three independent local save slots.
- Each slot writes to a temporary file, verifies the JSON, keeps the previous valid file as a backup and only then replaces the active file.
- Slot 1 can load the old single-slot `savegame.json`; after the next successful slot-1 save, the legacy files are removed.
- Main menu now shows slot summaries with day, player level and money.
- Continue disables empty slots.
- New Game asks for a slot before the story choice; choosing a used slot does not delete it until the final story choice is confirmed.
- Pause menu clearly shows the current slot and saves or reloads that slot.
- Settings remember the last selected slot.
- Existing 90-second autosave uses the selected slot without changing the world loop.

## Data files

For slot `N`:

- Active: `user://savegame_slot_N.json`
- Temporary: `user://savegame_slot_N.tmp`
- Backup: `user://savegame_slot_N.bak`
- Damaged active file quarantine: `user://savegame_slot_N.corrupt.json`

## Device test checklist

1. Install the feature-branch APK on the Redmi 9A without uninstalling the current app.
2. Confirm the old save appears in slot 1 and loads.
3. Save it once and return to the menu; confirm slot 1 shows the current day, level and money.
4. Start different games in slots 2 and 3, move the player, save and confirm each returns to its own location.
5. Force-close during ordinary play, reopen and confirm the selected slot still loads.
6. Leave the game running for more than 90 seconds, return to menu without manual save and confirm autosave updated only the current slot.
7. Watch for overlapping menu text at 1280x720 landscape and verify every slot button responds to touch.

## Honest limitations

- The source and CI can verify script parsing, APK signing and the ARMv7 payload; they cannot prove Redmi 9A FPS, RAM use or Android lifecycle behaviour.
- Save overwrite has no second confirmation dialog after the story selection. The previous slot remains intact until the player confirms a story choice.
- Save data remains JSON and is not encrypted.
