# Chapter I · Inverted Room observation checkpoint

This checkpoint opens the official story route from the fixed Control Walkway after the on-site inversion. Kath uses the visible lower hatch and the enclosed service duct through the support-ring hub, then enters the wing at its former ceiling. The old elevated bridge remains disconnected. The new entrance art is isolated from the original scene layers and only appears after `control_inversion_complete`.

Inside the room, the player can walk on the continuous old-ceiling ledge, return through the hatch, inspect the falling water and the hanging weight in either order, compare the two observations, examine loose furniture, and mark the maintenance ladder as the next route. The observation only identifies the direction objects fall and a safe walking surface; it does not claim to explain the castle fault. The shaft is a later playable checkpoint.

`castle_down_confirmed`, `room_water_observed`, `room_plumb_observed`, and `room_ladder_checked` persist in `PrologueState` for this run. Dialogue actions record notes only after Enter advances through the final line. Esc cancels without committing, and each note ID is unique. The Phase 2 art preview remains separate.

Run `res://tests/phase3_step2_smoke.gd` for the route and cancellation checks. Run `res://tests/phase3_step2_capture.gd` with graphical Godot to refresh the 1672×941 and 1280×720 images in `../review-phase3-step2/`.

## Added art

The two transparent PNGs in `../story-route-v1/` were generated with the built-in image tool and composited as Godot sprites, leaving the approved room and control illustrations intact.

- `fixed-tower-lower-hatch.png` prompt: “Transparent side-view storybook sprite of a compact riveted dark iron and aged brass maintenance hatch, three-step stone landing, guardrail and descending stair; match the dark navy wet-steam castle control walkway reference; no people, text, other scenery or background.”
- `wing-lower-entry.png` prompt: “Transparent side-view storybook sprite of a low masonry maintenance passage on the old ceiling, narrow brass frame, shadowed connecting steps and muted amber light; match the approved inverted-room reference; no people, text, sky or background.”

The final scale and placement were checked with Kath at her canonical 301.6 px height and Wick at 130 px. These are narrative transition hatches; Kath stoops through them between scenes. The ladder to the maintenance shaft is visible and inspectable but not climbable in this checkpoint.
