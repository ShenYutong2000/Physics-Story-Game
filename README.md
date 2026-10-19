# Footnotes to the World — Prologue prototype

This Godot 4.7.2 project contains the playable prologue rooms: the Library Hall, Machine Room, Upper Stacks, Kath's Room, and the dawn Service Road to the Observatory Castle. These prologue rooms use separate far, middle, character, and foreground layers. A temporary Chapter I Control Walkway uses the supplied full illustration until its layered artwork is built.

## Run

1. Open this folder in Godot 4.7.2 (`project.godot`). Let the asset import finish.
2. Press **F6** with `scenes/library_hall.tscn` open, or **F5** to run the project.
3. Press **Enter** to finish Kath's opening thought. Use **A / D** or **Left / Right Arrow** to move, **E** to inspect or use a nearby object, **Enter** to advance dialogue or confirm the torn page, **J** to open or close Notes, and **Esc** to close the current view or pause. While paused, **Enter / Esc** resumes and **Q** quits.

Inspect the archive door on the left, the old clock near the middle, and the maintenance sheet on the right. The sheet's close-up lists **Lamps, Pipes, Pressure, Doors, Upper Shelves**. Each completed inspection adds one observation to Notes. After all three, use the archive door to enter the Machine Room. Compare the gauge's current needle position with its previous pencil mark; **Enter** records the observation and **Esc** leaves without recording it. The route diagram is optional. Use the left-side exit to return to the Hall. The Hall then plays a one-time drip cue and points Kath toward the upper stacks.

After recording the Machine Room reading, use the Hall's right-side stairs to enter the Upper Stacks. Inspect the roof seam and press **E** again to slide the bucket under the drip. At the rolling ladder, press **E** to take hold; use **A / D** or the arrow keys to push it along the floor, then press **E** to lock it in place. Align it beneath the high wooden case, press **E** to climb, and use **W / S** or **Up / Down Arrow** to climb. The case only opens when Kath is high enough and the ladder is correctly positioned. Press **E** to open it, then **E** again to view the page. **Enter** records the page; **Esc** closes it while leaving it in the box. Press **J** and **Enter** to revisit a collected page from Notes. Descend to the floor before using the stairway back to the Hall.

After collecting the torn page, use the Upper Stacks' left doorway to enter Kath's Room. Turn on the desk lamp, compare the page with the gap in her notebook, then rest at the bed to advance to dawn. Pack the notebook in the satchel and return through the stacks to the Hall. The one-time alarm leads back to the Machine Room. Open the gauge console, use **Left / Right** to select levers 2 and 4, and press **E** to operate them. Press **Esc** to close the console, then use the emergency stop near the right side of the room. If you stop the drive first, you can still operate both levers afterward. Watch the distant Observatory Castle's supported wing tilt about 12° clockwise in its ring over roughly three seconds; the fixed tower remains upright. The Archive's local drive is stopped, while the Castle's local control signal remains unstable. Kath records what she saw without claiming a cause. The incident record and dawn state persist when moving between rooms.

After the incident, use the far-right Machine Room exit to reach the Service Road; the left exit still returns to the Library Hall. Inspect the sign and loose cable, then approach the gate and press **E** to open it. Walk through to the far right to see **Chapter I — Upside-Down Castle / Prologue Complete**. Press **Enter** to enter the Control Walkway, or **Esc** to return to the road. On the walkway, move left and press **E** near its exit to return to the Service Road. Kath follows the road's painted incline; the walkway uses a flat standing area on the left of its illustration. The Castle's 180° inversion will occur later inside Chapter I.

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
- In Kath's Room, the comparison can be cancelled, but confirming it records one unique note. Resting changes the window view to dawn across every prologue room; the satchel must be packed before the incident alarm is armed.
- The machine incident can be completed in the listed order or by stopping the local drive first. Re-entering during the incident restores lever and stop states. The one-time remote view ends at a 12° wing tilt and leaves an observation note without claiming its cause.
- The Service Road stays locked before the incident is complete and opens afterward; its doorway returns to the Machine Room while the Hall exit remains available.
- Kath's feet follow the Service Road slope, and the supported castle wing remains tilted inside the ring while the fixed tower stays upright.
- The road sign and hanging cable add unique notes; the cable is one observation and does not establish the Castle's vertical direction. The gate state persists across travel.
- Reaching the open road's end displays the chapter handoff card. **Esc** places Kath left of the trigger without reopening it immediately; **Enter** enters the temporary Control Walkway. Kath and Wick appear on its walkable left platform and can return to the road without repeating first-arrival dialogue or notes.

The original prototype asset pack lives under `prologue-asset-pack-v1/`. Keep that folder name: its Godot SpriteFrames resources contain paths beginning with `res://prologue-asset-pack-v1/`.

For automated integration checks, run the following from this folder with Godot 4.7.2:

```powershell
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week1_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week2_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week3_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week4_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week5_smoke.gd
& 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/week6_smoke.gd
```
