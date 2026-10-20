# Chapter I — Maintenance Shaft, Phase 2 step 5

Open `res://scenes/chapter1_maintenance_shaft_preview.tscn` directly in Godot. Kath walks with A/D or left/right arrows. In this art-only preview, E swaps the two rope arrangements, W/S moves the basket between upper and lower stops, and keys 1–4 show empty, tool, passenger and docked visual states. The preview never changes `PrologueState` or the official Chapter I route.

The approved `03-maintenance-shaft.png` is the composition reference. `clean-composite.png` is an unrendered repaint intermediate. Game layers are:

- `far-wheelworks.png`: distant fixed arcades, waterwheels, waterfalls and mist.
- `fixed-architecture.png`: transparent fixed walls, lower work platform, overhead beam and upper receiving ledge. Movable rigging and the upper rail were removed and the exposed background repaired.
- `front-occluders.png`: near masonry, short chains and the partial gear over the lower corners.
- Separate winch drum, brake lever, load indicator, upper fixed pulley, basket-mounted moving pulley, top rope anchor, basket, tool crate, loading spur, upper receiving rail and dock catches. The basket has closed and open-gate textures.

The rescue rig has two **independent Line2D paths**, not ropes baked into a backdrop. In the tool arrangement the line goes from the lower winch over the fixed pulley and directly to the basket eye. In the passenger arrangement the line goes from the winch over that fixed pulley, around the basket-mounted moving pulley and back to a separate top anchor; two segments support the basket. The scene script derives both paths from the same basket position, so lifting/lowering the basket does not leave the rope endpoints behind.

Geometry is measured on the 1672×941 canvas. Kath's safe lower walking surface is y=790, x=90–815; she cannot walk across the open shaft. Erin's upper ledge is y≈430. The basket at its high stop has floor y≈445 and right edge x≈1211, against the upper ledge beginning x≈1200. At the lower stop its floor is y≈790 and left edge x≈988, reached by a hinged loading spur ending near x≈1001. The separate upper rail and dock catches can change state later. Basket motion, loading, rescue, friction and brake failure are visual previews here; the actual puzzle remains for the later development phase.
