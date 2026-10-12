# Footnotes to the World — Week 1 prototype

This Godot 4.7.2 project contains the first playable room of the prologue: the Library Hall of the Archive. Its far, middle, character and foreground layers are separate so Kath can walk behind the foreground objects.

## Run

1. Open this folder in Godot 4.7.2 (`project.godot`). Let the asset import finish.
2. Press **F6** with `scenes/library_hall.tscn` open, or **F5** to run the project.
3. Use **A / D** or **Left / Right Arrow** to move Kath.

The scene uses a 1672 × 941 design canvas and opens in a 1280 × 720 window. It keeps the artwork's aspect ratio when resized. The floor and left/right movement limits are currently fixed for this room. Dialogue, interactions and scene transitions are scheduled for later development steps.

Kath's shared display height is 301.6 scene pixels (1.3× the initial 232 px). Both idle and walk frames are normalized to this height in `scripts/kath.gd`; future scenes should instance `scenes/kath.tscn` without applying another scale.

## Week 1 acceptance check

- Godot imports the project without missing-resource errors.
- Kath starts near the middle of the Hall, idles, walks and faces the direction of travel.
- Foreground books and the globe cover Kath as she passes behind them.
- Kath stays on the painted floor and cannot leave the left/right edges.
- Resizing the window preserves the scene proportions.

The original prototype asset pack lives under `prologue-asset-pack-v1/`. Keep that folder name: its Godot SpriteFrames resources contain paths beginning with `res://prologue-asset-pack-v1/`.

For a quick automated integration check, run `Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/week1_smoke.gd` from the project folder.
