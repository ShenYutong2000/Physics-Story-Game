# Erin — Chapter I checkpoint 2

Transparent character poses for the castle technician. Her short copper hair, work cap, rust scarf and tool belt distinguish her from Kath at game scale. Each pose is kept as a full-resolution source PNG; the reusable `res://scenes/erin.tscn` crops its nontransparent bounds at runtime and anchors the feet at the node origin.

- `idle.png` — neutral stance
- `walk-a.png`, `walk-b.png` — two-frame walking cycle
- `repair.png` — raised-wrench inspection pose

The Godot scene displays Erin at **308 px** high. Use `set_walking(bool)` and `set_repairing(bool)` to switch poses. Dialogue, rescue behavior and collision remain for later chapter implementation.

Open `res://scenes/chapter1_character_preview.tscn` to compare Erin with Kath and Wick against the approved dark control-walkway illustration. **A/D** moves Kath behind the sample foreground railing; **E** cycles Erin's poses. This review scene does not advance story state and is not the chapter entrance.

The sample railing, lamp, hatch frame, speaking tube, angle needle and exit marker are reusable vector variants in `res://scenes/castle_fixture.tscn`. They establish scale and placement; painted foreground layers and detached mechanisms are scheduled for the next scene-specific checkpoints.
