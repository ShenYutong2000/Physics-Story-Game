extends Node2D
## A short maintenance-room visit focused on recording a baseline observation.

const HALL_SCENE := "res://scenes/library_hall.tscn"
const ROUTE_NOTE := {
	"title": "Service route diagram",
	"body": "A service line connects the Library Hall machinery to the Observatory Castle."
}
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-machine.wav")
const PENCIL_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/pencil-write.wav")
const LEVER_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const STOP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/stop-switch.wav")
const DAWN_CITY: Texture2D = preload("res://prologue-asset-pack-v1/far/archive-dawn-city.png")

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var return_exit: Node2D = $ReturnToHall
@onready var service_road_exit: Node2D = $ServiceRoadExit
@onready var stop_hotspot: Node2D = $StopHotspot
@onready var far: Sprite2D = $Far
@onready var needle: Sprite2D = $Gauge/Needle
@onready var lever_two: AnimatedSprite2D = $LeverTwo
@onready var lever_four: AnimatedSprite2D = $LeverFour
@onready var lamp_one: AnimatedSprite2D = $StatusLampOne
@onready var lamp_two: AnimatedSprite2D = $StatusLampTwo
@onready var stop_switch: AnimatedSprite2D = $EmergencyStop
@onready var hotspots: Array[Node] = [$Gauge, $RouteDiagram, $ReturnToHall, $StopHotspot, $ServiceRoadExit]
@onready var state: Node = get_node("/root/PrologueState")

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_inspection: StringName = &""
var record_audio: AudioStreamPlayer
var incident_rebound_timer := -1.0
var selected_lever := 2
var incident_busy := false


func _ready() -> void:
	return_exit.exit_requested.connect(_on_exit_requested)
	service_road_exit.exit_requested.connect(_on_exit_requested)
	var spawn_tag: StringName = state.take_spawn_tag()
	if state.flags.get("dawn_reached", false):
		far.texture = DAWN_CITY
	if spawn_tag == &"from-hall":
		kath.position.x = 250.0
		if not state.flags.get("machine_intro_seen", false):
			state.flags["machine_intro_seen"] = true
			_start_dialogue(["No warning lamp. The upper needle is still below the red sector.", "I should compare it with yesterday's mark before I leave."])
	elif spawn_tag == &"from-service-road":
		kath.position.x = 1510.0
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
	_set_incident_visuals()
	if state.flags.get("machine_incident_active", false) \
		and not state.flags.get("incident_complete", false) \
		and not state.flags.get("machine_incident_intro_seen", false):
		state.flags["machine_incident_intro_seen"] = true
		_start_dialogue(["The pointer has crossed the red mark. The emergency card is still legible.", "Open return lever 2, isolate lever 4, then stop the local drive if the pointer keeps rising."])


func _exit_tree() -> void:
	if is_instance_valid(record_audio):
		record_audio.stop()
	var ambience := get_node_or_null("MachineRoomAmbience") as AudioStreamPlayer
	if ambience != null:
		ambience.stop()


func _process(_delta: float) -> void:
	if incident_rebound_timer >= 0.0 and mode != &"paused" and mode != &"dialogue" and not state.flags.get("incident_drive_stopped", false):
		incident_rebound_timer -= _delta
		if incident_rebound_timer <= 0.0:
			needle.rotation = -0.54
			state.flags["incident_needle_rebounded"] = true
			incident_rebound_timer = -1.0
			ui.show_hint("THE NEEDLE IS RISING AGAIN  ·  E  OPEN EMERGENCY STOP", 6.0)
	if mode != &"roam":
		ui.hide_prompt()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
	else:
		if closest == stop_hotspot and not _incident_active():
			ui.hide_prompt()
			return
		var action := "RETURN" if closest == return_exit else "INSPECT"
		var prompt_y := 415.0
		if closest == service_road_exit:
			if not state.flags.get("incident_complete", false):
				ui.show_prompt("Service road", closest.approach_x, "COMPLETE THE REPAIR", 415.0)
				return
			action = "EXIT TO ROAD"
			prompt_y = 415.0
		elif closest == stop_hotspot:
			action = "STOP DRIVE"
			prompt_y = 465.0
		elif closest.content_key == &"gauge":
			prompt_y = 142.0
			if _incident_active():
				action = "OPEN CONTROL CONSOLE"
		elif closest.content_key == &"route":
			prompt_y = 190.0
		ui.show_prompt(closest.display_name, closest.approach_x, action, prompt_y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"cutscene":
			get_viewport().set_input_as_handled()
			return
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"dialogue":
			_close_dialogue(false)
		elif mode == &"gauge":
			ui.hide_modals()
			_set_mode(&"roam")
		elif mode == &"console":
			ui.hide_modals()
			_set_mode(&"roam")
		elif mode == &"paper":
			_return_from_saved_page()
		else:
			_close_modal()
		get_viewport().set_input_as_handled()
		return
	if mode == &"console":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			selected_lever = 4 if selected_lever == 2 else 2
			_update_console()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			_operate_selected_lever()
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
		if hotspot == stop_hotspot and not _incident_active():
			continue
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
	if hotspot == service_road_exit:
		if not state.flags.get("incident_complete", false):
			_start_dialogue(["I should finish dealing with the machine before taking the service road."])
		else:
			service_road_exit.request_exit()
		return
	match hotspot.content_key:
		&"gauge":
			if _incident_active():
				selected_lever = 2 if not state.flags.get("incident_valve_two_open", false) else 4
				_set_mode(&"console")
				ui.show_emergency_console(bool(state.flags.get("incident_valve_two_open", false)), bool(state.flags.get("incident_valve_four_open", false)), bool(state.flags.get("incident_drive_stopped", false)), selected_lever)
			else:
				wick.react_to(1136.0, 310.0)
				_set_mode(&"gauge")
				ui.show_gauge_inspection(bool(state.flags.get("machine_baseline_recorded", false)))
		&"route":
			pending_inspection = &"service-route"
			_start_dialogue(["This line runs from the library machinery toward the Observatory Castle.", "I wonder what the two places were built to do together."])
		&"stop":
			if _incident_active():
				_operate_emergency_stop()
			else:
				_start_dialogue(["The emergency stop is released."])


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
	ui.show_journal(state.notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)), bool(state.flags.get("room_notebook_compared", false)), bool(state.flags.get("incident_complete", false)), state.room_preparation_complete(), bool(state.flags.get("machine_incident_active", false)))


