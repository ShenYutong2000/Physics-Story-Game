extends StoryRoom
## Notebook comparison, rest, and departure preparation.

const UPPER_SCENE := "res://scenes/upper_stacks.tscn"
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-room.wav")
const PAGE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")
const NOTEBOOK_NOTE := {
	"title": "A matching page",
	"body": "The torn edge fits the empty place in Kath's notebook. An old entry names the Observatory Castle. The equation remains unexplained.",
}

const DOOR_X := 100.0
const LAMP_X := 1281.0
const NOTEBOOK_X := 1028.0
const BED_X := 560.0
const BAG_X := 646.0
const COAT_X := 881.0

## Room objects in priority order: id, centre x, reach, prompt name.
const TARGETS := [
	[&"door", DOOR_X, 94.0, "Stairway to Upper Stacks"],
	[&"lamp", LAMP_X, 75.0, "Desk lamp"],
	[&"notebook", NOTEBOOK_X, 75.0, "Old notebook"],
	[&"bed", BED_X, 55.0, "Bed"],
	[&"bag", BAG_X, 55.0, "Travel satchel"],
	[&"coat", COAT_X, 55.0, "Hanging coat"],
]

@onready var far: Sprite2D = $Far
@onready var rain_streaks: Node2D = $RainStreaks
@onready var night_tint: CanvasModulate = $NightTint
@onready var lamp: AnimatedSprite2D = $DeskLamp
@onready var satchel: AnimatedSprite2D = $Satchel


func _ready() -> void:
	state.take_spawn_tag()
	kath.position = Vector2(210.0, 801.0)
	_apply_archive_weather(far, rain_streaks, false)
	lamp.frame = 1 if _flag("room_lamp_on") else 0
	satchel.frame = 1 if _flag("room_bag_packed") else 0
	if _flag("dawn_reached"):
		night_tint.color = Color.WHITE
	_add_audio("RoomAmbience", AMBIENCE, -16.0, true)
	if not _flag("room_intro_seen"):
		state.flags["room_intro_seen"] = true
		_start_dialogue(["My room. I must have hidden that page here before the Night of Unnaming.", "First, the desk lamp. Then I can compare it with the notebook I kept."])


func _flag(key: String) -> bool:
	return bool(state.flags.get(key, false))


func discovery_candidates() -> Array[Dictionary]:
	var items: Array[Dictionary] = [{"x": DOOR_X, "position": Vector2(DOOR_X, 575), "id": &"room-door"}]
	if not _flag("room_lamp_on"):
		items.append({"x": LAMP_X, "position": Vector2(LAMP_X, 495), "id": &"room-lamp"})
	if _flag("room_lamp_on") and not _flag("room_notebook_compared"):
		items.append({"x": NOTEBOOK_X, "position": Vector2(NOTEBOOK_X, 515), "id": &"room-notebook"})
	if _flag("room_notebook_compared") and not _flag("room_rested"):
		items.append({"x": BED_X, "position": Vector2(BED_X, 580), "id": &"room-bed"})
	if _flag("dawn_reached") and not _flag("room_bag_packed"):
		items.append({"x": BAG_X, "position": Vector2(BAG_X, 585), "id": &"room-bag"})
	items.append({"x": COAT_X, "position": Vector2(COAT_X, 475), "id": &"room-coat"})
	return items


## The first object in reach that still has something to do, or {}.
func _target_at(x: float) -> Dictionary:
	for target in TARGETS:
		var id: StringName = target[0]
		if absf(x - float(target[1])) <= float(target[2]) and not _target_finished(id):
			return {"id": id, "x": target[1], "name": target[3]}
	return {}


func _target_finished(id: StringName) -> bool:
	match id:
		&"lamp":
			return _flag("room_lamp_on")
		&"notebook":
			return _flag("room_notebook_compared")
		&"bed":
			return _flag("room_rested")
		&"bag":
			return _flag("room_bag_packed")
	return false


func _target_action(id: StringName) -> String:
	match id:
		&"door":
			return "RETURN"
		&"lamp":
			return "TURN ON"
		&"notebook":
			return "COMPARE PAGE" if _flag("room_lamp_on") else "TURN ON LAMP FIRST"
		&"bed":
			return "REST UNTIL MORNING" if _flag("room_notebook_compared") else "COMPARE THE PAGE FIRST"
		&"bag":
			return "PACK NOTEBOOK" if _flag("dawn_reached") else "WAIT FOR DAWN"
	return "INSPECT"


func _process(_delta: float) -> void:
	var target := _target_at(kath.position.x) if mode == &"roam" else {}
	if target.is_empty():
		ui.hide_prompt()
	else:
		ui.show_prompt(target["name"], target["x"], _target_action(target["id"]), 540.0)


func _room_input(event: InputEvent) -> bool:
	if mode == &"comparison" and event.is_action_pressed("advance_dialogue"):
		_commit_comparison()
		return true
	return false


func _interact() -> void:
	var target := _target_at(kath.position.x)
	if target.is_empty():
		return
	match target["id"]:
		&"door":
			state.flags["prologue_departure_ready"] = state.room_preparation_complete()
			state.travel_to(UPPER_SCENE, &"from-kath-room")
		&"lamp":
			state.flags["room_lamp_on"] = true
			lamp.frame = 1
			_play_effect(PAGE_SOUND)
			_start_dialogue(["There. I can read the pencil marks now."])
		&"notebook":
			if not _flag("room_lamp_on"):
				_start_dialogue(["Too dark to compare the page. I should light the desk lamp."])
				return
			_set_mode(&"comparison")
			ui.show_notebook_comparison()
			_play_effect(PAGE_SOUND)
		&"bed":
			if not _flag("room_notebook_compared"):
				_start_dialogue(["I need to find out whether this page belongs in my notebook first."])
				return
			_rest_until_dawn()
		&"bag":
			if not _flag("dawn_reached"):
				_start_dialogue(["I'll pack when morning comes."])
				return
			state.flags["room_bag_packed"] = true
			state.add_note_once(&"notebook-match", NOTEBOOK_NOTE["title"], NOTEBOOK_NOTE["body"])
			satchel.frame = 1
			_play_effect(PENCIL_SOUND)
			_start_dialogue(["Notebook, pencil, and the page. I want to see what I was trying to understand at the castle."])
		&"coat":
			_start_dialogue(["Still warm from the pipes. I'll need this for the road."])


func _rest_until_dawn() -> void:
	state.flags["room_rested"] = true
	state.flags["dawn_reached"] = true
	_apply_archive_weather(far, rain_streaks, false)
	create_tween().tween_property(night_tint, "color", Color.WHITE, 1.8)
	_play_effect(PAGE_SOUND)
	_start_dialogue(["I must have fallen asleep over my notes.", "Morning already. The castle entry is still waiting in my notebook."])


func _commit_comparison() -> void:
	ui.hide_modals()
	state.flags["room_notebook_compared"] = true
	state.add_note_once(&"notebook-match", NOTEBOOK_NOTE["title"], NOTEBOOK_NOTE["body"])
	_play_effect(PENCIL_SOUND)
	_start_dialogue(["The torn edge fits. And this line says I was due back at the Observatory Castle.", "The handwriting is mine. The equation still means nothing to me."])
