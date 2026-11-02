# Phase 3 · Step 5 — Engine room restoration

## Formal route

After Erin reaches the shaft's fixed lower platform, the new **Engine Room** threshold at its right end opens. Kath can return to the shaft at any time. The fixed engine room's right passage stays misaligned until the wing is restored; afterward it leads to a walkable observatory entry with a return path. At that point the shaft's old low wing hatch no longer lines up and cannot reopen the upside-down room. The archive documents and next-region clue are reserved for the following story step.

## Play sequence

1. Inspect the orientation chart, wet obstruction, home linkage, brake and independent inverted catch, and stop signal. The order is free. Kath records observations, then compares the visible connections with Erin to identify a plausible fault chain. The source of the water remains unconfirmed.
2. At the isolator, disconnect the automatic drive. Only then clear the wet grit and loose fragment from the linkage track. The detached obstruction disappears from the scene, while the fixed architecture stays in place.
3. At the cleared linkage, perform an isolated dry run. Left/Right selects the home stop signal, brake pawl or normal-position lock; E checks the selected response. Enter commits only after all three are checked. Esc discards the pending checks. This test does not claim that the normal lock is holding the inverted wing.
4. At the maintenance drive, **hold Left** to return the wing slowly. Release Left to brake; Esc closes the panel and holds the current angle. The angle persists on a round trip to the shaft. At home, the stop signal changes, brake pawl seats, and normal lock engages. The shared `castle_pose` advances from `inverted` to `restored` only at this point.
5. Cross the reopened right passage into the observatory entry. E at its right side returns to the engine room. E at the drawers or telescope provides a short orientation line, while document investigation remains for the next step.

The journal keeps unique observations in discovery order and shows engine-room progress. The restored wing no longer appears as “Inverted” in the progress page.

## Checks

- `res://tests/phase3_engine_restoration_smoke.gd` covers rescue exit, order-independent investigation, Esc cancellation, repair gates, partial return persistence, restoration and observatory round trip.
- `res://tests/phase3_engine_restoration_capture.gd` is a graphical Godot capture script for five states at 1672×941 and 1280×720. It writes to `chapter1-assets/review-phase3-engine-restoration/`.
- Run the earlier week and phase-three smoke scripts after changes to the shared `HallUI` or shaft entrance.

This step uses the approved dark storybook layers. It does not move the fixed tower or assign an unverified numerical pressure or load to the mechanism.
