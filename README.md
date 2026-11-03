# G.I KO KO – MYANMAR OPEN WORLD 3D

A complete 3D open-world farming, survival and exploration game set in a
Myanmar river valley. Built with **Godot 3.5.2 (GLES2)** for **Android 10+
(armeabi-v7a)**, tuned for low-end phones such as the **Redmi 9A (32-bit)**.

> Powered by I KO KO

## Features

- **Seamless open world** — procedurally generated valley with a winding river,
  lake, island, waterfall, mountains, rice paddies, roads, village, town,
  pagoda, shrine and hidden spots. Chunk-streamed terrain, no loading screens.
- **Farming** — 24 plots: plow, plant (12 crops), water, fertilize, harvest.
  Growth depends on the season and weather.
- **Survival** — health, stamina, hunger and thirst. Eat, drink from wells,
  sleep in your house (autosaves). Storms and cold nights are dangerous.
- **Fishing** — 8 species (including the rare Golden Kya) with a timing
  minigame.
- **Animals** — chickens, ducks, cows, buffalo, pigs, goats, cats, dogs; feed,
  collect eggs, milk, buy a companion pet.
- **Vehicles** — bicycle, motorbike, tuk-tuk, car, pickup, truck and a boat
  (water only). Fuel, damage, repair and refuel.
- **Races** — 3 race tracks with checkpoints and time targets.
- **Treasure** — 8 treasure mounds hidden around the valley.
- **Building** — place farmhouses, barns, warehouses, a water tower and more
  (costs money + materials); each building has an interior.
- **Missions** — **88 missions and achievements**: main story (8 chapters),
  side quests, farming, deliveries, errands, vehicle, survival, fishing,
  animal, race, timed, hidden, 8 dailies, 4 weeklies, 4 event missions and
  10 achievements. Tracked by a live beacon and minimap marker.
- **Village life** — 11 NPCs with daily schedules, dialogue, shops (seed,
  vehicle, animal, general, market, fuel) and a wandering trader.
- **Economy** — sell crops, fish, eggs, milk, truffles, wood and stone;
  festival days give better prices.
- **Story choices** — pick your background (Family Duty / Fresh Start /
  Golden Harvest) for different starting bonuses.
- **Save system** — autosave + manual save/load, settings (graphics quality,
  music/SFX/ambience volume), Redmi-9A-friendly "Low" preset.
- **100% procedural assets** — every mesh is built in code, every sound is
  synthesized PCM, the icon is SVG. No binary assets, tiny repo, fast build.

## Controls (Android touch)

| Action | Touch |
| --- | --- |
| Move | drag anywhere on the **left half** (virtual joystick) |
| Look / rotate camera | drag on the **right half** |
| Jump / Walk–Sprint | big buttons bottom-right |
| Interact / context actions | buttons on the right edge when near something |
| Panels | Missions / Map / Bag / Build / Menu, top-right |
| Drive | Exit Vehicle + BRAKE buttons appear while driving |
| Build | pick in Build panel, walk to spot, Confirm/Cancel |
| Fish | "Fish" appears near water if you own a fishing rod |

Mouse is also supported for desktop testing (left half = joystick).

## Build the APK

The easiest way — **GitHub Actions** builds it for you:

1. Push any commit to `main` (already done).
2. Open the **Actions** tab → **Android Build** → wait for it to finish
   (about 3–5 minutes).
3. On success the APK is attached to the **v1.0.0 Release** automatically
   (see the Releases page), or download the `GiKoKoMyanmarOpenWorld3D-apk`
   artifact from the run page.

The workflow downloads headless Godot 3.5.2 + export templates, configures
the Android SDK and a debug keystore, imports and validates the whole
project and exports the APK — no local tools needed. Diagnostics for each
run are pushed to the `ci-status` branch.

For a local build (Godot 3.5.2 + Android export templates + JDK + Android SDK),
see [docs/BUILD.md](docs/BUILD.md).

## Project layout

```
project.godot            Godot 3.5.2 config, autoloads, GLES2, 30 fps physics
export_presets.cfg       Android preset (armeabi-v7a only)
scripts/autoload/        Events, ItemDB, TerrainGen, Props, AudioSynth,
                         GameState, SaveMgr, Missions
scripts/missions/        mission_data.gd (88 mission definitions)
scripts/world/           world, terrain chunks, farm, NPCs, animals,
                         vehicles, buildings, gatherables, treasure, races
scripts/player/          player controller (walk, run, swim, survival stats)
scripts/ui/              HUD, joystick, panels (inventory, shop, missions,
                         map, dialogue, pause, build, fish), splash, menu
scenes/                  splash.tscn, main_menu.tscn, main.tscn
```

## Known limitations

- **All visuals and audio are procedural placeholders** — primitive meshes and
  synthesized sounds keep the repo binary-free and the APK small; they are
  intentionally simple.
- UI is in **English** (Burmese fonts need a bundled font file; add one under
  the same license terms if you want Burmese text).
- CI has not been tested on a physical device; please report issues.
- Single-player, offline only.

## License

All code in this repository was written from scratch for this project.
