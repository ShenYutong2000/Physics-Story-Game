extends Node2D
## Official shaft shell. The pulley rig remains static until the rescue step.

const INVERTED_ROOM_SCENE := "res://scenes/chapter1_inverted_room.tscn"
const FLOOR_Y := 790.0

@onready var kath: CharacterBody2D = $Kath
@onready var ui: CanvasLayer = $HallUI
@onready var return_aperture: Node2D = $ReturnAperture
@onready var rope_shadow: Line2D = $RopeShadow
@onready var rope_core: Line2D = $RopeCore
@onready var state: Node = get_node("/root/PrologueState")

var mode: StringName = &"roam"


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.floor_y = FLOOR_Y
	kath.left_limit = 90.0
	kath.right_limit = 815.0
	kath.position = Vector2(300.0, FLOOR_Y)
	# The empty basket hangs on the original single run. No preview rig controls
	# are installed in this story scene.
	var rope_path := PackedVector2Array([
		Vector2(690, 665), Vector2(1028, 119), Vector2(1030, 98),
		Vector2(1042, 79), Vector2(1060, 72), Vector2(1080, 79),
		Vector2(1093, 99), Vector2(1095, 119), Vector2(1100, 625)
	])
	rope_shadow.points = rope_path
	rope_core.points = rope_path
	if spawn_tag == &"from-inverted-room" and not state.flags.get("shaft_intro_seen", false):
		state.flags["shaft_intro_seen"] = true
		_set_mode(&"dialogue")
		ui.show_dialogue("A short stair through the ring leads to this fixed platform. Erin is stranded across the shaft.", kath.global_position)


func _process(_delta: float) -> void:
	if mode != &"roam" or not return_aperture.is_reachable(kath.position.x):
		ui.hide_prompt()
		return
	ui.show_prompt(return_aperture.display_name, return_aperture.approach_x, "RETURN", 300.0)


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
			if return_aperture.is_reachable(kath.position.x):
				_set_mode(&"travel")
				ui.hide_modals()
				state.travel_to(INVERTED_ROOM_SCENE, &"from-maintenance-shaft")
		elif event.is_action_pressed("toggle_journal"):
			get_viewport().set_input_as_handled()
			_set_mode(&"journal")
			_show_journal()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_close_overlay()
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
