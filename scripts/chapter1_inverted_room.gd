extends Node2D
## First official route into the rotating wing: identify the real down direction.

const CONTROL_WALKWAY_SCENE := "res://scenes/castle_control_walkway.tscn"
const MAINTENANCE_SHAFT_SCENE := "res://scenes/chapter1_maintenance_shaft.tscn"
const FLOOR_Y := 806.0
const LADDER_X := 1510.0
const LADDER_TOP_Y := 475.0
const LADDER_FOOT_X := 1460.0
const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var falling_water: Sprite2D = $FallingWater
@onready var shaft_hatch_art: Sprite2D = $ShaftHatchArt
@onready var return_hatch: Node2D = $ReturnHatch
@onready var plumb_weight: Node2D = $PlumbWeight
@onready var water_path: Node2D = $WaterPath
@onready var fallen_furniture: Node2D = $FallenFurniture
@onready var shaft_ladder: Node2D = $ShaftLadder
@onready var state: Node = get_node("/root/PrologueState")
@onready var hotspots: Array[Node] = [return_hatch, plumb_weight, water_path, fallen_furniture, shaft_ladder]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_dialogue_action: StringName = &""
var drip_player: AudioStreamPlayer
var drip_elapsed := 0.0


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.floor_y = FLOOR_Y
	kath.floor_slope = 0.0
	kath.left_limit = 100.0
	kath.right_limit = 1470.0
	kath.position = Vector2(390.0, FLOOR_Y)
	shaft_hatch_art.visible = state.castle_pose == &"inverted"
	drip_player = AudioStreamPlayer.new()
	drip_player.stream = DRIP_SOUND
	drip_player.volume_db = -22.0
	add_child(drip_player)
	if state.castle_pose != &"inverted" or not state.flags.get("control_inversion_complete", false):
		_start_dialogue(["This passage is only safe after the wing has stopped moving. I should return to the fixed tower."])
	elif spawn_tag == &"from-maintenance-shaft":
		kath.begin_climbing(LADDER_X, LADDER_TOP_Y, FLOOR_Y, LADDER_TOP_Y)
		ui.show_hint("W/S climb down. E at the top returns to the shaft.", 4.0)
	elif not state.flags.get("inverted_room_intro_seen", false):
		state.flags["inverted_room_intro_seen"] = true
		_start_dialogue([
			"The fixed tower's lower duct runs through the ring's service hub. Its low hatch opens onto the turned wing's old ceiling.",
			"The stone beneath me used to be the ceiling. Before I cross, I need to check which way loose things actually fall."
		])
	elif state.flags.get("castle_down_confirmed", false):
		ui.show_hint("Follow the old ceiling toward the maintenance ladder.", 4.0)
	else:
		ui.show_hint("Compare the leaking water with the hanging weight.", 4.0)


