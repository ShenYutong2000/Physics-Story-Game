extends SceneTree
## Preferences, pause access, key remap and live text sizing.

const TITLE: PackedScene = preload("res://scenes/title_screen.tscn")
const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const TEST_PATH := "res://.godot/stage6-settings-test.cfg"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	settings.settings_path_override = TEST_PATH
	var title = TITLE.instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	title.selection = 2
	title._unhandled_input(_key(KEY_ENTER))
	if not settings.menu.visible:
		_fail("Title Settings did not open.")
		return
	settings.selection = 4
	settings._adjust(1)
	if settings.hints_enabled:
		_fail("Optional hints did not turn off.")
		return
	settings.selection = 3
	settings._adjust(1)
	if settings.text_scale < 1.04 or title.get_node("Menu/Title").get_theme_font_size("font_size") <= 62:
		_fail("Text size did not change live.")
		return
	if InputMap.has_action("world_action") or settings.key_bindings.has("world_action"):
		_fail("The removed action binding still exists.")
		return
	settings.selection = 5
	settings._input(_key(KEY_ENTER))
	if not settings.capturing:
		_fail("Interact-key capture did not start.")
		return
	settings._input(_key(KEY_G))
	if settings.capturing:
		_fail("Interact-key capture did not end after a valid letter.")
		return
	if settings.key_label("interact") != "G" or not settings.control_text("E  OPERATE").begins_with("G"):
		_fail("Interact remap did not update game prompts.")
		return
	if settings._bind_key("interact", KEY_F) or settings.key_label("interact") != "G":
		_fail("F should not be assignable to the unified interaction.")
		return
	settings.close_menu()
	if not FileAccess.file_exists(TEST_PATH):
		_fail("Preferences were not saved.")
		return
	var hall = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	var no_checks: Array[StringName] = []
	hall.ui.update_shaft_load_check(no_checks, 0)
	if not hall.ui.shaft_load_detail.text.begins_with("G to compare"):
		_fail("Load check did not use the remapped action key.")
		return
	hall.ui.update_shaft_winch(1.0, false)
	if not hall.ui.shaft_winch_instruction.text.contains("G to dock"):
		_fail("Winch instructions did not use the remapped action key.")
		return
	hall.ui.show_engine_maintenance("TEST", "TEST", "TEST", "E CHECK")
	if hall.ui.engine_footer.text != "G CHECK":
		_fail("Engine instructions did not use the remapped action key.")
		return
	hall.ui.hide_modals()
	hall._set_mode(&"paused")
	settings._input(_key(KEY_S))
	if not settings.menu.visible:
		_fail("Pause-screen Settings did not open.")
		return
	settings._input(_key(KEY_ESCAPE))
	if settings.menu.visible or hall.mode != &"paused":
		_fail("Closing Settings did not return to pause.")
		return
	settings.hints_enabled = true
	settings.text_scale = 1.0
	settings._bind_key("interact", KEY_E)
	settings.settings_path_override = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("STAGE6_SETTINGS_OK: title, pause, hint toggle, text, action remap and persistence")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("STAGE6_SETTINGS_FAIL: " + message)
	quit(1)
