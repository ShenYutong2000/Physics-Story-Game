# Phase 3 · Step 7 — Integrated prototype and playtest gate

## Delivered

- F5 now opens a title screen with New Game and a single-slot Continue. A second Enter is required to replace an existing journey.
- `PrologueState` stores scene checkpoint, castle pose, observation flags, unique notes in discovery order, total active seconds, and Chapter I start/finish times in `user://footnotes-chapter1-save.json` (schema version 1).
- Saving occurs at scene transitions, periodically during safe exploration, and immediately when pausing and pressing Q. Continue reconstructs the current room at a safe entry point; it does not restore exact Kath coordinates or an unconfirmed close view.
- The save loader rejects an unsupported version, unknown scene, missing resource, invalid pose, or missing core fields without altering the current session. Stage-two art-preview scenes are outside the save route.
- The pause screen says Save & Quit. The full route and updated controls are in the root README. The completion timer prints `CHAPTER_I_PLAYTIME: mm:ss` on a first real completion; pauses are excluded.

## Fresh-player timing pass

Start with **New Game**, without referring to a solution. Have a player speak aloud when a goal, entry point, or control is unclear. Use the console's `CHAPTER_I_PLAYTIME` for the chapter-only measurement; time the prologue separately if the showcase includes it. Target **about 25 minutes for Chapter I**, with a useful review band of roughly **22–28 minutes**. Do not add repeated walking or artificial waits merely to hit the target.

Record real timestamps at these milestones:

1. Enter castle control walkway and begin Chapter I.
2. Reach the inverted room and confirm downward direction.
3. Contact Erin and deliver the tool basket.
4. Finish the two-strand rethread and empty test.
5. Bring Erin to the fixed lower platform.
6. Restore the wing from the engine room.
7. Read all observatory records, repair the notebook, and reach the completion card.

Note the time spent stuck without a hypothesis, any ambiguous hotspot or hidden requirement, and whether the player understood the observed force/motion ideas from actions rather than from a lecture. If the run is short, add meaningful optional observations or character reactions; if long, clarify the blocking clue or shorten mechanical repetition. The target remains unverified until a fresh human run is timed.

## Acceptance and regression

- The formal route goes from library hall to the Chapter I card without using the stage-two preview menu. Restored castle, Erin rescue, archive documents, and final notebook flags remain coherent across backtracking.
- Pause, journal, document, winch, check panels, and chapter card never overlap. Esc cancels pending choices; Enter commits only the intended choice. E and Enter do not retrigger an interaction after a scene switch.
- Quit from the hall, shaft, engine room, and observatory; relaunch and Continue each time. The scene starts in a safe place, the journal has no duplicate entries, and rig/wing/drawer artwork matches the saved state.
- Confirm the new title at 1672×941 and 1280×720; confirm the final archive sheets, notebook, and chapter card at both sizes. No text overlaps or clipped controls.
- Run all week 1–6 and Phase 3 smoke scripts, including the engine restoration, archive finale, checkpoint, and pause-Q flush checks. `git diff --check` must pass. The developer should run one complete keyboard playthrough and log the real first-player time before declaring the 25-minute target met.

## Known boundary

The Floating Isles remains a story lead. There is no Chapter II scene yet. The checkpoint is a single slot and resumes at a safe room entrance, not at the exact frame of a moving mechanism.
