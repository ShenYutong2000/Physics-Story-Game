extends StoryRoom
## Archive maintenance room: record the gauge baseline, later handle the alarm.

const HALL_SCENE := "res://scenes/library_hall.tscn"
const ROUTE_NOTE := {
	"title": "Service route diagram",
	"body": "The Archive auxiliary line and a separate status wire run toward the Observatory Castle. The diagram also marks a local ring drive and isolator at the Castle; this panel does not directly switch that motor."
}
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-machine.wav")
const LEVER_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const STOP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/stop-switch.wav")
const MACHINE_SOUND_DB := -8.0
const NEEDLE_RISING := -0.76
const NEEDLE_REBOUND := -0.54
const NEEDLE_UNLOADED := -1.29
const NEEDLE_RESTED := -1.3
const REBOUND_SECONDS := 1.8

@onready var return_exit: Node2D = $ReturnToHall
@onready var service_road_exit: Node2D = $ServiceRoadExit
@onready var stop_hotspot: Node2D = $StopHotspot
@onready var far: Sprite2D = $Far
@onready var rain_streaks: Node2D = $RainStreaks
@onready var needle: Sprite2D = $Gauge/Needle
@onready var lever_two: AnimatedSprite2D = $LeverTwo
@onready var lever_four: AnimatedSprite2D = $LeverFour
@onready var lamp_one: AnimatedSprite2D = $StatusLampOne
@onready var lamp_two: AnimatedSprite2D = $StatusLampTwo
@onready var stop_switch: AnimatedSprite2D = $EmergencyStop

var incident_rebound_timer := -1.0
var selected_lever := 2
var incident_busy := false


func _ready() -> void:
	hotspots = [$Gauge, $RouteDiagram, return_exit, stop_hotspot, service_road_exit]
	return_exit.exit_requested.connect(_on_exit_requested)
	service_road_exit.exit_requested.connect(_on_exit_requested)
	var spawn_tag: StringName = state.take_spawn_tag()
	if not _flag("dawn_reached"):
		state.flags["hall_rain_started"] = true
	_apply_archive_weather(far, rain_streaks)
	_add_audio("MachineRoomAmbience", AMBIENCE, -14.0, true)
	kath.position.x = 1510.0 if spawn_tag == &"from-service-road" else 250.0
	if spawn_tag == &"from-hall" and not _flag("machine_intro_seen"):
		state.flags["machine_intro_seen"] = true
		_start_dialogue(["Rain is tapping the vents. No warning lamp; the upper needle is still below red.", "I should compare it with yesterday's mark before I leave."])
	_set_incident_visuals()
	if _incident_active() and not _flag("machine_incident_intro_seen"):
		state.flags["machine_incident_intro_seen"] = true
		_start_dialogue(["The pointer has crossed the red mark. The emergency card is still legible.", "Open return lever 2, isolate lever 4, then stop the local drive if the pointer keeps rising."])


func _flag(key: String) -> bool:
	return bool(state.flags.get(key, false))


func _incident_active() -> bool:
	return _flag("machine_incident_active") and not _flag("incident_complete")


func _is_hotspot_available(hotspot: Node) -> bool:
	return hotspot != stop_hotspot or _incident_active()


func _process(delta: float) -> void:
	if incident_rebound_timer >= 0.0 and mode not in [&"paused", &"dialogue"] and not _flag("incident_drive_stopped"):
		incident_rebound_timer -= delta
		if incident_rebound_timer <= 0.0:
			needle.rotation = NEEDLE_REBOUND
			state.flags["incident_needle_rebounded"] = true
			incident_rebound_timer = -1.0
			ui.show_hint("THE NEEDLE IS RISING AGAIN  ·  E  OPEN EMERGENCY STOP", 6.0)
	var closest := nearest_hotspot(kath.position.x) if mode == &"roam" else null
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 415.0
	if closest == return_exit:
		action = "RETURN"
	elif closest == service_road_exit:
		action = "EXIT TO ROAD" if _flag("incident_complete") else "COMPLETE THE REPAIR"
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


func _room_input(event: InputEvent) -> bool:
	match mode:
		&"console":
			if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
				selected_lever = 4 if selected_lever == 2 else 2
				_update_console()
				return true
			if event.is_action_pressed("interact"):
				_operate_selected_lever()
				return true
		&"gauge":
			if event.is_action_pressed("advance_dialogue"):
				_confirm_gauge_reading()
				return true
	return false


func _inspect(hotspot: Node) -> void:
	if hotspot == return_exit:
		return_exit.request_exit()
		return
	if hotspot == service_road_exit:
		if _flag("incident_complete"):
			service_road_exit.request_exit()
		else:
			_start_dialogue(["I should finish dealing with the machine before taking the service road."])
		return
	match hotspot.content_key:
		&"gauge":
			if _incident_active():
				selected_lever = 4 if _flag("incident_valve_two_open") else 2
				_set_mode(&"console")
				ui.show_emergency_console(_flag("incident_valve_two_open"), _flag("incident_valve_four_open"), _flag("incident_drive_stopped"), selected_lever)
			else:
				wick.react_to(1136.0, 310.0)
				_set_mode(&"gauge")
				ui.show_gauge_inspection(_flag("machine_baseline_recorded"))
		&"route":
			_start_note_dialogue(&"service-route", ROUTE_NOTE["title"], ROUTE_NOTE["body"], [
				"Two lines lead toward the Observatory Castle: an Archive auxiliary line and a status wire.",
				"The diagram marks a separate ring drive inside the Castle. This stop switch belongs to the Archive side; I still don't know whether the faults are related.",
			])
		&"stop":
			if _incident_active():
				_operate_emergency_stop()
			else:
				_start_dialogue(["The emergency stop is released."])


