# Grand Archive Hall — close-up art review (step 2)

The archive-door close-up is now playable in the hall as the Step 3 reference interaction. The other prop sheets are art assets for the following steps. Open [the review viewer](review.html) to compare the proposed states at the design size (1672 × 941) or 1280 × 720. The viewer draws planned English headings and key lines as live text; the PNGs intentionally leave inscription areas blank so Godot can render the full final wording clearly.

## Scene and main props

- [Pre-storm skyline](archive-prestorm-city.png): replaces the rainy far layer only when the story is still before the first rain. The original rainy far layer remains available for the later weather state.
- [Door latch: open / secured](door-latch-states.png), with [sliding bolt layer](layer-door-bolt.png).
- [Window catch: loose / fixed](window-catch-states.png), with [pivoting catch layer](layer-window-catch.png).
- [Hall clock winding close-up: unwound / wound](clock-winding-detail-states.png), [full clock view](hall-clock-states.png), [crank layer](layer-clock-crank.png), and [pendulum layer](layer-clock-pendulum.png).
- [Duty keys: temporary nail / correct hook](duty-keys-states.png), with [east key layer](layer-east-key.png).
- [Readable round-book page: checklist / filed blank page](round-book-page-states.png), [readable emergency page](round-book-emergency-page.png), [full book view for the page turn](round-book-states.png), and [stamp layer](layer-round-stamp.png).

## Optional finds

- [Old plaque: dusty / wiped](old-plaque-states.png).
- [Clock cover: closed / open](clock-inner-cover-states.png).
- [Catalogue card: front / reverse](catalogue-card-states.png).

## Import notes

Each `*-states.png` is a two-column sheet. The left half is the initial state and the right half is the changed state. In Godot, use an `AtlasTexture` region for each half; the exact pixel widths are listed in [asset manifest](manifest.json). The separately generated `layer-*.png` files have actual alpha transparency and can be animated over the state art. Their proportions need final placement against the chosen atlas half during the next implementation step.

The labels `MACHINE ROOM`, `UPPER STACKS`, `EAST SERVICE WAY`, the book tasks, `ROUND FILED`, the emergency instructions, and the archive/catalogue text belong in Godot `Label` nodes. Do not bake generated lettering into the textures. The review viewer includes the planned text at both target sizes.

The art sheets are concept-quality production candidates. Their state changes and palette were checked visually; final alignment of moving pieces, sound timing, and the room-level persistent variants are part of later implementation steps.

## Godot capture examples

The [capture script](../../tests/hall_art_capture.gd) renders the art with live English text in the project's existing 16:9 scaling mode. It produced a before and after frame for all five main props at both sizes. Useful starting points:

- [Opening hall, 1672 × 941](review-captures/00-hall-prestorm-1672x941.png) · [1280 × 720](review-captures/00-hall-prestorm-1280x720.png)
- [Door before](review-captures/door-before-1280x720.png) · [after](review-captures/door-after-1280x720.png)
- [Window before](review-captures/window-before-1280x720.png) · [after](review-captures/window-after-1280x720.png)
- [Clock before](review-captures/clock-before-1280x720.png) · [after](review-captures/clock-after-1280x720.png)
- [Keys before](review-captures/keys-before-1280x720.png) · [after](review-captures/keys-after-1280x720.png)
- [Round book before](review-captures/book-before-1280x720.png) · [after](review-captures/book-after-1280x720.png) · [emergency page](review-captures/emergency-page-1280x720.png)

## Playable close-up reference (Step 3)

In the hall, stand by the archive door and press E to focus on the latch. Press E again to slide the bolt; Esc returns to the hall. Esc before operating leaves the door unchecked. On a later visit, the close-up reopens in its secured state. The same focus scene supports left/right part selection for props with multiple actionable parts in later steps. The live Godot captures show the playable [before](review-captures/interactive-door-before-1280x720.png) and [after](review-captures/interactive-door-after-1280x720.png) views at 1280 × 720; corresponding 1672 × 941 captures are in the same folder. The hall-scale latch art update and the full door/window checklist gate are scheduled for Step 4.
