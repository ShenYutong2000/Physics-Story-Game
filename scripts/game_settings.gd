extends Node
## Player preferences shared by the title screen and every story scene.

signal changed

const SETTINGS_PATH := "user://footnotes-settings.cfg"
const REMAPPABLE := ["interact", "world_action", "toggle_journal", "request_hint"]
const DEFAULT_KEYS := {
	"interact": KEY_E,
	"world_action": KEY_F,
	"toggle_journal": KEY_J,
	"request_hint": KEY_H,
}
const ROWS := ["Master volume", "Ambience", "Effects", "Text size", "Optional hints", "Examine key", "Action key", "Notes key", "Hint key", "Back"]
const BUS_NAMES := ["Master", "Ambience", "Effects"]
const UI_TICK: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")

var master_volume := 1.0
var ambience_volume := 0.8
var effects_volume := 0.9
var text_scale := 1.0
var hints_enabled := true
var key_bindings: Dictionary = DEFAULT_KEYS.duplicate()
var settings_path_override := ""
var menu: CanvasLayer
var rows_label: Label
var instruction: Label
var selection := 0
var capturing := false
var status_message := ""
var ui_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_buses()
	load_preferences()
	_build_menu()
	apply_text_scale(menu)
	ui_player = AudioStreamPlayer.new()
	ui_player.stream = UI_TICK
	ui_player.volume_db = -18.0
	configure_audio(ui_player)
	add_child(ui_player)
	get_tree().scene_changed.connect(_scene_changed)
	_apply_audio()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not menu.visible:
		var scene := get_tree().current_scene
		if scene != null and scene.get("mode") == &"paused" and event.keycode == KEY_S:
			open_menu()
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	if capturing:
		if event.keycode == KEY_ESCAPE:
			capturing = false
			status_message = ""
		else:
			capturing = not _bind_key(REMAPPABLE[selection - 5], event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		_refresh()
		return
	if event.keycode in [KEY_ESCAPE, KEY_S] or (event.keycode == KEY_ENTER and selection == 9):
		close_menu()
	elif event.keycode in [KEY_UP, KEY_W]:
		status_message = ""
		selection = posmod(selection - 1, ROWS.size())
		play_ui_tick()
		_refresh()
	elif event.keycode in [KEY_DOWN]:
		status_message = ""
		selection = posmod(selection + 1, ROWS.size())
		play_ui_tick()
		_refresh()
	elif event.keycode in [KEY_LEFT, KEY_RIGHT]:
		_adjust(-1 if event.keycode == KEY_LEFT else 1)
	elif event.keycode == KEY_ENTER:
		if selection >= 5 and selection <= 8:
			capturing = true
			status_message = ""
		elif selection < 5:
			_adjust(1)
		_refresh()


func open_menu() -> void:
	capturing = false
	status_message = ""
	selection = 0
	menu.visible = true
	_refresh()


func close_menu() -> void:
	capturing = false
	menu.visible = false
	save_preferences()


func _adjust(direction: int) -> void:
	match selection:
		0: master_volume = clampf(master_volume + direction * 0.1, 0.0, 1.0)
		1: ambience_volume = clampf(ambience_volume + direction * 0.1, 0.0, 1.0)
		2: effects_volume = clampf(effects_volume + direction * 0.1, 0.0, 1.0)
		3: text_scale = clampf(text_scale + direction * 0.05, 1.0, 1.15)
		4: hints_enabled = not hints_enabled
		_: return
	master_volume = snappedf(master_volume, 0.1)
	ambience_volume = snappedf(ambience_volume, 0.1)
	effects_volume = snappedf(effects_volume, 0.1)
	text_scale = snappedf(text_scale, 0.05)
	_apply_audio()
	apply_text_scale(menu)
	_on_scene_changed(get_tree().current_scene)
	changed.emit()
	play_ui_tick()
	_refresh()


func _bind_key(action: String, code: int) -> bool:
	if code < KEY_A or code > KEY_Z or code in [KEY_Q, KEY_S, KEY_W, KEY_A, KEY_D]:
		status_message = "Choose an unused letter other than Q, S, W, A or D."
		return false
	for other in key_bindings:
		if other != action and key_bindings[other] == code:
			status_message = "That letter already has a story action."
			return false
	key_bindings[action] = code
	status_message = ""
	_apply_binding(action, code)
	_on_scene_changed(get_tree().current_scene)
	changed.emit()
	play_ui_tick()
	return true


func _apply_binding(action: String, code: int) -> void:
	var input_event := InputEventKey.new()
	input_event.physical_keycode = code
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, input_event)


func play_ui_tick() -> void:
	if ui_player != null:
		ui_player.play()


func key_label(action: String) -> String:
	return char(int(key_bindings.get(action, DEFAULT_KEYS.get(action, KEY_E))))


func control_text(value: String) -> String:
	var result := value
	var pairs := [["interact", "E"], ["world_action", "F"], ["toggle_journal", "J"], ["request_hint", "H"]]
	for i in pairs.size():
		var pair: Array = pairs[i]
		var marker := "⟦KEY_%d⟧" % i
		result = result.replace(pair[1] + "  ", marker + "  ")
		result = result.replace(pair[1] + " / ", marker + " / ")
		result = result.replace("Press " + pair[1] + " ", "Press " + marker + " ")
		result = result.replace("press " + pair[1] + " ", "press " + marker + " ")
		result = result.replace(pair[1] + " at ", marker + " at ")
		result = result.replace(pair[1] + " to ", marker + " to ")
		result = result.replace(pair[1] + " CHECK", marker + " CHECK")
	for i in pairs.size():
		result = result.replace("⟦KEY_%d⟧" % i, key_label(pairs[i][0]))
	return result


