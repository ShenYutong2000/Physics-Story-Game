# Chapter I control walkway — phase 2, checkpoint 3

The approved dark storybook illustration in `../storybook-original-scenes-v1/01-control-walkway.png` is the composition reference. These PNGs are the editable raster sources used by `res://scenes/castle_control_walkway.tscn`:

- `far-landscape.png`: rainy mountain, forest and city backdrop.
- `tower-and-bridge.png`: transparent control tower, floor, stair and elevated bridge; the dial and support ring have been removed from this plate.
- `support-ring.png`: stationary ring and right-side support columns.
- `control-dial.png`: fixed semicircular dial face and gear housing.
- `rotating-wing.png`: transparent castle building only; Godot rotates it behind the fixed ring.
- `dial-needle.png`: detached control pointer.
- `short-guardrail.png`: front railing in Kath's walkable span.
- `front-parapet.png`: dark near-edge foreground.

The eight game layers and one intermediate plate were produced with the built-in imagegen edit tool from the approved painting. The selected prompt set requested: reveal the distant rainy landscape; isolate the fixed tower and bridge; isolate the stationary support ring; isolate the fixed dial without its pointer; isolate the castle building without the ring; isolate the dial pointer; isolate the short guardrail; and isolate the very-near bottom parapet. Intermediate edits removed the wing, railing, dial and pointer from their underlying plates and repainted the exposed stone or landscape. The original concept remains untouched.

The source painting shows a **12° tilted** wing. `castle_control_walkway.gd` subtracts those 12° from the shared castle-pose angle so the painted tilt lines up at the prologue ending. The fixed ring remains a stationary scene node. The smaller dial is a bounded status display, so its pointer indicates each pose within the visible arc instead of spinning through 180°. `PrologueState` still owns progression; this art checkpoint does not add the on-site inversion or any route across the bridge.

The dial face, needle, support ring and rotating building are separate Godot nodes. The bridge is still part of the stationary tower plate; its crossing threshold and other moving controls are reserved for later gameplay checkpoints. The separate `short-guardrail.png` covers Kath's legs when she walks behind it. The near bottom parapet covers only the edge of the picture. `fixed-architecture.png` is an intermediate extracted plate kept as an editable source of the unsplit fixed structures.