func _confirm_gauge_reading() -> void:
	ui.hide_modals()
	if _flag("machine_baseline_recorded"):
		_set_mode(&"roam")
		return
	state.add_note_once(&"machine-reading", "Machine-room reading", "The needle rests one division above the previous mark, still below the red sector.")
	state.flags["machine_baseline_recorded"] = true
	_play_effect(PENCIL_SOUND, MACHINE_SOUND_DB)
	_start_dialogue(["One division higher than the last mark. Still below the red sector.", "I've written down what I can see. I don't know what the scale measures."])


func _set_incident_visuals() -> void:
	var active := _incident_active()
	var complete := _flag("incident_complete")
	lever_two.frame = 1 if _flag("incident_valve_two_open") else 0
	lever_four.frame = 1 if _flag("incident_valve_four_open") else 0
	lamp_one.frame = 0 if complete else (2 if active else 1)
	lamp_two.frame = lamp_one.frame
	stop_switch.frame = 1 if _flag("incident_drive_stopped") else 0
	if active:
		if _flag("incident_needle_rebounded"):
			needle.rotation = NEEDLE_REBOUND
		elif _flag("incident_valve_two_open") or _flag("incident_valve_four_open"):
			needle.rotation = NEEDLE_UNLOADED
		else:
			needle.rotation = NEEDLE_RISING
	elif complete:
		needle.rotation = NEEDLE_RESTED


func _update_console() -> void:
	ui.update_emergency_console(_flag("incident_valve_two_open"), _flag("incident_valve_four_open"), _flag("incident_drive_stopped"), selected_lever)


func _operate_selected_lever() -> void:
	if selected_lever == 2:
		_open_valve("incident_valve_two_open", lever_two)
	else:
		_open_valve("incident_valve_four_open", lever_four)
	selected_lever = 2 if _flag("incident_valve_four_open") else 4
	_update_console()
	if _flag("incident_valve_two_open") and _flag("incident_valve_four_open"):
		state.flags["incident_valves_complete"] = true
		if _flag("incident_drive_stopped"):
			_complete_incident()
		else:
			ui.show_hint("THE NEEDLE DROPS, THEN RISES AGAIN  ·  STOP THE LOCAL DRIVE", 7.0)


## Opening either relief lever unloads the needle briefly until the drive stops.
func _open_valve(flag: String, lever: AnimatedSprite2D) -> void:
	if _flag(flag):
		return
	state.flags[flag] = true
	lever.frame = 1
	needle.rotation = NEEDLE_UNLOADED
	if not _flag("incident_drive_stopped"):
		incident_rebound_timer = REBOUND_SECONDS
	_play_effect(LEVER_SOUND, MACHINE_SOUND_DB)


func _operate_emergency_stop() -> void:
	if _flag("incident_drive_stopped"):
		return
	state.flags["incident_drive_stopped"] = true
	stop_switch.frame = 1
	incident_rebound_timer = -1.0
	_play_effect(STOP_SOUND, MACHINE_SOUND_DB)
	if _flag("incident_valves_complete"):
		_complete_incident()
	else:
		_start_dialogue(["The Archive drive is stopped. The emergency card still calls for levers 2 and 4 to unload and isolate this line."])


func _complete_incident() -> void:
	if incident_busy or _flag("incident_tilt_observed"):
		return
	incident_busy = true
	state.flags["incident_tilt_started"] = true
	_set_mode(&"cutscene")
	ui.hide_modals()
	await ui.play_castle_tilt()
	incident_busy = false
	if not state.transition_castle_pose(&"tilted"):
		_set_mode(&"roam")
		return
	state.flags["incident_tilt_observed"] = true
	state.flags["incident_complete"] = true
	state.add_note_once(&"castle-alarm", "Remote tilt observed", "The Archive auxiliary drive and line were stopped and isolated. The Castle's status signal remained unstable, and its supported wing tilted about 12 degrees while the fixed tower stayed upright. The Castle has its own ring drive; I do not yet know whether these failures share a cause.")
	_start_dialogue(["The Archive auxiliary drive is stopped, but the Castle's status signal still behaves abnormally.", "The fixed tower stayed upright while the supported wing tilted. Its ring drive is separate; I can't tell whether the two failures are connected."])


func _on_exit_requested(destination_scene: String, spawn_tag: String) -> void:
	state.flags["returned_from_machine_room"] = true
	var destination := HALL_SCENE if destination_scene.is_empty() else destination_scene
	if destination == HALL_SCENE and _flag("machine_baseline_recorded") and not _flag("dawn_reached"):
		state.flags["hall_rain_heavy"] = true
	state.travel_to(destination, StringName(spawn_tag))