func _process(delta: float) -> void:
	falling_water.modulate.a = 0.76 + sin(Time.get_ticks_msec() * 0.007) * 0.035
	drip_elapsed += delta
	if drip_elapsed >= 3.4:
		drip_elapsed = 0.0
		drip_player.play()
	if mode != &"roam":
		ui.hide_prompt()
		return
	if kath.locomotion_mode == &"climb":
		if kath.position.y >= FLOOR_Y - 1.0:
			_leave_ladder_at_foot()
		elif kath.position.y <= LADDER_TOP_Y + 18.0:
			ui.show_prompt("Shaft Hatch", 1300.0, "ENTER", 550.0)
			return
		else:
			ui.hide_prompt()
			return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 400.0
	if closest == return_hatch:
		action = "RETURN"
		prompt_y = 475.0
	elif closest == shaft_ladder:
		action = "CLIMB" if state.flags.get("room_ladder_checked", false) else "CHECK"
		prompt_y = 390.0
	ui.show_prompt(closest.display_name, closest.approach_x, action, prompt_y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		else:
			_close_overlay()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			if kath.locomotion_mode == &"climb":
				if kath.position.y <= LADDER_TOP_Y + 18.0:
					_set_mode(&"travel")
					ui.hide_modals()
					state.travel_to(MAINTENANCE_SHAFT_SCENE, &"from-inverted-room")
				return
			var closest: Node = nearest_hotspot(kath.position.x)
			if closest != null:
				_inspect(closest)
		elif event.is_action_pressed("toggle_journal"):
			get_viewport().set_input_as_handled()
			_set_mode(&"journal")
			_show_journal()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()
	elif mode == &"journal":
		if event.is_action_pressed("toggle_journal"):
			get_viewport().set_input_as_handled()
			_close_overlay()
		elif event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
			get_viewport().set_input_as_handled()
			_set_mode(&"paper")
			ui.show_torn_page(true)
		elif event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			ui.scroll_journal(-1)
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			ui.scroll_journal(1)
	elif mode == &"paper" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_set_mode(&"journal")
		_show_journal()
	elif mode == &"paused" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_close_overlay()


func nearest_hotspot(feet_x: float) -> Node:
	if kath.locomotion_mode == &"climb":
		return null
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
	if hotspot == return_hatch:
		_set_mode(&"travel")
		ui.hide_modals()
		state.travel_to(CONTROL_WALKWAY_SCENE, &"from-inverted-room")
		return
	if not state.flags.get("castle_down_confirmed", false) \
		and state.flags.get("room_water_observed", false) \
		and state.flags.get("room_plumb_observed", false) \
		and hotspot in [plumb_weight, water_path, shaft_ladder]:
		_start_down_comparison()
		return
	if hotspot == water_path:
		wick.react_to(888.0, 468.0)
		_start_dialogue([
			"The pipe broke above me, but its drops keep falling toward this stone ledge.",
			"The stream lands on what used to be the ceiling. I can trace its path with my eyes."
		], &"observe_water" if not state.flags.get("room_water_observed", false) else &"")
	elif hotspot == plumb_weight:
		wick.react_to(704.0, 600.0)
		_start_dialogue([
			"This weight hangs straight below its chain mount, toward the same ledge as the water.",
			"The mount moved with the room. The hanging direction did not."
		], &"observe_plumb" if not state.flags.get("room_plumb_observed", false) else &"")
	elif hotspot == fallen_furniture:
		_start_dialogue(["That chair slid from the old floor and stopped on the stone below me. I'll keep clear of the loose furniture."])
	elif hotspot == shaft_ladder:
		if state.castle_pose != &"inverted" or not state.flags.get("control_inversion_complete", false):
			_start_dialogue(["The wing must settle before this ladder is safe."])
		elif not state.flags.get("castle_down_confirmed", false):
			_start_dialogue(["The ladder runs toward the maintenance shaft, but I need to check this room's safe lower surface first."])
		elif not state.flags.get("room_ladder_checked", false):
			_start_dialogue([
				"The ladder bolts are still set in stone. This route leads on toward Erin's maintenance ledge.",
				"I'll mark this access and check the shaft before I climb with any load."
			], &"mark_ladder")
		else:
			kath.begin_climbing(LADDER_X, LADDER_TOP_Y, FLOOR_Y, FLOOR_Y - 30.0)
			ui.show_hint("W/S climb. E at the top enters the maintenance shaft.", 4.0)


func _leave_ladder_at_foot() -> void:
	kath.stop_climbing()
	kath.position = Vector2(LADDER_FOOT_X, FLOOR_Y)
	ui.show_hint("Back on the lower ledge.", 2.0)


func _start_down_comparison() -> void:
	_start_dialogue([
		"The room turned. Down stayed down.",
		"Both the drops and the weight point to the old ceiling under my feet. I can cross this ledge toward the maintenance ladder."
	], &"confirm_down")


func _start_dialogue(lines: Array[String], completion_action: StringName = &"") -> void:
	dialogue_lines = lines
	dialogue_index = 0
	pending_dialogue_action = completion_action
	_set_mode(&"dialogue")
	ui.show_dialogue(dialogue_lines[dialogue_index], kath.global_position)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		ui.show_dialogue(dialogue_lines[dialogue_index], kath.global_position)
		return
	var action := pending_dialogue_action
	_close_overlay()
	_complete_dialogue_action(action)


func _complete_dialogue_action(action: StringName) -> void:
	match action:
		&"observe_water":
			state.flags["room_water_observed"] = true
			state.add_note_once(&"castle-water-path", "Water in the turned room", "Water from the broken pipe falls onto the stone beneath Kath's feet. That surface was the room's ceiling before the wing turned.")
		&"observe_plumb":
			state.flags["room_plumb_observed"] = true
			state.add_note_once(&"castle-plumb-weight", "The hanging weight", "A weight on a chain points toward the same surface as the falling water. Its mount is attached to the turned room.")
		&"confirm_down":
			state.flags["castle_down_confirmed"] = true
			state.add_note_once(&"castle-down-confirmed", "The lower surface", "The wing rotated, but both the water and the hanging weight still point toward the same down direction. The old ceiling is now the safe lower ledge toward the maintenance ladder.")
			ui.show_hint("The lower ledge leads toward the maintenance ladder.", 4.0)
		&"mark_ladder":
			state.flags["room_ladder_checked"] = true
			state.add_note_once(&"castle-shaft-access", "Maintenance shaft access", "A wall ladder at the far end of the turned room leads toward Erin's maintenance ledge. Its stone anchors are visible; the shaft beyond still needs inspection.")
	if action in [&"observe_water", &"observe_plumb"] \
		and state.flags.get("room_water_observed", false) \
		and state.flags.get("room_plumb_observed", false) \
		and not state.flags.get("castle_down_confirmed", false):
		_start_down_comparison()


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


func _close_overlay() -> void:
	ui.hide_modals()
	pending_dialogue_action = &""
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"
