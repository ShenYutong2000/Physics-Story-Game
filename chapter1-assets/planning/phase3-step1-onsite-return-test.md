# Chapter I phase 3, step 1 — on-site return test

This is the first gameplay checkpoint after the five-room art shell. The regular project starts in the Library Hall and now reaches a playable incident in the Castle Control Walkway. The route into the inverted room remains the next checkpoint.

## Fast review

Open `res://scenes/chapter1_return_test_playtest.tscn` and run the current scene with F6. This developer-only launcher seeds the end-of-prologue conditions, a torn-page note and an open service gate, then loads the **same official Control Walkway scene**. It is not the project main scene or an alternate implementation of the event.

After the opening bubble, use A/D or left/right to approach Erin and press E, then inspect the dial with E. Complete each short exchange with Enter; Esc cancels a conversation without recording it. The return console on the right remains blocked until both observations are recorded. Press E there, complete the two-line exchange and watch Erin take the maintenance stair. The wing moves from its existing 12° tilt toward level, passes the home position and continues in the same direction until inverted. The fixed tower and ring do not rotate. When the aftermath dialogue closes, J opens the notes; the left-side E hotspot returns to the Service Road.

For the full route, launch the project normally and complete the prologue. The Chapter I card still enters this same scene. The F6 launcher is only a short acceptance path.

## State and continuity

- The return test requires the completed Archive incident, the `tilted` castle pose, Erin's completed briefing and Kath's completed dial observation. Individual notes use unique IDs.
- `control_return_test_started` prevents retriggering during the cutscene. `control_inversion_complete` is set only after the animation reaches its end; the shared pose then advances from `tilted` to `inverted`.
- Erin leaves the fixed deck via the visible stair and later answers from the inner maintenance ledge. On re-entry she stays off the fixed deck; the wing and dial read the shared inverted pose. Kath remains on a walkable fixed surface throughout.
- Back on the Service Road, the wing uses the same shared pose. Inspecting the cable after inversion adds a new observation instead of repeating the earlier tilted-wing claim. Existing older notes remain as records of what Kath saw before the test. Returning to the road end after the accident shows **E Enter Control Walkway** instead of replaying the Prologue Complete card.
- The fixed stair/bridge landing and a safe route into the rotating wing still need traversal art and collision before the next scene opens in the official story. This checkpoint ends with Kath deciding to find Erin another route.

## Verification

`res://tests/phase3_step1_smoke.gd` covers the console gate, dialogue cancellation, continuous animation, uninterruptible cutscene, fixed architecture, persistent pose, the updated road observation and control-deck re-entry. The existing week 1–6 and phase 2 step 3–8 smoke checks continue to pass.

Rendered captures are in `../review-phase3-step1/`: before the test at both supported window sizes, Erin on the stair and elevated bridge, the wing mid-turn, and the inverted aftermath at both supported window sizes. `res://tests/phase3_step1_capture.gd` regenerates them with a graphical Godot run.
