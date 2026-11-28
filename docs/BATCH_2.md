# Batch 2: Mobile movement controls and CI gate

## Implemented

- Added dedicated Android touch buttons for crouch/stand and first/third-person camera switching.
- Crouch changes the capsule height, camera height and visible character pose without adding another physics body.
- First-person mode shortens the existing SpringArm and hides the player mesh to prevent the camera seeing inside the character.
- Controls hide while a full-screen UI panel is open; crouch is disabled while driving.
- Android build now runs on feature branches and pull requests, not only after merging to main.
- CI now fails on GDScript parse errors instead of allowing the import step to fail silently.
- CI verifies that the APK contains armeabi-v7a and rejects an accidental arm64 payload.
- APK artifacts are named with the commit SHA and retained for 14 days.

## Deliberately deferred

Myanmar UI text is not included in this batch. Godot 3.5 does not provide the same complex text shaping path as Godot 4, so adding a Myanmar font alone does not prove correct stacked-diacritic rendering. This needs an on-device rendering test before replacing production labels.

## Device test checklist

1. Install the workflow APK on Xiaomi Redmi 9A.
2. Start a new game and verify that Crouch lowers both collision and camera.
3. Walk beneath a low edge, press Stand and verify that the player does not become stuck.
4. Toggle first person, rotate the camera and verify that no body geometry blocks the view.
5. Enter and exit a vehicle in both camera modes.
6. Open inventory and pause panels and verify the new controls are hidden.
7. Play for 10 minutes on LOW and record the approximate FPS and whether Android kills the app.

## Known limitation

Standing currently does not perform an overhead clearance ray check. The existing procedural world has no crawl-space geometry, but a clearance test must be added before low-ceiling interiors are introduced.
