# Chapter I — Observatory, Phase 2 step 7

Open `res://scenes/chapter1_observatory_preview.tscn` directly in Godot. Walk with A/D or left/right. At the archive desk, press E to pull out the drawer and E again to inspect the papers; 1–3 selects a page and Esc/Enter closes it. At the telescope, E changes the optical tube's angle. These are **visual/legibility previews**, not Chapter I puzzle or story events. They do not modify `PrologueState`.

The approved `../storybook-original-scenes-v1/05-observatory.png` is the composition and palette reference. The scene depicts the **restored rotating wing**, reached in the future from the engine-room side at the existing right stair. `RestoredWingEntry` is a reserved marker, not an enabled exit. The distant Floating Isles are an exterior clue, not a claim that this room is floating. The floor is at y=820, with Kath limited to x=155–1530; Kath and Wick retain the shared 301.6 px / 130 px heights.

## Game layers and changeable props

- `far-restored-exterior.png`: repaired source painting with upright distant castle and open view. It provides the far plate and underpainting so no holes appear at window edges.
- `fixed-interior-alpha.png`: transparent fixed architecture. The scene uses its archival wall/desk and floor regions above the far plate. The full cutout is kept as an editable source; its intricate window edges contain generated color fringes, so those regions are not rendered over the far plate.
- `front-parapet.png`: transparent near-edge stone/wood silhouette that can pass in front of Kath.
- `telescope-tube.png`: independent optical tube; the brass floor mount remains fixed. Only the tube pivot changes angle.
- `open-drawer.png`: independent pulled-out drawer over the desk's closed cabinet painting.
- `blank-archive-sheet.png`: reusable empty paper artwork. The three English pages are rendered by Godot Labels, not baked into the image: a signed work record, Floating Isles comparison slip, and withdrawn explanation. The text is placeholder narrative copy for later script integration.

The observatory has no official route from the current control walkway. Its pre-restoration inverted exterior is intentionally not shown as an upright room; that view will require a separately composed, rotated-wing shot if later gameplay exposes it. The preview always shows the post-restoration visit without changing the shared castle pose.

## Generation record

All new bitmap assets were produced with the built-in `image_gen` edit tool, using the approved observatory painting as reference. The final prompt set requested: (1) a faithful dark storybook observatory plate with only the telescope tube, loose papers, drawer front, and near-edge parapet removed and the backgrounds repaired; (2) a transparent extraction of the diagonal navy/brass telescope tube and controls; (3) a transparent near-edge parapet; (4) a transparent fixed architecture cutout with outdoor arch openings; (5) a single open walnut/brass archive drawer; and (6) a blank, worn cream document sheet for engine-rendered English. Every prompt excluded characters, UI and baked text and retained the muted navy/slate and aged-brass palette. A second edge-cleanup pass on the architecture cutout was rejected because it increased chromatic fringes; the original cutout is used only in clean regions.
