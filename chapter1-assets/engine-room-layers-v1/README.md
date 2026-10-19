# Chapter I — Engine Room, Phase 2 step 6

Open `res://scenes/chapter1_engine_room_preview.tscn` directly in Godot. Walk Kath with A/D or left/right. Keys 1–4 show jammed, obstruction cleared, brake set and restored visual states. These are art previews, not the repair puzzle, and never write `PrologueState` or unlock the official Chapter I route.

The approved `../storybook-original-scenes-v1/04-engine-room.png` remains the composition reference. `clean-composite.png` is an edit source, not a game layer. In the Godot scene:

- `far-fixed-tower-clean.png` supplies the distant dawn exterior behind the open arch. It uses the cleaned painting so no original warning lamp or moving component leaks through transparent openings; the midground covers it everywhere else.
- `fixed-engine-room.png` carries the stationary floor, columns, ring, wall chart, pipes and device mounts. The moving devices and foreground rail were painted out and their backgrounds repaired.
- `front-guardrail.png` is the near railing and parapet that pass in front of Kath.
- `normal-linkage.png` and a dark travel-slot line show the normal-position transmission path. `jam-debris.png` is removable wet rubble blocking that path.
- `backup-lock.png` is bolted to a different right-hand support. The `brake-pawl.png` overlay drops into the independent `brake-wheel.png` after braking. `stop-signal.png` / `normal-signal.png` are separate status lamps.
- `distant-observatory-wing.png` rotates behind fixed architecture according to the preview pose. Its initial pose reads the shared `castle_pose`; preview keys can show inverted and restored views without mutating it.
- `service-threshold.png` frames the lower-service entry at the left and future restored-wing exit at the right. Marker nodes reserve the eventual spawn points; the formal story exit stays locked in this checkpoint.

The 1672×941 design canvas has a continuous walkable operator deck at foot y=725, x=115–1555, behind the foreground rail. Kath retains 301.6 px display height and Wick 130 px. The ring and fixed tower never rotate. The chart depicts the castle's rotating observatory/test-station purpose. English explanations and repair interactions will be rendered in Godot in the later gameplay phase; no functional labels are baked into these paintings.

All new bitmap layers were made with the built-in image-generation edit tool, using the approved engine-room painting as the composition/style target. The final prompt set was: remove the detachable rod, warning, brake, lock, jam and near rail while repairing their backgrounds; isolate fixed indoor architecture with transparent exterior openings; isolate the original near railing; extract the two normal-drive rods; create separate brass/red backup lock, brake gearbox, stop lamp and amber-normal lamp, loose wet rubble, a small engaged brake pawl, left/right service threshold and a distant movable observatory wing. Every prompt specified the same matte navy/slate and muted brass storybook palette, genuine alpha for cutouts, and no characters or baked gameplay text. `far-fixed-tower.png` is an unused unclean comparison plate; `far-fixed-tower-clean.png` is the actual far layer because it does not leak the source painting's red status lamp through the midground opening.
