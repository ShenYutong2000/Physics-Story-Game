# Footnotes to the World — Library Hall prototype

This Godot 4.7.2 project contains a complete short evening patrol in the first prologue room: the Library Hall of the Archive. Its far, middle, character and foreground layers are separate so Kath can walk behind the foreground objects.

## Run

1. Open this folder in Godot 4.7.2 (`project.godot`). Let the asset import finish.
2. Press **F6** with `scenes/library_hall.tscn` open, or **F5** to run the project.
3. Press **Enter** to finish Kath's opening thought. Use **A / D** or **Left / Right Arrow** to move, **E** to inspect a nearby object, **Enter** to advance dialogue or close the sheet, **J** to open or close Notes, and **Esc** to close the current view or pause. While paused, **Enter / Esc** resumes and **Q** quits.

Inspect the archive door on the left, the old clock near the middle, and the maintenance sheet on the right. The sheet's close-up lists **Lamps, Pipes, Pressure, Doors, Upper Shelves**. Each completed inspection adds one observation to Notes. Finishing all three gives Kath a short lead toward the upper shelves. The door is an observation point in this prototype; it does not change scenes.

The scene uses a 1672 × 941 design canvas and opens in a 1280 × 720 window. It keeps the artwork's aspect ratio when resized. The floor and left/right movement limits are currently fixed for this room. Notes are kept only for the current run; saving and scene transitions are later steps. `scenes/hall_hotspot.tscn` exposes an exit signal with destination scene and spawn tag for those later steps.

Kath's shared display height is 301.6 scene pixels (1.3× the initial 232 px). Both idle and walk frames are normalized to this height in `scripts/kath.gd`; future scenes should instance `scenes/kath.tscn` without applying another scale.

Wick's shared display height is 130 scene pixels. Perching and flight frames are both normalized to this height in `scripts/wick.gd`; future scenes should instance `scenes/wick.tscn` without applying another scale.

## Acceptance checks

- Godot imports the project without missing-resource errors.
- Kath starts near the middle of the Hall, idles, walks and faces the direction of travel.
- Foreground books and the globe cover Kath as she passes behind them.
- Kath stays on the painted floor and cannot leave the left/right edges.
- Resizing the window preserves the scene proportions.
- The nearest reachable object shows an **E Inspect** prompt above the foreground. Door, clock and sheet can all be inspected; distant **E** presses do nothing.
- Dialogue, sheet, Notes and pause each block movement and never overlap. **Esc** closes the active view first.
- Notes open empty, keep discoveries in order and never duplicate an observation. The final line plays once after all three are done.
- Wick follows Kath, settles when Kath stops and reacts to the clock and sheet without speaking.

The original prototype asset pack lives under `prologue-asset-pack-v1/`. Keep that folder name: its Godot SpriteFrames resources contain paths beginning with `res://prologue-asset-pack-v1/`.

For automated integration checks, run the following from this folder with Godot 4.7.2:

```powershell
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week1_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week2_smoke.gd
```
