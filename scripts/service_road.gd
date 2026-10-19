extends Node2D
## Walkable dawn route from the Archive machinery to the Observatory Castle.

const MACHINE_SCENE := "res://scenes/machine_room.tscn"
const CONTROL_WALKWAY_SCENE := "res://scenes/castle_control_walkway.tscn"
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-road.wav")
const GATE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/gate-latch.wav")
const PENCIL_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/pencil-write.wav")

const FLOOR_REFERENCE_X := 880.0
const FLOOR_REFERENCE_Y := 824.0
const FLOOR_SLOPE := 0.145
const ROAD_LEFT := 54.0
const ROAD_RIGHT := 1616.0
const CLOSED_GATE_LIMIT := 1210.0
const END_CARD_X := 1570.0

const ROAD_NOTES := {
	"service-road-sign": {
		"title": "Castle service sign",
		"body": "The maintenance way leads east from the Archive to the Observatory Castle."
	},
	"road-gravity-observation": {
		"title": "Cable and tilted wing",
		"body": "A loose service cable hangs toward the paving while the Castle's supported wing remains tilted in its ring. That is one observation from the road; the cause of the wing's position remains unknown."
	},
	"road-inverted-wing": {
		"title": "Cable and inverted wing",
		"body": "Back on the road after the return test, the loose cable still hangs toward the paving. The supported wing is now inverted inside the fixed ring."
	}
}

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var gate: AnimatedSprite2D = $ServiceGate/AnimatedSprite2D
@onready var castle_wing_pivot: Node2D = $CastleWingPivot
@onready var state: Node = get_node("/root/PrologueState")
@onready var hotspots: Array[Node] = [$MachineDoor, $RoadSign, $SlackCable, $ServiceGate]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_note_id: StringName = &""
var pending_note_title := ""
var pending_note_body := ""
var ambient_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer


func _ready() -> void:
	castle_wing_pivot.rotation = state.castle_pose_angle_radians()
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.floor_anchor_x = FLOOR_REFERENCE_X
	kath.floor_y = FLOOR_REFERENCE_Y
	kath.floor_slope = FLOOR_SLOPE
	kath.left_limit = ROAD_LEFT
	kath.right_limit = ROAD_RIGHT if state.flags.get("service_gate_open", false) else CLOSED_GATE_LIMIT
	if spawn_tag == &"from-machine-room":
		kath.position.x = 150.0
	elif spawn_tag == &"from-control-walkway":
		kath.position.x = 1510.0
	kath.position.y = kath.floor_height_at(kath.position.x)
	gate.frame = 1 if state.flags.get("service_gate_open", false) else 0

	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "ServiceRoadAmbience"
	ambient_player.stream = AMBIENCE
	ambient_player.volume_db = -15.0
	add_child(ambient_player)
	ambient_player.play()
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "ServiceRoadEffects"
	add_child(effects_player)

	if not state.flags.get("service_road_intro_seen", false):
		state.flags["service_road_intro_seen"] = true
		_start_dialogue(["The service road leads straight to the Observatory Castle.", "The fixed tower is upright. The wing inside the ring is still tilted."])


