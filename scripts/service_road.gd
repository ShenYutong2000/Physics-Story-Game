extends StoryRoom
## Walkable dawn route from the Archive machinery to the Observatory Castle.

const MACHINE_SCENE := "res://scenes/machine_room.tscn"
const CONTROL_WALKWAY_SCENE := "res://scenes/castle_control_walkway.tscn"
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-road.wav")
const GATE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/gate-latch.wav")

const FLOOR_REFERENCE_X := 880.0
const FLOOR_REFERENCE_Y := 824.0
const FLOOR_SLOPE := 0.145
const ROAD_LEFT := 54.0
const ROAD_RIGHT := 1616.0
const CLOSED_GATE_LIMIT := 1210.0
const END_CARD_X := 1570.0

const ROAD_NOTES := {
	&"service-road-sign": {
		"title": "Castle service sign",
		"body": "The maintenance way leads east from the Archive to the Observatory Castle."
	},
	&"road-gravity-observation": {
		"title": "Cable and tilted wing",
		"body": "A loose service cable hangs toward the paving while the Castle's supported wing remains tilted in its ring. That is one observation from the road; the cause of the wing's position remains unknown."
	},
	&"road-inverted-wing": {
		"title": "Cable and inverted wing",
		"body": "Back on the road after the return test, the loose cable still hangs toward the paving. The supported wing is now inverted inside the fixed ring."
	}
}

@onready var gate: AnimatedSprite2D = $ServiceGate/AnimatedSprite2D
@onready var castle_wing_pivot: Node2D = $CastleWingPivot
@onready var machine_door: Node2D = $MachineDoor
@onready var road_sign: Node2D = $RoadSign
@onready var slack_cable: Node2D = $SlackCable
@onready var service_gate: Node2D = $ServiceGate


func _ready() -> void:
	hotspots = [machine_door, road_sign, slack_cable, service_gate]
	castle_wing_pivot.rotation = state.castle_pose_angle_radians()
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.floor_anchor_x = FLOOR_REFERENCE_X
	kath.floor_y = FLOOR_REFERENCE_Y
	kath.floor_slope = FLOOR_SLOPE
	kath.left_limit = ROAD_LEFT
	kath.right_limit = ROAD_RIGHT if _gate_open() else CLOSED_GATE_LIMIT
	if spawn_tag == &"from-machine-room":
		kath.position.x = 150.0
	elif spawn_tag == &"from-control-walkway":
		kath.position.x = 1510.0
	kath.position.y = kath.floor_height_at(kath.position.x)
	gate.frame = 1 if _gate_open() else 0
	_add_audio("ServiceRoadAmbience", AMBIENCE, -15.0, true)
	if not state.flags.get("service_road_intro_seen", false):
		state.flags["service_road_intro_seen"] = true
		_start_dialogue(["The service road leads straight to the Observatory Castle.", "The fixed tower is upright. The wing inside the ring is still tilted."])


func discovery_candidates() -> Array[Dictionary]:
	return [{"x": END_CARD_X, "position": Vector2(END_CARD_X, 555), "id": &"road-end"}] if _gate_open() else []


func _gate_open() -> bool:
	return bool(state.flags.get("service_gate_open", false))


func _at_castle_entrance() -> bool:
	return _gate_open() and kath.position.x >= END_CARD_X


func _castle_entrance_open() -> bool:
	return state.castle_pose == &"inverted" or state.castle_pose == &"restored"


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	if _at_castle_entrance():
		if _castle_entrance_open():
			ui.show_prompt("Control Walkway", END_CARD_X, "ENTER", kath.position.y - 200.0)
		else:
			_show_chapter_end()
		return
	var closest := nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 420.0
	if closest == machine_door:
		action = "RETURN"
		prompt_y = kath.position.y - 470.0
	elif closest == service_gate:
		action = "INSPECT" if _gate_open() else "OPEN GATE"
		prompt_y = kath.position.y - 170.0
	elif closest == road_sign:
		prompt_y = 650.0
	elif closest == slack_cable:
		prompt_y = 490.0
	ui.show_prompt(closest.display_name, closest.approach_x, action, prompt_y)


func _room_input(event: InputEvent) -> bool:
	if mode == &"chapter_end":
		if event.is_action_pressed("ui_cancel"):
			_return_from_chapter_card()
			return true
		if event.is_action_pressed("advance_dialogue"):
			_travel(CONTROL_WALKWAY_SCENE, &"from-service-road")
			return true
	return false


func _interact() -> void:
	if _at_castle_entrance() and _castle_entrance_open():
		_travel(CONTROL_WALKWAY_SCENE, &"from-service-road")
	else:
		super()


func _inspect(hotspot: Node) -> void:
	if hotspot == machine_door:
		state.travel_to(MACHINE_SCENE, &"from-service-road")
	elif hotspot == road_sign:
		_start_road_note(&"service-road-sign", ["CASTLE SERVICE WAY →", "The old sign still points toward the Observatory."])
	elif hotspot == slack_cable:
		wick.react_to(1480.0, 185.0)
		if state.castle_pose == &"inverted":
			_start_road_note(&"road-inverted-wing", ["The cable still hangs toward the paving.", "The wing has turned over inside the fixed ring. I need to find Erin another route."])
		else:
			_start_road_note(&"road-gravity-observation", ["The loose cable hangs toward the paving.", "The Castle wing is tilted. I should check what happens inside before drawing conclusions."])
	elif hotspot == service_gate:
		if _gate_open():
			_start_dialogue(["The service gate is open. The road continues beyond it."])
		else:
			state.flags["service_gate_open"] = true
			gate.frame = 1
			kath.right_limit = ROAD_RIGHT
			_play_effect(GATE_SOUND)
			_start_dialogue(["The latch gives way.", "I can reach the Castle entrance now."])


func _start_road_note(note_id: StringName, lines: Array[String]) -> void:
	var note: Dictionary = ROAD_NOTES[note_id]
	_start_note_dialogue(note_id, note["title"], note["body"], lines)


func _show_chapter_end() -> void:
	state.flags["service_road_end_reached"] = true
	if not state.flags.get("service_road_end_card_seen", false):
		state.flags["service_road_end_card_seen"] = true
		state.add_note_once(
			&"service-road-arrival",
			"At the Castle entrance",
			"The supported wing is %s inside the ring. I have reached the Castle's control walkway; the cause is still unknown." % String(state.castle_pose)
		)
		_start_dialogue(["The service road ends at the Observatory Castle.", "The wing is %s. The control walkway is the nearest way in." % String(state.castle_pose)])
		return
	_set_mode(&"chapter_end")
	ui.show_chapter_end()


func _return_from_chapter_card() -> void:
	ui.hide_modals()
	kath.position.x = 1510.0
	kath.position.y = kath.floor_height_at(kath.position.x)
	_set_mode(&"roam")
