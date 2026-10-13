# Footnotes to the World — Library Hall prototype

This Godot 4.7.2 project contains three playable prologue rooms: the Library Hall, Machine Room, and Upper Stacks. Their far, middle, character, and foreground layers are separate so Kath can walk behind foreground objects.

## Run

1. Open this folder in Godot 4.7.2 (`project.godot`). Let the asset import finish.
2. Press **F6** with `scenes/library_hall.tscn` open, or **F5** to run the project.
3. Press **Enter** to finish Kath's opening thought. Use **A / D** or **Left / Right Arrow** to move, **E** to inspect or use a nearby object, **Enter** to advance dialogue or confirm the torn page, **J** to open or close Notes, and **Esc** to close the current view or pause. While paused, **Enter / Esc** resumes and **Q** quits.

Inspect the archive door on the left, the old clock near the middle, and the maintenance sheet on the right. The sheet's close-up lists **Lamps, Pipes, Pressure, Doors, Upper Shelves**. Each completed inspection adds one observation to Notes. After all three, use the archive door to enter the Machine Room. Compare the gauge's current needle position with its previous pencil mark; **Enter** records the observation and **Esc** leaves without recording it. The route diagram is optional. Use the left-side exit to return to the Hall. The Hall then plays a one-time drip cue and points Kath toward the upper stacks.

After recording the Machine Room reading, use the Hall's right-side stairs to enter the Upper Stacks. Inspect the roof seam and press **E** again to slide the bucket under the drip. At the rolling ladder, press **E** to take hold; use **A / D** or the arrow keys to push it along the floor, then press **E** to lock it in place. Align it beneath the high wooden case, press **E** to climb, and use **W / S** or **Up / Down Arrow** to climb. The case only opens when Kath is high enough and the ladder is correctly positioned. Press **E** to open it, then **E** again to view the page. **Enter** records the page; **Esc** closes it while leaving it in the box. Press **J** and **Enter** to revisit a collected page from Notes. Descend to the floor before using the stairway back to the Hall.

The scenes use a 1672 × 941 design canvas and open in a 1280 × 720 window. They keep the artwork's aspect ratio when resized. Floors and left/right movement limits are set per room. `PrologueState` keeps unique notes and transition flags for the current run; it does not write a disk save.

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
- The machine-room door stays an inspection until the three Hall checks are complete; afterward it changes to an entrance.
- The gauge view shows a prior pencil mark and a current needle below the red sector. **Enter** records once; **Esc** cancels.
- Returning from the Machine Room restores Kath beside the Hall door, keeps all notes, and plays the drip cue once after a reading is recorded.
- Wick follows Kath, settles when Kath stops and reacts to the clock and sheet without speaking.
- The Hall's right staircase is inspect-only until the Machine Room reading is recorded.
- In the Upper Stacks, roof leak, bucket, ladder position, open case, and recovered page survive multiple trips between rooms.
- Ladder movement and climbing use A/D or arrows and W/S or arrows; pausing on the ladder preserves Kath's height.
- The case requires both horizontal ladder alignment and climbing height. Escaping the page close-up does not collect it; Enter records it once and the journal can reopen it.

The original prototype asset pack lives under `prologue-asset-pack-v1/`. Keep that folder name: its Godot SpriteFrames resources contain paths beginning with `res://prologue-asset-pack-v1/`.

For automated integration checks, run the following from this folder with Godot 4.7.2:

```powershell
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week1_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week2_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week3_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week4_smoke.gd
```
