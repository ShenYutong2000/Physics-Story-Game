extends Node2D
## Temporary Chapter I entrance, using the supplied control walkway illustration.

const SERVICE_ROAD_SCENE := "res://scenes/service_road.tscn"
const FLOOR_Y := 755.0

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var return_exit: Node2D = $ReturnExit
@onready var state: Node = get_node("/root/PrologueState")

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0


func _ready() -> void:
	state.take_spawn_tag()
	kath.floor_y = FLOOR_Y
	kath.floor_slope = 0.0
	kath.left_limit = 85.0
	kath.right_limit = 625.0
	kath.position = Vector2(430.0, FLOOR_Y)
	if not state.flags.get("control_walkway_intro_seen", false):
		state.flags["control_walkway_intro_seen"] = true
		_start_dialogue([
			"The control walkway is still standing. The supported wing is %s." % String(state.castle_pose),
			"The inner access is jammed. I'll inspect these controls before going farther."
		])


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	if return_exit.is_reachable(kath.position.x):
		ui.show_prompt("Service Road", return_exit.approach_x, "RETURN", FLOOR_Y - 430.0)
	else:
		ui.hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"paper":
			_set_mode(&"journal")
			_show_journal()
		else:
			_close_overlay()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			if return_exit.is_reachable(kath.position.x):
				_return_to_service_road()
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
	elif mode == &"paused" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_close_overlay()


func _return_to_service_road() -> void:
	_set_mode(&"travel")
	ui.hide_modals()
	state.travel_to(SERVICE_ROAD_SCENE, &"from-control-walkway")


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
		_close_overlay()


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
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"
