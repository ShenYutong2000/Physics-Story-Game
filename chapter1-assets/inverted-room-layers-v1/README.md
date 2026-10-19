# Chapter I — Inverted Room, Phase 2 step 4

Open `res://scenes/chapter1_inverted_room_preview.tscn` directly in Godot to walk the art preview with A/D or the arrow keys. It is separate from the story route and does not add notes or change `PrologueState`.

The approved `02-inverted-room.png` is the composition reference. `clean-composite.png` is an intermediate repaint source; the final `room-shell.png` also removes the upper chandelier. The composite is not rendered in the scene. The game scene combines:

- `far-exterior.png`: distant fixed tower, support ring, mountains, rain, and sky.
- `room-shell.png`: transparent overturned architectural shell, windows, upper former floor, and continuous lower walking surface (the former ceiling).
- `front-parapet.png`: bottom near edge and gear silhouettes drawn above Kath.
- `split-water-pipe.png`, `falling-water.png`: separate source and downward leak/splash sprites.
- `plumb-chain.png`: detachable vertically hanging reference line; pointed weight faces screen down.
- `fallen-chair.png`, `fallen-chandelier.png`: loose furniture and the original ceiling fixture resting on the current lower floor. The chandelier was removed from the upper slab to avoid implying that gravity reversed.
- `wall-ladder.png`: separate fixed access ladder. Traversal is reserved for the later puzzle phase.

Scene coordinates use the 1672×941 design canvas. Kath's feet are at y=806, with a preview-safe x range of 100–1470. The room's lower stone surface is continuous within that range; the dark foreground covers its near edge. The visible distant tower belongs to the fixed structure; this interior belongs to the rotating wing. The water and suspended weight indicate ordinary gravity after the wing has inverted. No interactive gravity puzzle, climbing, or route from the Control Walkway is enabled in this art checkpoint.
