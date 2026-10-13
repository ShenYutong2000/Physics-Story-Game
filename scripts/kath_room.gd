extends Node2D
## Notebook comparison, rest, and departure preparation.

const UPPER_SCENE := "res://scenes/upper_stacks.tscn"
const DAWN_CITY: Texture2D = preload("res://prologue-asset-pack-v1/far/archive-dawn-city.png")
const NIGHT_CITY: Texture2D = preload("res://prologue-asset-pack-v1/far/archive-night-city.png")
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-room.wav")
const PAGE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")
const PENCIL_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/pencil-write.wav")

const DOOR_X := 100.0
const DOOR_REACH := 94.0
const LAMP_X := 1281.0
const LAMP_REACH := 75.0
const NOTEBOOK_X := 1028.0
const NOTEBOOK_REACH := 75.0
const BED_X := 560.0
const BED_REACH := 55.0
const BAG_X := 646.0
const BAG_REACH := 55.0
const COAT_X := 881.0
const COAT_REACH := 55.0

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var far: Sprite2D = $Far
@onready var night_tint: CanvasModulate = $NightTint
@onready var lamp: AnimatedSprite2D = $DeskLamp
@onready var satchel: AnimatedSprite2D = $Satchel
@onready var state: Node = get_node("/root/PrologueState")

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var ambient_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer
var page_from_journal := false


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.position = Vector2(210.0, 801.0)
	if spawn_tag == &"from-upper-stacks":
		kath.position.x = 210.0
	far.texture = DAWN_CITY if state.flags.get("dawn_reached", false) else NIGHT_CITY
	if state.flags.get("room_lamp_on", false):
		lamp.frame = 1
	if state.flags.get("room_bag_packed", false):
		satchel.frame = 1
	if state.flags.get("dawn_reached", false):
		night_tint.color = Color.WHITE
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "RoomAmbience"
	ambient_player.stream = AMBIENCE
	ambient_player.volume_db = -16.0
	add_child(ambient_player)
	ambient_player.play()
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "RoomEffects"
	add_child(effects_player)
	if not state.flags.get("room_intro_seen", false):
		state.flags["room_intro_seen"] = true
		_start_dialogue(["My room. I must have hidden that page here before the Night of Unnaming.", "First, the desk lamp. Then I can compare it with the notebook I kept."])