func _exit_tree() -> void:
	if is_instance_valid(ambient_player):
		ambient_player.stop()
	if is_instance_valid(effects_player):
		effects_player.stop()


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	if state.flags.get("service_gate_open", false) and kath.position.x >= END_CARD_X:
		if state.castle_pose == &"inverted" or state.castle_pose == &"restored":
			ui.show_prompt("Control Walkway", END_CARD_X, "ENTER", kath.position.y - 200.0)
		else:
			_show_chapter_end()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 420.0
	if closest == $MachineDoor:
		action = "RETURN"
		prompt_y = kath.position.y - 470.0
	elif closest == $ServiceGate:
		action = "OPEN GATE" if not state.flags.get("service_gate_open", false) else "GATE OPEN"
		prompt_y = kath.position.y - 170.0
	elif closest == $RoadSign:
		prompt_y = 650.0
	elif closest == $SlackCable:
		prompt_y = 490.0
	ui.show_prompt(closest.display_name, closest.approach_x, action, prompt_y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"chapter_end":
			_return_from_chapter_card()
		elif mode == &"paper":
			_set_mode(&"journal")
			_show_journal()
		elif mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"dialogue":
			_close_dialogue(false)
		else:
			_close_overlay()
		get_viewport().set_input_as_handled()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			if state.flags.get("service_gate_open", false) and kath.position.x >= END_CARD_X \
				and (state.castle_pose == &"inverted" or state.castle_pose == &"restored"):
				_set_mode(&"travel")
				ui.hide_modals()
				state.travel_to(CONTROL_WALKWAY_SCENE, &"from-service-road")
				return
			var closest: Node = nearest_hotspot(kath.position.x)
			if closest != null:
				_inspect(closest)
		elif event.is_action_pressed("toggle_journal"):
			_set_mode(&"journal")
			_show_journal()
			get_viewport().set_input_as_handled()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("toggle_journal"):
		_close_overlay()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
		_set_mode(&"paper")
		ui.show_torn_page(true)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_up"):
		ui.scroll_journal(-1)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_down"):
		ui.scroll_journal(1)
		get_viewport().set_input_as_handled()
	elif mode == &"chapter_end" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_set_mode(&"travel")
		ui.hide_modals()
		state.travel_to(CONTROL_WALKWAY_SCENE, &"from-service-road")
	elif mode == &"paused":
		if event.is_action_pressed("advance_dialogue"):
			_close_overlay()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
			get_tree().quit()


func nearest_hotspot(feet_x: float) -> Node:
	var best: Node = null
	var best_distance := INF
	for hotspot in hotspots:
		if not hotspot.is_reachable(feet_x):
			continue
		var distance: float = hotspot.distance_from(feet_x)
		if distance < best_distance:
			best = hotspot
			best_distance = distance
	return best


func _inspect(hotspot: Node) -> void:
	if hotspot == $MachineDoor:
		get_viewport().set_input_as_handled()
		state.travel_to(MACHINE_SCENE, &"from-service-road")
		return
	if hotspot == $RoadSign:
		_start_note_dialogue(&"service-road-sign", ["CASTLE SERVICE WAY →", "The old sign still points toward the Observatory."])
	elif hotspot == $SlackCable:
		wick.react_to(1480.0, 185.0)
		if state.castle_pose == &"inverted":
			_start_note_dialogue(&"road-inverted-wing", ["The cable still hangs toward the paving.", "The wing has turned over inside the fixed ring. I need to find Erin another route."])
		else:
			_start_note_dialogue(&"road-gravity-observation", ["The loose cable hangs toward the paving.", "The Castle wing is tilted. I should check what happens inside before drawing conclusions."])
	elif hotspot == $ServiceGate:
		if state.flags.get("service_gate_open", false):
			_start_dialogue(["The service gate is open. The road continues beyond it."])
		else:
			state.flags["service_gate_open"] = true
			gate.frame = 1
			kath.right_limit = ROAD_RIGHT
			_play_effect(GATE_SOUND)
			_start_dialogue(["The latch gives way.", "I can reach the Castle entrance now."])


func _start_note_dialogue(note_id: StringName, lines: Array[String]) -> void:
	pending_note_id = note_id
	var note: Dictionary = ROAD_NOTES[String(note_id)]
	pending_note_title = String(note["title"])
	pending_note_body = String(note["body"])
	_start_dialogue(lines)


func _start_dialogue(lines: Array[String]) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	_set_mode(&"dialogue")
	ui.show_dialogue(dialogue_lines[0], kath.global_position)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		ui.show_dialogue(dialogue_lines[dialogue_index], kath.global_position)
	else:
		_close_dialogue(true)


func _close_dialogue(completed: bool) -> void:
	ui.hide_modals()
	_set_mode(&"roam")
	if completed and pending_note_id != &"":
		if state.add_note_once(pending_note_id, pending_note_title, pending_note_body):
			_play_effect(PENCIL_SOUND)
	pending_note_id = &""
	pending_note_title = ""
	pending_note_body = ""


func _show_journal() -> void:
	ui.show_journal(
		state.notes,
		state.hall_checks_complete(),
		bool(state.flags.get("machine_baseline_recorded", false)),
		bool(state.flags.get("stacks_bucket_moved", false)),
		bool(state.flags.get("stacks_page_collected", false)),
		bool(state.flags.get("room_notebook_compared", false)),
		bool(state.flags.get("incident_complete", false)),
		state.room_preparation_complete(),
		bool(state.flags.get("machine_incident_active", false)),
		bool(state.flags.get("service_gate_open", false)),
		bool(state.flags.get("service_road_end_reached", false))
	)


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


func _close_overlay() -> void:
	ui.hide_modals()
	_set_mode(&"roam")


func _return_from_chapter_card() -> void:
	ui.hide_modals()
	kath.position.x = 1510.0
	kath.position.y = kath.floor_height_at(kath.position.x)
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _play_effect(stream: AudioStream) -> void:
	effects_player.stop()
	effects_player.stream = stream
	effects_player.play()
