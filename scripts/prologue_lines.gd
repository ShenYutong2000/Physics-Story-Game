extends RefCounted
## Kath's prologue lines by Dialogue ID.
## Source of truth: docs/prologue/Kath_Prologue_Dialogue_Lines_v1_3.csv
## (tests/prologue_lines_test.gd checks that this table matches the CSV).

const LINES := {
	# S01 — Hall
	"D00": "I'd better find tonight's page before I begin.",
	"D02b": "There you are, tucked between yesterday's pages.",
	"D01": "Evening again. The light leaves the hall so quietly.",
	"D02": "Three small things to set right before the rain.",
	"D03": "That should hold. The wind loves finding little gaps.",
	"D04": "The sky is restless tonight. This window can rest.",
	"D05": "One more turn, and the old clock keeps its steady song.",
	"D06": "Third hook, as always. Even the little clink sounds familiar.",
	"D07": "Three small marks, and another evening folded away.",
	"O01": "Warm inside... yet the glass carries the evening chill.",
	"O02": "The pendulum comes back. The hands keep moving on.",
	"O03": "The brass is worn smooth. Whose hands held it before mine?",
	"D00_EXIT": "The rounds aren't filed yet. One thing at a time.",
	# S02 — Machine Room
	"D08": "A little higher than yesterday. Still below red.",
	"D09": "I'll draw where it is, not where I expected it to be.",
	"D10": "A route to the Observatory Castle.",
	"D11": "That sound... is it coming from upstairs?",
	# S03 — Top Library
	"D12": "Oh, no. The books.",
	"D13": "Why is it still hanging there?",
	"D14": "It seems faster near the floor. Why?",
	"D15": "The roof is slanted, but the drop falls almost straight down.",
	"D16": "It fell down. What sent those little drops up?",
	"D17": "That one fell sooner.",
	"D18": "Wait... I want to see that again.",
	"D19": "I can draw what happened. I still need to find out why.",
	"D20": "I wrote this. I know I did.",
	"D21": "Why would I keep a wrong mark?",
	"D22": "I drew what I saw tonight. The questions can stay beside it.",
	# S04 — Kath's Room
	"D23": "The torn edge fits. I took this page out of my own notebook.",
	"D24": "I was due back at the castle. I don't remember what I meant to check.",
	"D25": "I'll leave these notes here. Tomorrow I may notice something I missed.",
	# S05 — Alarm
	"D26": "That alarm is from the machine room. The needle was below red last night.",
	"D27": "I have a mark to compare it with.",
	"D28": "It was below the red line yesterday. Now it's over.",
	"D29": "Two and four. The needle fell... and now it's climbing again.",
	"D30": "The Archive drive is stopped.",
	"D31": "The upper lift must stay out of use.",
	"D32": "The fixed tower is still upright... but the wing isn't.",
	"D33": "I'll record what I saw. Someone at the castle may know what to check there.",
	# S06 — Maintenance Road
	"D34": "The fixed tower is upright. The wing isn't.",
	"D35": "One hanging cable tells me where it falls here. I still need to see what happened inside.",
	"D36": "I came for an answer. I'll start with what I can check.",
}


static func text(id: String) -> String:
	if not LINES.has(id):
		push_error("Unknown prologue line '%s'." % id)
		return ""
	return LINES[id]
