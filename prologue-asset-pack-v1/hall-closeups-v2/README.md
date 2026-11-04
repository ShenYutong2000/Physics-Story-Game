# Grand Archive Hall — close-up art and playable props

The archive door, high window, hall clock, and duty keys are now playable in the hall. The round book and optional prop sheets are art assets for the following steps. Open [the review viewer](review.html) to compare the proposed states at the design size (1672 × 941) or 1280 × 720. The viewer draws planned English headings and key lines as live text; the PNGs intentionally leave inscription areas blank so Godot can render the full final wording clearly.

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

## Playable close-ups (Steps 3–4)

In the hall, stand by the archive door or high window and press E to focus. Press E again to slide the bolt or press the catch; Esc returns to the hall. Esc before operating leaves that part unchanged. The latch or catch visibly changes in the close-up and on the room-scale fixture; the window rattle stops when the catch is fixed. The combined patrol item is recorded only after both parts are secured, in either order. Both close-ups reopen in their completed state after leaving and returning to the hall. The same focus scene supports left/right part selection for props with multiple actionable parts in later steps.

Live Godot captures at 1280 × 720: [hall before](review-captures/interactive-hall-before-1280x720.png) · [hall after](review-captures/interactive-hall-after-1280x720.png) · [door before](review-captures/interactive-door-before-1280x720.png) · [door after](review-captures/interactive-door-after-1280x720.png) · [window before](review-captures/interactive-window-before-1280x720.png) · [window after](review-captures/interactive-window-after-1280x720.png). Corresponding 1672 × 941 captures are in the same folder. The redesigned round book and other props remain for subsequent steps.

## Duty keys (Step 6)

Stand near the duty desk's key rack and press E. The close-up shows three keys: the machine-room and upper-stacks keys already hang on their hooks, while the east service key hangs on the spare nail. Press E to return that key to its labelled third hook. Its tag turns and reveals `OBSERVATORY CASTLE` in a readable magnified card. The rack changes in the hall and retains its arrangement after scene changes and checkpoint restore. Esc before moving the key leaves it unsorted; repeating the action cannot add a second note. The patrol-book completion gate still follows the existing three checks until Step 7 connects the redesigned checklist and stamp.

Live 1280 × 720 captures: [keys before](review-captures/interactive-keys-before-1280x720.png) · [keys after](review-captures/interactive-keys-after-1280x720.png) · [hall before](review-captures/interactive-keys-hall-before-1280x720.png) · [hall after](review-captures/interactive-keys-hall-after-1280x720.png). Matching 1672 × 941 captures are in the same folder.

## Hall clock (Step 5)

Stand by the clock and press E to focus. Hold E for about one second to wind it. Releasing E early keeps the visible spring progress; Esc can close and reopen the close-up without falsely completing the check. The handle and pendulum change in the close-up, while the room-scale handle turns and the pendulum and ticking settle into a regular rhythm. The completed state persists on later hall visits and produces only one journal entry. Review the live [unwound view](review-captures/interactive-clock-before-1280x720.png), [partial winding](review-captures/interactive-clock-partial-1280x720.png), [wound view](review-captures/interactive-clock-after-1280x720.png), and [hall after winding](review-captures/interactive-clock-hall-after-1280x720.png); 1672 × 941 versions are alongside them.
