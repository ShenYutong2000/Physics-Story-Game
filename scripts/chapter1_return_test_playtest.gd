extends Node
## F6-only checkpoint launcher. The regular main scene and story state are unchanged.

const CONTROL_WALKWAY := "res://scenes/castle_control_walkway.tscn"


func _ready() -> void:
	call_deferred("_launch")


func _launch() -> void:
	var state: Node = get_node("/root/PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.castle_pose = &"upright"
	state.transition_castle_pose(&"tilted")
	state.flags["incident_complete"] = true
	state.flags["stacks_page_collected"] = true
	state.flags["service_gate_open"] = true
	state.flags["service_road_intro_seen"] = true
	state.flags["service_road_end_reached"] = true
	state.flags["service_road_end_card_seen"] = true
	state.add_note_once(
		&"newton-note",
		"A torn page from my notebook",
		"F = ma. Beneath it is an unfinished sketch of a maintenance basket, marked for another Castle visit."
	)
	state.travel_to(CONTROL_WALKWAY, &"from-service-road")
