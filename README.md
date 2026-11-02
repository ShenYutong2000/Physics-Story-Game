# Footnotes to the World — Prologue and Chapter I prototype

Godot 4.7.2 project for a 2D storybook adventure about Kath, Wick, and the lost explanations behind a mechanical world. The playable route runs from the Grand Archive's library hall through the Observatory Castle rescue and ends with an unfinished record pointing to the Floating Isles. The Floating Isles is a next-chapter lead, not a playable map in this prototype.

## Start and continue

Open `project.godot` in Godot 4.7.2 and press **F5**. The title screen offers **New Game** and, when a valid single-slot checkpoint exists, **Continue**. Starting over with a checkpoint requires a second Enter confirmation. Continue restores the latest observations, mechanism states, castle orientation, and scene at a safe entrance. It does not restore Kath's exact position inside the room or an unfinished modal choice.

The game saves on room transitions and about every five seconds while Kath is freely exploring, paused, or viewing the chapter end card. Press **Esc** in exploration to pause, then **Q** to save and quit. A new run replaces the old slot. The file lives in Godot's `user://footnotes-chapter1-save.json`; Godot manages its actual system location. Direct **F6** scene previews are developer previews and do not enable disk saves.

## Controls

- **A/D** or **Left/Right**: walk; select items in certain close views.
- **E**: inspect, use, grab, lock, or operate the nearby object.
- **Enter**: advance dialogue or confirm a close view.
- **Esc**: close a view; pause while exploring. **Enter/Esc** resumes from pause.
- **J**: open or close Notes. **Up/Down** scrolls them.
- **W/S** or **Up/Down**: climb ladders; control the shaft winch when its view is open.
- **Space**: apply the stronger basket brake during Erin's descent.
- **Q** on the pause screen: save and quit.

## Play route

1. **Grand Archive.** Inspect the library door, clock, and maintenance sheet. Record the machine-room gauge baseline. Return to the hall, follow the leak to the upper stacks, position the bucket and ladder, and recover Kath's torn `F = ma` page. In Kath's room, match its torn edge to her notebook, rest until morning, and pack the notebook.
2. **Alarm and service road.** Return to the hall for the alarm. In the machine room, operate levers 2 and 4 and stop the local drive; the distant castle wing becomes tilted. Follow the service road, inspect the hanging cable, open the gate, and enter the castle control walkway from the chapter card.
3. **On-site inversion.** At the control walkway, compare the dial with the visible wing and speak with Erin. The failed return test turns the wing to the separate inverted maintenance catch. Enter the lower passage. In the inverted room, compare falling water and the plumb weight to establish the actual downward direction, then inspect and climb the maintenance ladder.
4. **Rescue in the fixed shaft.** Contact Erin through the speaking tube, load tools from the safe platform, raise the basket, and let her open the bent upper rail. Bring the empty basket down, lock it, take the long rope, and rethread through the basket pulley. Perform a short empty test, raise and dock the empty basket again, then let Erin board. Take up slack, confirm the four load checks, release the upper catch, and lower her with measured braking. Lock the lower dock and use the loading spur to bring her onto the fixed platform.
5. **Restore the castle.** Enter the engine room with Erin. Inspect the chart, wet track, linkage, brake, and signal. Isolate the automatic drive, remove the obstruction, test the home stop, brake, and lock, then hold Left at the maintenance drive to return the wing slowly to its normal position.
6. **Archive and ending.** Cross into the observatory. Open the shaken drawer and read its signed work record, Floating Isles comparison slip, and unexplained withdrawn page in any order. At the worktable, stitch the torn leaf into Kath's notebook. Return to Erin in the engine room for the final conversation and the Chapter I completion card. Enter or Esc closes the card and leaves the restored castle explorable.

Notes are added once in discovery order. Esc cancels an unconfirmed document, inspection, or repair check. The game never assumes the cause of the original roof leak or the reason for a withdrawn record before evidence establishes it.

## Prototype timing

`PrologueState` tracks active play time, excluding pause. When the first Chapter I completion card is reached, Godot prints `CHAPTER_I_PLAYTIME: mm:ss` in Output and stores the same timer fields in the checkpoint. This is an instrument for a fresh-player test, not a claim that the chapter already lasts a measured 25 minutes. The timing and review protocol is in `chapter1-assets/planning/phase3-step7-integration.md`.

## Project and checks

The design canvas is **1672×941** and the default window is **1280×720**, with aspect-preserving scaling. Kath's shared display height is **301.6 scene pixels** and Wick's is **130 scene pixels**; their shared scenes normalize their frames, so do not scale individual instances again. The reusable art source and game PNG layers are under `chapter1-assets/` and `prologue-asset-pack-v1/`.

Run the smoke scripts under `tests/` with Godot 4.7.2. The complete sequence includes `week1_smoke.gd` through `week6_smoke.gd`, `phase3_step1_smoke.gd` through `phase3_step6_smoke.gd` (including `phase3_step6a_smoke.gd`), `phase3_engine_restoration_smoke.gd`, `phase3_archive_finale_smoke.gd`, `phase3_step7_checkpoint_smoke.gd`, and `phase3_step7_quit_smoke.gd`. The save checks use dedicated temporary filenames and do not touch the player's slot.