func _exit_tree() -> void:
	if is_instance_valid(ambient_player):
		ambient_player.stop()
	if is_instance_valid(effects_player):
		effects_player.stop()


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	var x := kath.position.x
	var name := ""
	var action := "INSPECT"
	var target_x := x
	if absf(x - DOOR_X) <= DOOR_REACH:
		name = "Stairway to Upper Stacks"
		action = "RETURN"
		target_x = DOOR_X
	elif absf(x - LAMP_X) <= LAMP_REACH and not state.flags.get("room_lamp_on", false):
		name = "Desk lamp"
		action = "TURN ON"
		target_x = LAMP_X
	elif absf(x - NOTEBOOK_X) <= NOTEBOOK_REACH and not state.flags.get("room_notebook_compared", false):
		name = "Old notebook"
		action = "COMPARE PAGE" if state.flags.get("room_lamp_on", false) else "TURN ON LAMP FIRST"
		target_x = NOTEBOOK_X
	elif absf(x - BED_X) <= BED_REACH and not state.flags.get("room_rested", false):
		name = "Bed"
		action = "REST UNTIL MORNING" if state.flags.get("room_notebook_compared", false) else "COMPARE THE PAGE FIRST"
		target_x = BED_X
	elif absf(x - BAG_X) <= BAG_REACH and not state.flags.get("room_bag_packed", false):
		name = "Travel satchel"
		action = "PACK NOTEBOOK" if state.flags.get("dawn_reached", false) else "WAIT FOR DAWN"
		target_x = BAG_X
	elif absf(x - COAT_X) <= COAT_REACH:
		name = "Hanging coat"
		action = "INSPECT"
		target_x = COAT_X
	if name.is_empty():
		ui.hide_prompt()
	else:
		ui.show_prompt(name, target_x, action, 540.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"dialogue":
			_close_dialogue(false)
		elif mode == &"paper":
			_return_to_journal()
		else:
			_close_overlay()
		get_viewport().set_input_as_handled()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_interact()
		elif event.is_action_pressed("toggle_journal"):
			_set_mode(&"journal")
			_show_journal()
			get_viewport().set_input_as_handled()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()
	elif mode == &"comparison" and event.is_action_pressed("advance_dialogue"):
		_commit_comparison()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("toggle_journal"):
		_close_overlay()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_up"):
		ui.scroll_journal(-1)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_down"):
		ui.scroll_journal(1)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
		page_from_journal = true
		_set_mode(&"paper")
		ui.show_torn_page(true)
		get_viewport().set_input_as_handled()
	elif mode == &"paper" and (event.is_action_pressed("advance_dialogue") or event.is_action_pressed("toggle_journal")):
		_return_to_journal()
		get_viewport().set_input_as_handled()
	elif mode == &"paused" and event.is_action_pressed("advance_dialogue"):
		_close_overlay()
		get_viewport().set_input_as_handled()
	elif mode == &"paused" and event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		get_tree().quit()


func _interact() -> void:
	var x := kath.position.x
	if absf(x - DOOR_X) <= DOOR_REACH:
		state.flags["prologue_departure_ready"] = state.room_preparation_complete()
		state.travel_to(UPPER_SCENE, &"from-kath-room")
		return
	if absf(x - LAMP_X) <= LAMP_REACH and not state.flags.get("room_lamp_on", false):
		state.flags["room_lamp_on"] = true
		lamp.frame = 1
		_play_effect(PAGE_SOUND)
		_start_dialogue(["There. I can read the pencil marks now."])
		return
	if absf(x - NOTEBOOK_X) <= NOTEBOOK_REACH and not state.flags.get("room_notebook_compared", false):
		if not state.flags.get("room_lamp_on", false):
			_start_dialogue(["Too dark to compare the page. I should light the desk lamp."])
			return
		_set_mode(&"comparison")
		ui.show_notebook_comparison()
		_play_effect(PAGE_SOUND)
		return
	if absf(x - BED_X) <= BED_REACH and not state.flags.get("room_rested", false):
		if not state.flags.get("room_notebook_compared", false):
			_start_dialogue(["I need to find out whether this page belongs in my notebook first."])
			return
		state.flags["room_rested"] = true
		state.flags["dawn_reached"] = true
		far.texture = DAWN_CITY
		var dawn_tween := create_tween()
		dawn_tween.tween_property(night_tint, "color", Color.WHITE, 1.8)
		_play_effect(PAGE_SOUND)
		_start_dialogue(["I must have fallen asleep over my notes.", "Morning already. The castle entry is still waiting in my notebook."])
		return
	if absf(x - BAG_X) <= BAG_REACH and not state.flags.get("room_bag_packed", false):
		if not state.flags.get("dawn_reached", false):
			_start_dialogue(["I'll pack when morning comes."])
			return
		state.flags["room_bag_packed"] = true
		state.add_note_once(&"notebook-match", "A matching page", "The torn edge fits the empty place in Kath's notebook. An old entry names the Observatory Castle. The equation remains unexplained.")
		satchel.frame = 1
		_play_effect(PENCIL_SOUND)
		_start_dialogue(["Notebook, pencil, and the page. I want to see what I was trying to understand at the castle."])
		return
	if absf(x - COAT_X) <= COAT_REACH:
		_start_dialogue(["Still warm from the pipes. I'll need this for the road."])


func _commit_comparison() -> void:
	ui.hide_modals()
	state.flags["room_notebook_compared"] = true
	state.add_note_once(&"notebook-match", "A matching page", "The torn edge fits the empty place in Kath's notebook. An old entry names the Observatory Castle. The equation remains unexplained.")
	_play_effect(PENCIL_SOUND)
	_start_dialogue(["The torn edge fits. And this line says I was due back at the Observatory Castle.", "The handwriting is mine. The equation still means nothing to me."])


func _show_journal() -> void:
	ui.show_journal(state.notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)), bool(state.flags.get("room_notebook_compared", false)), bool(state.flags.get("incident_complete", false)), state.room_preparation_complete(), bool(state.flags.get("machine_incident_active", false)))


func _return_to_journal() -> void:
	page_from_journal = false
	_set_mode(&"journal")
	_show_journal()


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


func _close_dialogue(_completed: bool) -> void:
	ui.hide_modals()
	_set_mode(&"roam")


func _close_overlay() -> void:
	ui.hide_modals()
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _play_effect(stream: AudioStream) -> void:
	effects_player.stop()
	effects_player.stream = stream
	effects_player.play()
