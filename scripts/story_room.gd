class_name StoryRoom
extends Node2D
## Shared exploration loop for every playable room.
##
## A room scene has Kath, Wick and HallUI children. Subclasses fill `hotspots`
## in `_ready()`, implement `_inspect()`, and override the hooks below only
## where the room differs:
##   _room_input(event)            room-specific modes; return true when handled
##   _cancel()                     Esc behaviour outside the shared modes
##   _interact()                   E while roaming (default: nearest hotspot)
##   _is_hotspot_available(node)   hide hotspots that are not usable yet
##   _complete_dialogue_action(id) follow-up after a finished dialogue
##   _close_saved_page()           leaving the torn page view

const PENCIL_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/pencil-write.wav")
const PRESTORM_CITY: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/archive-prestorm-city.png")
const RAIN_CITY: Texture2D = preload("res://prologue-asset-pack-v1/far/archive-night-city.png")
const DAWN_CITY: Texture2D = preload("res://prologue-asset-pack-v1/far/archive-dawn-city.png")
const HEAVY_RAIN_TINT := Color(0.76, 0.82, 0.94)

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var state: Node = get_node("/root/PrologueState")
@onready var settings: Node = get_node("/root/GameSettings")

## roam, dialogue, journal, paper, paused, travel, cutscene, or a room mode.
var mode: StringName = &"roam"
var hotspots: Array[Node] = []
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_speaker := Vector2.ZERO
var dialogue_by_kath := true
var pending_dialogue_action: StringName = &""
## Note recorded when the current dialogue is read to the end: {id, title, body}.
var pending_note: Dictionary = {}
var page_from_journal := false
var effects_player: AudioStreamPlayer


func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()


# --- Modes -------------------------------------------------------------------

func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _close_overlay() -> void:
	ui.hide_modals()
	pending_dialogue_action = &""
	pending_note = {}
	_set_mode(&"roam")


func _pause() -> void:
	_set_mode(&"paused")
	ui.show_pause()


func _travel(scene_path: String, spawn_tag: StringName) -> void:
	_set_mode(&"travel")
	ui.hide_modals()
	state.travel_to(scene_path, spawn_tag)


# --- Dialogue ----------------------------------------------------------------

## `speaker` places the bubble at another character; by default it is Kath.
func _start_dialogue(lines: Array[String], completion_action: StringName = &"", speaker := Vector2.ZERO) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_by_kath = speaker == Vector2.ZERO
	dialogue_speaker = kath.global_position if dialogue_by_kath else speaker
	pending_dialogue_action = completion_action
	_set_mode(&"dialogue")
	_show_dialogue_line()


## Show `lines`, then record the note once if the player reads to the end.
func _start_note_dialogue(note_id: StringName, title: String, body: String, lines: Array[String]) -> void:
	_start_dialogue(lines)
	pending_note = {"id": note_id, "title": title, "body": body}


func _show_dialogue_line() -> void:
	ui.show_dialogue(dialogue_lines[dialogue_index], dialogue_speaker)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_dialogue_line()
	else:
		_close_dialogue(true)


func _close_dialogue(completed: bool) -> void:
	var action := pending_dialogue_action
	var note := pending_note
	_close_overlay()
	if not completed:
		return
	if not note.is_empty() and state.add_note_once(note["id"], note["title"], note["body"]):
		_play_effect(PENCIL_SOUND)
	if action != &"":
		_complete_dialogue_action(action)


func _complete_dialogue_action(_action: StringName) -> void:
	pass


# --- Notes -------------------------------------------------------------------

func _open_journal() -> void:
	_set_mode(&"journal")
	_show_journal()


func _show_journal() -> void:
	ui.show_journal()


func _open_saved_page() -> void:
	page_from_journal = true
	_set_mode(&"paper")
	ui.show_torn_page(true)


func _close_saved_page() -> void:
	page_from_journal = false
	_open_journal()


# --- Hotspots ----------------------------------------------------------------

func nearest_hotspot(feet_x: float) -> Node:
	var best: Node = null
	var best_distance := INF
	for hotspot in hotspots:
		if not _is_hotspot_available(hotspot) or not hotspot.is_reachable(feet_x):
			continue
		var distance: float = hotspot.distance_from(feet_x)
		if distance < best_distance:
			best = hotspot
			best_distance = distance
	return best


func _is_hotspot_available(_hotspot: Node) -> bool:
	return true


func _interact() -> void:
	var closest := nearest_hotspot(kath.position.x)
	if closest != null:
		_inspect(closest)


func _inspect(_hotspot: Node) -> void:
	pass


# --- Archive weather -----------------------------------------------------------

## Match the city behind the Archive windows to the story's weather phase.
## Rooms first reached after the storm starts pass allow_prestorm = false.
func _apply_archive_weather(far: Sprite2D, rain: Node2D, allow_prestorm := true) -> void:
	var phase: StringName = state.weather_phase()
	if phase == &"prestorm" and not allow_prestorm:
		phase = &"rain"
	match phase:
		&"dawn":
			far.texture = DAWN_CITY
			far.modulate = Color.WHITE
			rain.set_strength(0.0)
		&"heavy":
			far.texture = RAIN_CITY
			far.modulate = HEAVY_RAIN_TINT
			rain.set_strength(1.0)
		&"rain":
			far.texture = RAIN_CITY
			far.modulate = Color.WHITE
			rain.set_strength(0.25)
		_:
			far.texture = PRESTORM_CITY
			far.modulate = Color.WHITE
			rain.set_strength(0.0)


# --- Audio -------------------------------------------------------------------

## Ambient players loop on the Ambience bus and start at once unless autoplay is false.
func _add_audio(player_name: String, stream: AudioStream, volume_db: float, ambient := false, autoplay := ambient) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	settings.configure_audio(player, ambient)
	player.name = player_name
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	if autoplay:
		player.play()
	return player


func _play_effect(stream: AudioStream, volume_db := 0.0) -> void:
	if effects_player == null:
		effects_player = _add_audio("Effects", null, 0.0)
	effects_player.stop()
	effects_player.stream = stream
	effects_player.volume_db = volume_db
	effects_player.play()


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	# Travel can remove this room from the tree while the event is handled.
	var viewport := get_viewport()
	if _room_input(event) or _shared_input(event):
		viewport.set_input_as_handled()


## Room-specific input, checked before the shared modes. Return true if used.
func _room_input(_event: InputEvent) -> bool:
	return false


func _shared_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		return true
	match mode:
		&"roam":
			if event.is_action_pressed("interact"):
				_interact()
				return true
			if event.is_action_pressed("toggle_journal"):
				_open_journal()
				return true
		&"dialogue":
			if event.is_action_pressed("advance_dialogue"):
				_advance_dialogue()
				return true
		&"journal":
			if event.is_action_pressed("toggle_journal"):
				_close_overlay()
				return true
			if event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
				_open_saved_page()
				return true
			if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
				ui.scroll_journal(-1 if event.is_action_pressed("move_up") else 1)
				return true
		&"paper":
			if event.is_action_pressed("advance_dialogue") or event.is_action_pressed("toggle_journal"):
				_close_saved_page()
				return true
		&"paused":
			if event.is_action_pressed("advance_dialogue"):
				_close_overlay()
				return true
			# PrologueState saves and quits first when persistence is on.
			if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
				get_tree().quit()
				return true
	return false


func _cancel() -> void:
	match mode:
		&"roam":
			_pause()
		&"dialogue":
			_close_dialogue(false)
		&"paper":
			_close_saved_page()
		&"cutscene", &"travel":
			pass
		_:
			_close_overlay()
