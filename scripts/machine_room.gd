extends Node2D
## A short maintenance-room visit focused on recording a baseline observation.

const HALL_SCENE := "res://scenes/library_hall.tscn"
const ROUTE_NOTE := {
	"title": "Service route diagram",
	"body": "A service line connects the Library Hall machinery to the Observatory Castle."
}
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-machine.wav")
const PENCIL_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/pencil-write.wav")

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var return_exit: Node2D = $ReturnToHall
@onready var hotspots: Array[Node] = [$Gauge, $RouteDiagram, $ReturnToHall]
@onready var state: Node = get_node("/root/PrologueState")

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_inspection: StringName = &""
var record_audio: AudioStreamPlayer


func _ready() -> void:
	return_exit.exit_requested.connect(_on_exit_requested)
	var spawn_tag: StringName = state.take_spawn_tag()
	if spawn_tag == &"from-hall":
		kath.position.x = 250.0
		if not state.flags.get("machine_intro_seen", false):
			state.flags["machine_intro_seen"] = true
			_start_dialogue(["No warning lamp. The upper needle is still below the red sector.", "I should compare it with yesterday's mark before I leave."])
	else:
		kath.position.x = 250.0
	var ambience := AudioStreamPlayer.new()
	ambience.name = "MachineRoomAmbience"
	ambience.stream = AMBIENCE
	ambience.volume_db = -14.0
	add_child(ambience)
	ambience.play()
	record_audio = AudioStreamPlayer.new()
	record_audio.name = "RecordAudio"
	record_audio.stream = PENCIL_SOUND
	record_audio.volume_db = -8.0
	add_child(record_audio)


func _exit_tree() -> void:
	if is_instance_valid(record_audio):
		record_audio.stop()
	var ambience := get_node_or_null("MachineRoomAmbience") as AudioStreamPlayer
	if ambience != null:
		ambience.stop()


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
	else:
		var action := "RETURN" if closest == return_exit else "INSPECT"
		var prompt_y := 415.0
		if closest.content_key == &"gauge":
			prompt_y = 142.0
		elif closest.content_key == &"route":
			prompt_y = 190.0
		ui.show_prompt(closest.display_name, closest.approach_x, action, prompt_y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"dialogue":
			_close_dialogue(false)
		elif mode == &"gauge":
			ui.hide_modals()
			_set_mode(&"roam")
		elif mode == &"paper":
			_return_from_saved_page()
		else:
			_close_modal()
		get_viewport().set_input_as_handled()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			# Returning to the hall removes this scene immediately.
			get_viewport().set_input_as_handled()
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
	elif mode == &"gauge" and event.is_action_pressed("advance_dialogue"):
		_confirm_gauge_reading()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("toggle_journal"):
		_close_modal()
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
	elif mode == &"paper" and (event.is_action_pressed("advance_dialogue") or event.is_action_pressed("toggle_journal")):
		_return_from_saved_page()
		get_viewport().set_input_as_handled()
	elif mode == &"paused":
		if event.is_action_pressed("advance_dialogue"):
			_close_modal()
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
	if hotspot == return_exit:
		return_exit.request_exit()
		return
	match hotspot.content_key:
		&"gauge":
			wick.react_to(1136.0, 310.0)
			_set_mode(&"gauge")
			ui.show_gauge_inspection(bool(state.flags.get("machine_baseline_recorded", false)))
		&"route":
			pending_inspection = &"service-route"
			_start_dialogue(["This line runs from the library machinery toward the Observatory Castle.", "I wonder what the two places were built to do together."])


func _confirm_gauge_reading() -> void:
	ui.hide_modals()
	if not state.flags.get("machine_baseline_recorded", false):
		state.add_note_once(&"machine-reading", "Machine-room reading", "The needle rests one division above the previous mark, still below the red sector.")
		state.flags["machine_baseline_recorded"] = true
		record_audio.play()
		_start_dialogue(["One division higher than the last mark. Still below the red sector.", "I've written down what I can see. I don't know what the scale measures."])
	else:
		_set_mode(&"roam")


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
	var inspected_id := pending_inspection
	pending_inspection = &""
	_close_modal()
	if completed and inspected_id == &"service-route":
		state.add_note_once(&"service-route", ROUTE_NOTE["title"], ROUTE_NOTE["body"])


func _close_modal() -> void:
	if mode == &"dialogue":
		pending_inspection = &""
	ui.hide_modals()
	_set_mode(&"roam")


func _show_journal() -> void:
	ui.show_journal(state.notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)))


func _return_from_saved_page() -> void:
	_set_mode(&"journal")
	_show_journal()


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _on_exit_requested(destination_scene: String, spawn_tag: String) -> void:
	state.flags["returned_from_machine_room"] = true
	state.travel_to(destination_scene if not destination_scene.is_empty() else HALL_SCENE, StringName(spawn_tag))