func _return_from_saved_page() -> void:
	_set_mode(&"journal")
	_show_journal()


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _incident_active() -> bool:
	return bool(state.flags.get("machine_incident_active", false)) and not bool(state.flags.get("incident_complete", false))


func _set_incident_visuals() -> void:
	var active := _incident_active()
	lever_two.frame = 1 if state.flags.get("incident_valve_two_open", false) else 0
	lever_four.frame = 1 if state.flags.get("incident_valve_four_open", false) else 0
	lamp_one.frame = 0 if state.flags.get("incident_complete", false) else (2 if active else 1)
	lamp_two.frame = 0 if state.flags.get("incident_complete", false) else (2 if active else 1)
	stop_switch.frame = 1 if state.flags.get("incident_drive_stopped", false) else 0
	if active:
		needle.rotation = -0.54 if state.flags.get("incident_needle_rebounded", false) else (-1.29 if state.flags.get("incident_valve_two_open", false) or state.flags.get("incident_valve_four_open", false) else -0.76)
	elif state.flags.get("incident_complete", false):
		needle.rotation = -1.3


func _update_console() -> void:
	ui.update_emergency_console(bool(state.flags.get("incident_valve_two_open", false)), bool(state.flags.get("incident_valve_four_open", false)), bool(state.flags.get("incident_drive_stopped", false)), selected_lever)


func _operate_selected_lever() -> void:
	if selected_lever == 2 and not state.flags.get("incident_valve_two_open", false):
		state.flags["incident_valve_two_open"] = true
		lever_two.frame = 1
		needle.rotation = -1.29
		if not state.flags.get("incident_drive_stopped", false):
			incident_rebound_timer = 1.8
		_play_incident_sound(LEVER_SOUND)
	elif selected_lever == 4 and not state.flags.get("incident_valve_four_open", false):
		state.flags["incident_valve_four_open"] = true
		lever_four.frame = 1
		needle.rotation = -1.29
		if not state.flags.get("incident_drive_stopped", false):
			incident_rebound_timer = 1.8
		_play_incident_sound(LEVER_SOUND)
	selected_lever = 4 if not state.flags.get("incident_valve_four_open", false) else 2
	_update_console()
	if state.flags.get("incident_valve_two_open", false) and state.flags.get("incident_valve_four_open", false):
		state.flags["incident_valves_complete"] = true
		if state.flags.get("incident_drive_stopped", false):
			_complete_incident()
		else:
			ui.show_hint("THE NEEDLE DROPS, THEN RISES AGAIN  ·  STOP THE LOCAL DRIVE", 7.0)


func _operate_emergency_stop() -> void:
	if state.flags.get("incident_drive_stopped", false):
		return
	state.flags["incident_drive_stopped"] = true
	stop_switch.frame = 1
	incident_rebound_timer = -1.0
	_play_incident_sound(STOP_SOUND)
	if not state.flags.get("incident_valves_complete", false):
		_start_dialogue(["The local drive is stopped. The pressure trapped in this line still needs to be released."])
	else:
		_complete_incident()


func _complete_incident() -> void:
	if incident_busy or state.flags.get("incident_rotation_seen", false):
		return
	incident_busy = true
	state.flags["incident_rotation_started"] = true
	_set_mode(&"cutscene")
	ui.hide_modals()
	await ui.play_castle_rotation()
	state.flags["incident_rotation_seen"] = true
	state.flags["incident_complete"] = true
	state.add_note_once(&"castle-alarm", "The castle turned", "After the local drive stopped, the Observatory Castle's supported wing continued around the ring and came to rest upside down. The cause remains unknown.")
	incident_busy = false
	_set_mode(&"dialogue")
	_start_dialogue(["The local drive is quiet. The fixed tower stayed upright; only the supported wing turned.", "I don't know what failed at the castle. I can find out if I go there."])


func _play_incident_sound(stream: AudioStream) -> void:
	record_audio.stop()
	record_audio.stream = stream
	record_audio.play()


func _on_exit_requested(destination_scene: String, spawn_tag: String) -> void:
	state.flags["returned_from_machine_room"] = true
	state.travel_to(destination_scene if not destination_scene.is_empty() else HALL_SCENE, StringName(spawn_tag))
