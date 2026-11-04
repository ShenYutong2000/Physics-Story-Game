# Footnotes to the World — Prologue and Chapter I prototype

Godot 4.7.2 project for a 2D storybook adventure about Kath, Wick, and the lost explanations behind a mechanical world. The playable route runs from the Grand Archive's library hall through the Observatory Castle rescue and ends with an unfinished record pointing to the Floating Isles. The Floating Isles is a next-chapter lead, not a playable map in this prototype.

## Start and continue

Open `project.godot` in Godot 4.7.2 and press **F5**. The title screen offers **New Game** and, when a valid single-slot checkpoint exists, **Continue**. Starting over with a checkpoint requires a second Enter confirmation. Continue restores the latest observations, mechanism states, castle orientation, and scene at a safe entrance. It does not restore Kath's exact position inside the room or an unfinished modal choice.

The game saves on room transitions and about every five seconds while Kath is freely exploring, paused, or viewing the chapter end card. Press **Esc** in exploration to pause, then **Q** to save and quit. A new run replaces the old slot. The file lives in Godot's `user://footnotes-chapter1-save.json`; Godot manages its actual system location. Checkpoints are written through a temporary file and retain a `.bak` copy; Continue falls back to that copy if the primary file is damaged. Direct **F6** scene previews are developer previews and do not enable disk saves.

**Settings** are available on the title screen or with **S** while paused. Adjust master, ambience and effect volume; text size from 100% to 115%; optional H hints; and the interaction, notes and hint letter keys. Story progress and preferences are separate files. Esc closes Settings and returns to the title or paused game.

## Controls

- **A/D** or **Left/Right**: walk; select items in certain close views.
- **E**: interact with a nearby object or person—examine, read, talk, take, move, operate, climb, or enter, depending on the prompt.
- **H**: request an optional hint. Each press reveals one of three increasingly specific hints; the level resets when the objective or its evidence changes.
- **Enter**: advance dialogue or confirm a close view.
- **Esc**: close a view; pause while exploring. **Enter/Esc** resumes from pause.
- **J**: open or close Notes. **Up/Down** scrolls them.
- **W/S** or **Up/Down**: climb ladders; control the shaft winch when its view is open.
- **Space**: apply the stronger basket brake during Erin's descent.
- **S** on the pause screen: settings. **Q**: save and quit.

Nearby inspectable objects show a small storybook mark before Kath is close enough to use E. At the original interaction distance the mark is joined by the exact E action prompt. After about 75 seconds of free exploration without a new observation or mechanism change, Wick briefly points toward an unfinished lead and Kath gets a short objective reminder. H gives more detail only when requested. Turning optional hints off removes Wick's timed guidance and H hints, while the nearby object marks and E prompts remain available.

## Play route

1. **Grand Archive.** Inspect the library door, clock, and maintenance sheet. Record the machine-room gauge baseline. Return to the hall, follow the leak to the upper stacks, position the bucket and ladder, and recover Kath's torn `F = ma` page. In Kath's room, match its torn edge to her notebook, rest until morning, and pack the notebook.
2. **Alarm and service road.** Return to the hall for the alarm. In the machine room, operate levers 2 and 4 and stop the local drive; the distant castle wing becomes tilted. Follow the service road, inspect the hanging cable, open the gate, and enter the castle control walkway from the chapter card.
3. **On-site inversion.** At the control walkway, compare the dial with the visible wing and speak with Erin. The failed return test turns the wing to the separate inverted maintenance catch. Enter the lower passage. In the inverted room, optionally mark a prediction about which way is down at the chalk patch, then test it against falling water and the plumb weight. Inspect and climb the maintenance ladder.
4. **Rescue in the fixed shaft.** Contact Erin through the speaking tube, load tools from the safe platform, raise the basket, and let her open the bent upper rail. Bring the empty basket down, lock it, take the long rope, and rethread through the basket pulley. In the short empty test, compare the moving rope marks with the basket's rise and the changed winch rhythm. Raise and dock the empty basket again, then let Erin board. Take up slack, confirm the four load checks, release the upper catch, and lower her with measured braking. Lock the lower dock and use the loading spur to bring her onto the fixed platform.
5. **Restore the castle.** Enter the engine room with Erin. Inspect the chart, wet track, linkage, brake, and signal. Return to the chart to compare the fault sequence and choose a safe repair order. Isolate the automatic drive, remove the obstruction, test the home stop, brake, and lock, then hold Left at the maintenance drive to return the wing slowly to its normal position.
6. **Archive and ending.** Cross into the observatory. Open the shaken drawer and read its signed work record, Floating Isles comparison slip, and unexplained withdrawn page in any order. At the worktable, stitch the torn leaf into Kath's notebook. Return to Erin in the engine room for the final conversation and the Chapter I completion card. Enter or Esc closes the card and leaves the restored castle explorable.

