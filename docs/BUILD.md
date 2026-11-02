# Build Guide

Two ways to get the APK: **GitHub Actions** (no tools needed) or a **local
Godot export** (full control).

## Option 1 — GitHub Actions (recommended)

1. Fork or clone `gikoko611/G.I-KO-KO-MYANMAR-OPEN-WORLD-3D`.
2. Push any commit to `main` — the **Android Build** workflow runs:
   - imports the project headless,
   - runs `godot --check-only --script` on **every** `.gd` file (parse gate),
   - exports `build/GiKoKoMyanmarOpenWorld3D.apk` with the Android preset,
   - verifies the APK contains `lib/armeabi-v7a/libgodot*.so`,
   - uploads the APK as an artifact.
3. Download the artifact from the workflow run page, or push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   Tagged runs also attach the APK to a GitHub **Release**.
4. Install on your phone (enable "install unknown apps"), then open.

Target device: Android 10, armeabi-v7a (32-bit ARM), e.g. Redmi 9A.
Set graphics to **Low** in Settings → designed for 2–3 GB RAM class phones.

## Option 2 — Local export with Godot 3.5.2

Requirements:

- **Godot 3.5.2-stable** (desktop editor)
- **Godot 3.5.2 Android export templates** (Editor → Manage Export Templates)
- **JDK 8+** and an **Android SDK** with build-tools / platform-tools
  (Godot needs `SDK_HOME`/`ANDROID_HOME` with `adb` and the Android platform)
- Environment variables (adjust paths):
  ```bash
  export ANDROID_HOME=$HOME/Android/Sdk
  export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
  ```

Steps:

1. Open the project in Godot 3.5.2 (import `project.godot`).
2. Editor → Editor Settings → Export → Android: set the SDK path and debug
   keystore (or leave the default debug one).
3. Project → Export → preset **Android** → check:
   - architectures: **armeabi-v7a = on**, arm64/x86 = off
   - package: `com.gikoko.myanmaropenworld3d`
4. Export To → `build/GiKoKoMyanmarOpenWorld3D.apk`.
5. Install: `adb install -r build/GiKoKoMyanmarOpenWorld3D.apk`
   (or copy the APK to the phone and tap it).

## Quick desktop test (no Android needed)

You can also run the game inside the Godot editor on a PC: open the project and
press F5. Mouse input is mapped to the virtual joystick (left half) and camera
(right half). GLES2 runs on almost any GPU.

## Checklist after first run

- [ ] Splash → menu → pick a story → world loads at the farm
- [ ] Joystick moves the player, camera drag rotates
- [ ] Talk to U Ba, mission MS1 completes and chains to MS2
- [ ] Plow / plant / water / harvest a rice plot
- [ ] Buy seeds at the seed shop, sell crops at the market
- [ ] Drive a vehicle; boat floats on water only
- [ ] Fish at the lake dock with the fishing rod
- [ ] Sleep in the house (20:00–05:00) → next day, autosave
- [ ] Save + Continue from the main menu
- [ ] Redmi 9A: Low graphics stays above ~25 fps

## Troubleshooting

- **Workflow fails on "Validate scripts"** — open the log, find
  `PARSE FAIL: scripts/...`, that file has a syntax error to fix.
- **APK missing armeabi-v7a** — you exported with different templates; make
  sure the 3.5.2 templates are installed and the preset checkboxes are right.
- **Black screen on phone** — the game needs GLES2 support (all Redmi 9A
  firmware has it); try restarting the app once to rebuild the shader cache.
- **Performance** — Settings → graphics **Low** reduces view radius, prop
  density, rain and fog, and disables shadows.