func apply_text_scale(node: Node) -> void:
	if node == null:
		return
	if node is Label:
		if not node.has_meta("base_font_size"):
			node.set_meta("base_font_size", node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size", roundi(float(node.get_meta("base_font_size")) * text_scale))
	elif node is RichTextLabel:
		if not node.has_meta("base_font_size"):
			node.set_meta("base_font_size", node.get_theme_font_size("normal_font_size"))
		node.add_theme_font_size_override("normal_font_size", roundi(float(node.get_meta("base_font_size")) * text_scale))
	for child in node.get_children():
		apply_text_scale(child)


func _on_scene_changed(scene: Node) -> void:
	if scene == null:
		return
	apply_text_scale(scene)
	_apply_control_labels(scene)


func _scene_changed() -> void:
	_on_scene_changed(get_tree().current_scene)


func _apply_control_labels(node: Node) -> void:
	if node is Label and node.has_meta("control_base_text"):
		node.text = control_text(str(node.get_meta("control_base_text")))
	for child in node.get_children():
		_apply_control_labels(child)


func configure_audio(player: AudioStreamPlayer, ambient: bool = false) -> void:
	player.bus = "Ambience" if ambient else "Effects"


func _ensure_buses() -> void:
	for name in BUS_NAMES.slice(1):
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus(AudioServer.bus_count)
			AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _apply_audio() -> void:
	for i in BUS_NAMES.size():
		var index := AudioServer.get_bus_index(BUS_NAMES[i])
		if index >= 0:
			var value: float = [master_volume, ambience_volume, effects_volume][i]
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))
			AudioServer.set_bus_mute(index, value <= 0.0)


func save_preferences() -> bool:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "ambience", ambience_volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("accessibility", "text_scale", text_scale)
	config.set_value("accessibility", "hints_enabled", hints_enabled)
	for action in REMAPPABLE:
		config.set_value("keys", action, int(key_bindings[action]))
	return config.save(_settings_path()) == OK


func load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(_settings_path()) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master", 1.0)), 0.0, 1.0)
	ambience_volume = clampf(float(config.get_value("audio", "ambience", 0.8)), 0.0, 1.0)
	effects_volume = clampf(float(config.get_value("audio", "effects", 0.9)), 0.0, 1.0)
	text_scale = clampf(float(config.get_value("accessibility", "text_scale", 1.0)), 1.0, 1.15)
	hints_enabled = bool(config.get_value("accessibility", "hints_enabled", true))
	var proposed := {}
	for action in REMAPPABLE:
		var code := int(config.get_value("keys", action, DEFAULT_KEYS[action]))
		if code < KEY_A or code > KEY_Z or code in [KEY_Q, KEY_S, KEY_W, KEY_A, KEY_D] or proposed.values().has(code):
			proposed = DEFAULT_KEYS.duplicate()
			break
		proposed[action] = code
	key_bindings = proposed
	for action in REMAPPABLE:
		_apply_binding(action, int(key_bindings[action]))
	_apply_audio()


func _settings_path() -> String:
	return SETTINGS_PATH if settings_path_override.is_empty() else settings_path_override


func _build_menu() -> void:
	menu = CanvasLayer.new()
	menu.layer = 100
	add_child(menu)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.035, 0.07, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(backdrop)
	var panel := Panel.new()
	panel.position = Vector2(400, 90)
	panel.size = Vector2(872, 760)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172536")
	style.border_color = Color("b28755")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	menu.add_child(panel)
	var title := Label.new()
	title.position = Vector2(470, 130)
	title.size = Vector2(730, 55)
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 39)
	title.add_theme_color_override("font_color", Color("fff4db"))
	menu.add_child(title)
	rows_label = Label.new()
	rows_label.position = Vector2(520, 205)
	rows_label.size = Vector2(650, 520)
	rows_label.add_theme_font_size_override("font_size", 27)
	rows_label.add_theme_color_override("font_color", Color("f5dba6"))
	menu.add_child(rows_label)
	instruction = Label.new()
	instruction.position = Vector2(470, 740)
	instruction.size = Vector2(730, 60)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 20)
	instruction.add_theme_color_override("font_color", Color("fff4db"))
	menu.add_child(instruction)
	menu.visible = false


func _refresh() -> void:
	var values := [
		"%d%%" % roundi(master_volume * 100),
		"%d%%" % roundi(ambience_volume * 100),
		"%d%%" % roundi(effects_volume * 100),
		"%d%%" % roundi(text_scale * 100),
		"ON" if hints_enabled else "OFF",
		key_label("interact"), key_label("world_action"), key_label("toggle_journal"), key_label("request_hint"), ""
	]
	var lines: Array[String] = []
	for i in ROWS.size():
		lines.append("%s%-20s %s" % ["›  " if i == selection else "   ", ROWS[i], values[i]])
	rows_label.text = "\n".join(lines)
	instruction.text = status_message if not status_message.is_empty() else "PRESS A NEW LETTER · ESC CANCEL" if capturing else "↑/↓ SELECT  ·  ←/→ ADJUST  ·  ENTER CHANGE  ·  ESC BACK"
