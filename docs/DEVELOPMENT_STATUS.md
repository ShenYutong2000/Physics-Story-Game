# Current implementation and review scope

The playable route covers the prologue and Chapter I through the Observatory Castle archive. `README.md` is the current player and developer entry point. Files under `chapter1-assets/planning/` record historical checkpoints; their old key prompts, scene status and intended future work may predate the current implementation.

The current controls are E interact, H optional hint, J notes, Esc pause, and S settings while paused. The title screen also opens settings. The settings file is separate from the single story checkpoint.

The current art is maintained as separate PNG layers and Godot nodes, with the source mapping in `docs/ASSET_SOURCES.md`. A future paint change should retain its native layered source. The test scripts under `tests/` are the executable acceptance record (`tools/run_tests.ps1` runs them all); the Windows package is rebuilt with `tools/build_windows_portable.ps1`. The export preset leaves review captures, planning notes and superseded art passes out of the game pack: `chapter1-assets/review-*`, `planning`, `prototype`, the source paintings in `castle-detail-pass-v1`, `castle-storybook-v1`, `storybook-original-scenes-v1`, `redesign-castle-v2` and `revised-dark-v1`, and `hall-closeups-v2/review-captures`. If a scene starts using one of those folders, remove it from `exclude_filter` in `export_presets.cfg`.

Open quality work: independent first-play timing and comprehension sessions, plus explicit clearance of every asset before a public commercial release. Automated tests and visual spot checks do not replace those reviews.
