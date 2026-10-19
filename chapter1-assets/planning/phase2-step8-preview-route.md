# Phase 2 step 8 — five-room art tour

Open `res://scenes/chapter1_scene_tour.tscn` directly in Godot and run that scene (F6). `project.godot` still starts the library hall; the official Chapter I route still stops at the control walkway.

| Preview order | Room | Left/previous E position | Right/next E position |
| --- | --- | ---: | ---: |
| 1 | Control Walkway | — | 590 |
| 2 | Inverted Room | 140 | 1410 |
| 3 | Maintenance Shaft, lower deck | 130 | 780 |
| 4 | Engine Room | 130 | 1515 |
| 5 | Observatory | 1510, by the right stair | — |

Use A/D or left/right to walk; a bottom prompt appears near a safe edge and E moves to the adjacent preview scene. Each transition places Kath away from the new scene's trigger, resets her velocity, and brings Wick to the same entry. The room instance stays cached so local art controls remain visible on return. Preview labels call these transitions **art-scene travel**: they do not assert that the bridge, rescue route or restored-wing exit is already physically usable in the story.

The control walkway has a preview subclass of the official scene. Its original art, Erin and depth layers are reused, but the story script is overridden before the scene runs. Keys 1–3 can display tilted, inverted and restored wing angles without writing `PrologueState.castle_pose`. The existing art controls remain available in the other rooms; the observatory document modal must be closed before leaving. The tour neither adds notes nor changes flags/spawn tags. Its detached room cache is explicitly freed when the tour closes.

`res://tests/phase2_step8_smoke.gd` verifies every E transition in both directions, safe foot positions, a single active room, local art-state preservation and story-state isolation. `res://tests/phase2_step8_capture.gd` produces review images in `../review-step8/`.
