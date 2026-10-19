# Chapter I darker scene direction — review set 1

These five **new 1672 × 941 composite scene concepts** replace the earlier bright castle images as the proposed visual basis for Chapter I. They are intentionally not connected to the Godot rooms yet: each moving prop and foreground occluder still needs clean extraction, background repair, and scene-specific collision placement after the art direction is approved. The playable first-stage Control Walkway continues using its existing temporary art.

## Shared direction

- A storm-dark Observatory Castle rather than the prologue's inviting archive: charcoal-indigo stone, blackened riveted iron, tarnished brass, rain-wet paving and exposed service mechanisms.
- Light comes from selective amber gaslamps, gray dawn through storm cloud, small teal instrument lights and sparing red emergency indicators. Keep the player foot plane and key mechanisms brighter than unused corners.
- Fixed tower, service frame and engine room remain upright. The supported wing is about 12° tilted in the Control Walkway image; the Inverted Room represents the later 180° state; the Observatory represents the restored state.
- All images are unpopulated backgrounds. Kath, Wick and Erin remain separate game actors. There is no baked game UI or readable document text.

## Scene roles

1. `01-control-walkway.png` — exposed fixed deck, raised bridge and tilted wing; the new staircase/landing offers an architectural basis for future access.
2. `02-inverted-room.png` — colder enclosed room; old floor above, stable old ceiling below, water and plumb line both point down.
3. `03-maintenance-shaft.png` — deep fixed industrial frame, low winch platform, separated upper ledge, suspended basket and two pulley locations.
4. `04-engine-room.png` — sooty mechanism hall with a blocked normal-position linkage and distinct red warning devices.
5. `05-observatory.png` — restored upright research room; the storm begins to open while the interior retains the chapter's dark material palette.

## Items to resolve during layer production

- The generated scenes are flattened. Inpainting and manual paint cleanup are required after moving the wing, ropes, basket, drops, levers, telescope, drawers and foreground rails to independent alpha layers.
- The shaft ropes are **visual concepts**, not an approved final reeving diagram. Draw tool and passenger configurations from the chapter's mechanical sequence before implementing the puzzle.
- A few small astronomical decorations and exterior architectural details are atmospheric. Treat only separately specified mechanism layers and Godot-rendered labels as reliable information for gameplay.
- Re-measure foot lines and exits from this new art. The annotated layouts in `../planning/layouts/` describe the previous references and are superseded for pixel positions.
