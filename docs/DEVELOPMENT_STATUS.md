# Current implementation and review scope

The playable route covers the prologue and Chapter I through the Observatory Castle archive. `README.md` is the current player and developer entry point. Files under `chapter1-assets/planning/` record historical checkpoints; their old key prompts, scene status and intended future work may predate the current implementation.

The current controls are E interact, H optional hint, J notes, Esc pause, and S settings while paused. The title screen also opens settings. The settings file is separate from the single story checkpoint.

The current art is maintained as separate PNG layers and Godot nodes, with the source mapping in `docs/ASSET_SOURCES.md`. A future paint change should retain its native layered source. The test scripts under `tests/` are the executable acceptance record; the Windows package is rebuilt with `tools/build_windows_portable.ps1`.

Open quality work: independent first-play timing and comprehension sessions, plus explicit clearance of every asset before a public commercial release. Automated tests and visual spot checks do not replace those reviews.
