extends StoryRoom
## First official route into the rotating wing: identify the real down direction.

const CONTROL_WALKWAY_SCENE := "res://scenes/castle_control_walkway.tscn"
const MAINTENANCE_SHAFT_SCENE := "res://scenes/chapter1_maintenance_shaft.tscn"
const FLOOR_Y := 806.0
const LADDER_X := 1510.0
const LADDER_TOP_Y := 475.0
const LADDER_TOP_REACH := 18.0
const LADDER_FOOT_X := 1460.0
const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")
const CHALK := Color(231 / 255.0, 220 / 255.0, 196 / 255.0)  # #e7dcc4
const CHALK_SHADOW := Color(24 / 255.0, 35 / 255.0, 55 / 255.0)  # #182337

@onready var falling_water: Sprite2D = $FallingWater
@onready var shaft_hatch_art: Sprite2D = $ShaftHatchArt
@onready var return_hatch: Node2D = $ReturnHatch
@onready var chalk_patch: Node2D = $ChalkPatch
@onready var plumb_weight: Node2D = $PlumbWeight
@onready var water_path: Node2D = $WaterPath
@onready var fallen_furniture: Node2D = $FallenFurniture
@onready var shaft_ladder: Node2D = $ShaftLadder

var drip_player: AudioStreamPlayer
var drip_elapsed := 0.0
var guess_choice := -1
var chalk_arrow: Label
var chalk_stroke: Line2D


func _ready() -> void:
	hotspots = [return_hatch, chalk_patch, plumb_weight, water_path, fallen_furniture, shaft_ladder]
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.floor_y = FLOOR_Y
	kath.floor_slope = 0.0
	kath.left_limit = 100.0
	kath.right_limit = 1470.0
	kath.position = Vector2(390.0, FLOOR_Y)
	shaft_hatch_art.visible = state.castle_pose == &"inverted"
	drip_player = _add_audio("DripAudio", DRIP_SOUND, -22.0, true, false)
	_build_chalk_mark()
	_refresh_chalk()
	if not _room_settled():
		_start_dialogue(["This passage is only safe after the wing has stopped moving. I should return to the fixed tower."])
	elif spawn_tag == &"from-maintenance-shaft":
		kath.begin_climbing(LADDER_X, LADDER_TOP_Y, FLOOR_Y, LADDER_TOP_Y)
		ui.show_hint("W/S climb down. E at the top returns to the shaft.", 4.0)
	elif not _flag("inverted_room_intro_seen"):
		state.flags["inverted_room_intro_seen"] = true
		_start_dialogue([
			"The fixed tower's lower duct runs through the ring's service hub. Its low hatch opens onto the turned wing's old ceiling.",
			"The stone beneath me used to be the ceiling. Before I cross, I need to check which way loose things actually fall."
		])
	elif _flag("castle_down_confirmed"):
		ui.show_hint("Follow the old ceiling toward the maintenance ladder.", 4.0)
	else:
		ui.show_hint("Compare the leaking water with the hanging weight.", 4.0)


func _build_chalk_mark() -> void:
	chalk_arrow = Label.new()
	chalk_arrow.position = Vector2(650, 744)
	chalk_arrow.rotation = -0.09
	chalk_arrow.z_index = 1
	chalk_arrow.add_theme_font_size_override("font_size", 40)
	chalk_arrow.add_theme_color_override("font_color", CHALK)
	chalk_arrow.add_theme_color_override("font_shadow_color", CHALK_SHADOW)
	chalk_arrow.add_theme_constant_override("shadow_offset_x", 2)
	chalk_arrow.add_theme_constant_override("shadow_offset_y", 2)
	add_child(chalk_arrow)
	chalk_stroke = Line2D.new()
	chalk_stroke.z_index = 1
	chalk_stroke.width = 6.0
	chalk_stroke.default_color = CHALK
	chalk_stroke.antialiased = true
	add_child(chalk_stroke)


func _flag(key: String) -> bool:
	return bool(state.flags.get(key, false))


func _room_settled() -> bool:
	return state.castle_pose == &"inverted" and _flag("control_inversion_complete")


func _at_ladder_top() -> bool:
	return kath.locomotion_mode == &"climb" and kath.position.y <= LADDER_TOP_Y + LADDER_TOP_REACH


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
		elif _at_ladder_top():
			ui.show_prompt("Shaft Hatch", 1300.0, "ENTER", 550.0)
			return
		else:
			ui.hide_prompt()
			return
	var closest := nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 400.0
	if closest == return_hatch:
		action = "RETURN"
		prompt_y = 475.0
	elif closest == chalk_patch:
		action = "INSPECT" if _flag("castle_down_confirmed") else "MARK GUESS"
		prompt_y = 475.0
	elif closest == shaft_ladder:
		action = "CLIMB" if _flag("room_ladder_checked") else "CHECK"
		prompt_y = 390.0
	ui.show_prompt(closest.display_name, closest.approach_x, action, prompt_y)


func _room_input(event: InputEvent) -> bool:
	if mode != &"guess":
		return false
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		guess_choice = 0 if event.is_action_pressed("move_left") else 1
		_update_guess_bubble()
		return true
	if event.is_action_pressed("advance_dialogue"):
		if guess_choice < 0:
			_update_guess_bubble()
		else:
			state.flags["room_down_guess"] = "old_floor" if guess_choice == 0 else "old_ceiling"
			_close_overlay()
			_refresh_chalk()
			ui.show_hint("Guess marked. Check the drops and the hanging weight.", 4.0)
		return true
	return false


