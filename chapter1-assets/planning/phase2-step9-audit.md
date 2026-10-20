# Phase 2 step 9 — five-scene acceptance audit

Run `res://scenes/chapter1_scene_tour.tscn` with F6 for the isolated art route. The project main scene remains `res://scenes/library_hall.tscn`; official play still ends at the Control Walkway. This audit does not unlock the on-site inversion or rescue.

## Review images

Each row has a 1672 × 941 design-canvas capture and a 1280 × 720 window capture in `../review-step9/`:

- Control Walkway: `01-control-walkway-1672x941.png`, `01-control-walkway-1280x720.png`
- Inverted Room: `02-inverted-room-1672x941.png`, `02-inverted-room-1280x720.png`
- Maintenance Shaft: `03-maintenance-shaft-1672x941.png`, `03-maintenance-shaft-1280x720.png`
- Engine Room: `04-engine-room-1672x941.png`, `04-engine-room-1280x720.png`
- Observatory: `05-observatory-1672x941.png`, `05-observatory-1280x720.png`

The review script is `res://tests/phase2_step9_capture.gd`. Because 1672:941 differs slightly from 16:9, Godot renders a 1279-pixel-wide content area in a 1280 × 720 window. The capture preserves that area and includes the one-pixel pillarbox instead of stretching the scene.

## Visual findings and corrections

- **Control Walkway:** Kath and Erin have distinct silhouettes and grounded feet. The near rail covers legs without covering faces. The control needle, fixed ring and rotating wing remain visually separate. The exterior wing is tilted in the default preview; the fixed tower is upright.
- **Inverted Room:** Kath stands on the former ceiling. Water drops, loose hanging items and the plumb cue all point to screen-down. The broken water path and near obstacles remain legible at the smaller window size.
- **Maintenance Shaft:** Kath's review position was moved left of the winch so her feet can be checked; walking behind the drum still gives the intended occlusion. The basket, upper ledge, fixed pulley, moving pulley and line route remain visible together. Erin stands on the higher receiving ledge.
- **Engine Room:** The rail passes in front of Kath at waist level. The repair controls are separable, and the exterior wing can show an inverted state while the fixed machinery remains upright.
- **Observatory:** Kath's feet align with the floor perspective, the telescope is a separate pivoting asset, and the desk/drawer has a legible interaction location. The art-tour hint now explains that page keys work while reading. No obvious doubled telescope or drawer appears in the render.

All five use the approved dark blue stone, aged brass and amber lighting direction. Character and HUD scale remain readable in both capture sizes; the shared Kath and Wick display heights remain 301.6 px and 130 px on the design canvas. Capture framing is for art review, not a claim that every painted connector is already playable.

## Import and regression

- Godot 4.7.2 `--headless --editor --import --quit`: exit 0; no missing resource or script parse errors.
- `week1_smoke.gd` through `week6_smoke.gd`: 6/6 passed.
- `phase2_step3_smoke.gd` through `phase2_step8_smoke.gd`: 6/6 passed.
- Ten review PNGs exist with the named dimensions; the five-room tour capture completed.

The sandboxed Godot process still logs failures to access the system certificate store, per-user log files and editor settings. These do not indicate a project resource failure; import, smoke tests and the rendered captures completed successfully.

## Remaining production dependencies

1. The Control Walkway bridge landing, the Inverted Room's lower exit, and the Engine Room/Observatory thresholds still need physically credible traversal geometry and final collision shapes before the formal Chapter I route opens. The art-tour E transitions deliberately stand in for those future connections.
2. The Observatory exterior is a repaired far plate, with selected transparent interior regions placed over it. The clean render avoids doubled props, but fully independent window parallax remains an art refinement if the later camera design needs it.
3. The separately exported PNG plates and Godot scenes are the editable layer sources currently delivered. A unified layered painting document is not yet present; keep the PNG layers and their README generation notes when revising art.
4. The inversion, gravity observation, pulley rescue, repair sequence and archive discovery are later gameplay milestones. Preview controls show artwork states only and must remain isolated from `PrologueState`.

Step 9 is ready for visual review. Do not begin the next development stage until this checkpoint is accepted.