Notes are added once in discovery order. Their observation thread places the machine reading, continuing roof leak, and torn page side by side without assigning a cause. The bucket changes the drops' landing place; it does not stop the rain. Esc cancels an unconfirmed document, inspection, or repair check. The game never assumes the cause of the original roof leak or the reason for a withdrawn record before evidence establishes it.

## Mechanical and physics continuity

The Archive's emergency levers unload and isolate its auxiliary line. The Castle has a separate ring motor and home-stop linkage; stopping the Archive drive cannot directly stop the Castle wing. The fixed tower and service core stay upright while one supported observatory wing rotates. On site, a jammed home rod is the leading explanation for the dark stop signal and missed brake: the ring motor runs past home, the separate inverted catch holds the wing, and the motor overload trips. The Castle feed is still connected until Kath and Erin use its own isolator. The route by which water reached the jammed track and any link to the Archive alarm remain unproven.

In the shaft, one fixed pulley redirects the pull; the alternate route has two strands supporting the basket. For the same empty basket, about two rope marks must be drawn in for one mark of lift. That geometry suggests an ideal pull advantage, while real hand force depends on friction and other losses. The load needle reads rope tension, not mass or weight directly. The final notebook treats `F = ma` as a testable guess about **net** force, mass, and acceleration under comparable conditions, based on the observed change in speed and braking distance.

## Prototype timing

`PrologueState` tracks active play time, excluding pause. When the first Chapter I completion card is reached, Godot prints `CHAPTER_I_PLAYTIME: mm:ss` in Output and stores the same timer fields in the checkpoint. This is an instrument for a fresh-player test, not a claim that the chapter already lasts a measured 25 minutes. The timing and review protocol is in `chapter1-assets/planning/phase3-step7-integration.md`.

## Project and checks

The design canvas is **1672×941** and the default window is **1280×720**, with aspect-preserving scaling. Kath's shared display height is **301.6 scene pixels** and Wick's is **130 scene pixels**; their shared scenes normalize their frames, so do not scale individual instances again. The reusable art source and game PNG layers are under `chapter1-assets/` and `prologue-asset-pack-v1/`.

Run the smoke scripts under `tests/` with Godot 4.7.2. The complete sequence includes `week1_smoke.gd` through `week6_smoke.gd`, `phase3_step1_smoke.gd` through `phase3_step6_smoke.gd` (including `phase3_step6a_smoke.gd`), `phase3_engine_restoration_smoke.gd`, `phase3_archive_finale_smoke.gd`, `phase3_step7_checkpoint_smoke.gd`, `phase3_step7_quit_smoke.gd`, and `stage6_settings_smoke.gd`. The save checks use dedicated temporary filenames and do not touch the player's slot.

For a repeatable Windows package, run `tools/build_windows_portable.ps1` with Godot 4.7.2 installed at `D:\Game\Godot-4.7.2` or pass its GUI executable path via `-GodotExe`. The script exports a PCK, pairs it with the engine, copies the engine notice and writes `build/FootnotesToTheWorld-Windows.zip`. Double-click `Play Footnotes.cmd` in the extracted folder. The package uses the installed Godot executable because dedicated Windows export templates are not installed on this development machine.

Asset provenance and the Godot notice are recorded in `docs/ASSET_SOURCES.md` and `GODOT_LICENSE.txt`. `docs/DEVELOPMENT_STATUS.md` identifies the current implementation and marks older planning notes as historical.