func _interact() -> void:
	if kath.locomotion_mode != &"climb":
		super()
	elif _at_ladder_top():
		_travel(MAINTENANCE_SHAFT_SCENE, &"from-inverted-room")


func _is_hotspot_available(_hotspot: Node) -> bool:
	return kath.locomotion_mode != &"climb"


func _inspect(hotspot: Node) -> void:
	if hotspot == return_hatch:
		_travel(CONTROL_WALKWAY_SCENE, &"from-inverted-room")
		return
	if hotspot == chalk_patch:
		if _flag("castle_down_confirmed"):
			_start_dialogue(["The chalk guess is still beside the two observations. I can see where it held and where it failed."])
		else:
			var guess: String = state.flags.get("room_down_guess", "")
			guess_choice = 0 if guess == "old_floor" else (1 if guess == "old_ceiling" else -1)
			_set_mode(&"guess")
			_update_guess_bubble()
		return
	if _ready_to_compare() and hotspot in [plumb_weight, water_path, shaft_ladder]:
		_start_down_comparison()
		return
	if hotspot == water_path:
		wick.react_to(888.0, 468.0)
		_start_dialogue([
			"The pipe broke above me, but its drops keep falling toward this stone ledge.",
			"The stream lands on what used to be the ceiling. I can trace its path with my eyes."
		], &"" if _flag("room_water_observed") else &"observe_water")
	elif hotspot == plumb_weight:
		wick.react_to(704.0, 600.0)
		_start_dialogue([
			"This weight hangs straight below its chain mount, toward the same ledge as the water.",
			"The mount moved with the room. The hanging direction did not."
		], &"" if _flag("room_plumb_observed") else &"observe_plumb")
	elif hotspot == fallen_furniture:
		_start_dialogue(["That chair slid from the old floor and stopped on the stone below me. I'll keep clear of the loose furniture."])
	elif hotspot == shaft_ladder:
		if not _room_settled():
			_start_dialogue(["The wing must settle before this ladder is safe."])
		elif not _flag("castle_down_confirmed"):
			_start_dialogue(["The ladder runs toward the maintenance shaft, but I need to check this room's safe lower surface first."])
		elif not _flag("room_ladder_checked"):
			_start_dialogue([
				"The ladder bolts are still set in stone. This route leads on toward Erin's maintenance ledge.",
				"I'll mark this access and check the shaft before I climb with any load."
			], &"mark_ladder")
		else:
			kath.begin_climbing(LADDER_X, LADDER_TOP_Y, FLOOR_Y, FLOOR_Y - 30.0)
			ui.show_hint("W/S climb. E at the top enters the maintenance shaft.", 4.0)


func _ready_to_compare() -> bool:
	return _flag("room_water_observed") and _flag("room_plumb_observed") and not _flag("castle_down_confirmed")


func _leave_ladder_at_foot() -> void:
	kath.stop_climbing()
	kath.position = Vector2(LADDER_FOOT_X, FLOOR_Y)
	ui.show_hint("Back on the lower ledge.", 2.0)


func _start_down_comparison() -> void:
	var first_line := "The room turned. Down stayed down."
	match state.flags.get("room_down_guess", ""):
		"old_floor":
			first_line = "My chalk arrow pointed to the old floor. Both observations disagree with it."
		"old_ceiling":
			first_line = "My chalk arrow pointed to the old ceiling. Both observations support it."
	_start_dialogue([first_line, "Both the drops and the weight point to the old ceiling under my feet. I can cross this ledge toward the maintenance ladder."], &"confirm_down")


func _update_guess_bubble() -> void:
	var selected := "Choose with ← / →" if guess_choice < 0 else ("OLD FLOOR ↑" if guess_choice == 0 else "OLD CEILING ↓")
	ui.show_dialogue("Before I check: which way is down?\n%s   ·   Enter mark   ·   Esc cancel" % selected, kath.global_position)


func _refresh_chalk() -> void:
	var guess: String = state.flags.get("room_down_guess", "")
	chalk_arrow.text = "?" if guess != "" else ""
	chalk_stroke.visible = guess != ""
	if guess == "old_floor":
		chalk_stroke.points = PackedVector2Array([Vector2(630, 790), Vector2(630, 741), Vector2(616, 757), Vector2(630, 741), Vector2(644, 757)])
	elif guess == "old_ceiling":
		chalk_stroke.points = PackedVector2Array([Vector2(630, 741), Vector2(630, 790), Vector2(616, 774), Vector2(630, 790), Vector2(644, 774)])


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
			var comparison := " No chalk guess was marked before the test."
			match state.flags.get("room_down_guess", ""):
				"old_floor":
					comparison = " My earlier chalk guess pointed the other way; the observations corrected it."
				"old_ceiling":
					comparison = " My chalk guess matched both observations."
			state.add_note_once(&"castle-down-confirmed", "The lower surface", "The wing rotated, but the water and hanging weight still point in the same down direction. The old ceiling is now the safe lower ledge toward the maintenance ladder." + comparison)
			ui.show_hint("The lower ledge leads toward the maintenance ladder.", 4.0)
		&"mark_ladder":
			state.flags["room_ladder_checked"] = true
			state.add_note_once(&"castle-shaft-access", "Maintenance shaft access", "A wall ladder at the far end of the turned room leads toward Erin's maintenance ledge. Its stone anchors are visible; the shaft beyond still needs inspection.")
	if action in [&"observe_water", &"observe_plumb"] and _ready_to_compare():
		_start_down_comparison()
