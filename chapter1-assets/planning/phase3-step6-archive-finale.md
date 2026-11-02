# Phase 3 · Step 6 — Observatory archive and Chapter I finale

## Play route

From the restored engine room, enter the observatory through the right passage. Open the shaken drawer at the left desk. Its three pages may be read in any order with Left/Right; Enter records the current page, while Esc closes it without adding a note. A check mark marks pages already recorded. The telescope is optional and gives Kath a stable view of the fixed tower.

The pages establish distinct facts:

1. A **Grand Archive — Castle Observation Station** work record lists direction and basket tests, retains a crossed-out estimate, and bears Kath's and Erin's signatures. Its filing pattern matches the library.
2. The **Floating Isles — Buoyancy Station** was awaiting comparison results about airship chambers and floating platforms. The last exchange predates the **Night of Unnaming**.
3. A **WITHDRAWN** processing page has a blank reason field. Neither it nor the similar library page explains who withdrew the record or why.

Once all three are recorded, the worktable opens a close view of Kath's notebook. Enter stitches the `F = ma` leaf beside her new rope, load, braking and castle-stop observations. Esc leaves the leaf loose. Returning to Erin in the engine room unlocks the final conversation. She stays to maintain the castle and try to restore the station link; Kath chooses the unfinished Floating Isles comparison as her next lead. The **Chapter I Complete** card names that destination. Enter or Esc closes the card for free exploration of the finished prototype.

## State and presentation

`PrologueState` holds the drawer, individual page records, station inference, stitched page and one-time chapter completion. Notes are unique and retain discovery order across room trips. The formal archive is reachable only after `castle_pose == restored` and the engine repair flag is set. The existing stage-two art preview remains separate and does not affect story state.

The documents use the approved paper illustration with Godot-rendered English text. The work record, communication slip, withdrawn form, notebook spread and chapter card were reviewed at 1672×941 and 1280×720. The journal progress page now expands with the chapter's accumulated entries instead of clipping the later sections.

## Verification

- `res://tests/phase3_archive_finale_smoke.gd` checks order-independent reading, Esc cancellation, no duplicate notes, scene round trips, notebook confirmation, Erin's finale and card reopening.
- `res://tests/phase3_archive_finale_capture.gd` generates the five visual review states at both resolutions in `chapter1-assets/review-phase3-archive-finale/`.
- Earlier prologue, shaft rescue and engine restoration checks must continue to pass.

The Floating Isles is a named next destination on the chapter card; a playable second chapter is outside this step.
