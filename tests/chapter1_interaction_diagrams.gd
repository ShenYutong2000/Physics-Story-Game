extends SceneTree
## Five 16:9 interaction diagrams for a Chapter I presentation.
## Captures the playable Godot scenes; does not write story progress or save data.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")
const ROOM: PackedScene = preload("res://scenes/chapter1_inverted_room.tscn")
const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")
const ENGINE: PackedScene = preload("res://scenes/chapter1_engine_room.tscn")
const OBSERVATORY: PackedScene = preload("res://scenes/chapter1_observatory.tscn")
const OUTPUT_DIR := "res://../Presentation/Chapter-I-Interaction-Diagrams-v2"
const SIZE := Vector2i(1672, 941)
const GOLD := Color("f5c77e")
const CREAM := Color("fff3de")
const DARK := Color(0.025, 0.045, 0.09, 0.95)

var state: Node
var current: Node2D
var overlay: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = SIZE
	state = root.get_node("PrologueState")
	_reset_state(&"tilted")
	state.flags["incident_complete"] = true
	state.flags["control_walkway_intro_seen"] = true
	await _load_scene(CONTROL)
	current.kath.position.x = 500.0
	_add_diagram(
		"01   CONTROL WALKWAY",
		"Castle begins tilted; test the local return before entering the wing",
		[
			{"point": Vector2(170, 565), "name": "Service Road", "detail": "E: return to the approach road."},
			{"point": Vector2(270, 505), "name": "Erin", "detail": "E: hear her account of the fault."},
			{"point": Vector2(420, 350), "name": "Position Dial", "detail": "E: compare needle with visible tilt."},
			{"point": Vector2(590, 530), "name": "Return Test", "detail": "E after Erin + dial; watch failed stop."},
			{"point": Vector2(1460, 370), "name": "Rotating Wing", "detail": "Observe inversion; tower stays upright."},
			{"point": Vector2(680, 655), "name": "Lower Hatch", "detail": "E after inversion: enter the wing."}
		]
	)
	if not await _save("01-control-walkway.png"):
		quit(1)
		return
	await _remove_current()

	_reset_state(&"inverted")
	state.flags["control_inversion_complete"] = true
	state.flags["inverted_room_intro_seen"] = true
	await _load_scene(ROOM)
	current.kath.position.x = 840.0
	_add_diagram(
		"02   INVERTED ROOM",
		"Predict, compare two clues, then climb from the rotating wing to the fixed shaft",
		[
			{"point": Vector2(150, 600), "name": "Lower Hatch", "detail": "E: return to control walkway."},
			{"point": Vector2(505, 655), "name": "Chalk Mark", "detail": "Optional: guess down before testing."},
			{"point": Vector2(685, 560), "name": "Hanging Weight", "detail": "E: see where its chain points."},
			{"point": Vector2(950, 440), "name": "Falling Water", "detail": "E: compare the drop direction."},
			{"point": Vector2(1180, 670), "name": "Fallen Chair", "detail": "Optional: inspect the loose furniture."},
			{"point": Vector2(1510, 530), "name": "Maintenance Ladder", "detail": "E check/grab; Up climb; E at top."}
		]
	)
	if not await _save("02-inverted-room.png"):
		quit(1)
		return
	await _remove_current()

	_reset_state(&"inverted")
	state.flags["shaft_intro_seen"] = true
	await _load_scene(SHAFT)
	current.kath.position.x = 680.0
	_add_diagram(
		"03   MAINTENANCE SHAFT",
		"All E controls are reached from Kath's safe left platform",
		[
			{"point": Vector2(130, 655), "name": "Wing Passage", "detail": "E: return to inverted room."},
			{"point": Vector2(300, 630), "name": "Long Rope", "detail": "Take after tool trip; use for rethread."},
			{"point": Vector2(470, 620), "name": "Winch", "detail": "Up lift; Down lower; Space brake."},
			{"point": Vector2(1110, 165), "name": "Rope + Top Anchor", "detail": "E from left platform; rethread rope."},
			{"point": Vector2(705, 690), "name": "Tools + Tray", "detail": "Load chest without crossing the gap."},
			{"point": Vector2(1415, 385), "name": "Voice Tube / Erin", "detail": "Call to dock, board, release catch."},
			{"point": Vector2(1100, 655), "name": "Basket + Dock", "detail": "Lock before rethread or Erin exits."},
			{"point": Vector2(790, 590), "name": "Engine Access", "detail": "E after Erin reaches fixed platform."}
		]
	)
	if not await _save("03-maintenance-shaft.png"):
		quit(1)
		return
	await _remove_current()

	_reset_state(&"inverted")
	state.flags["shaft_rescue_complete"] = true
	state.flags["engine_intro_seen"] = true
	await _load_scene(ENGINE)
	current.kath.position.x = 790.0
	_add_diagram(
		"04   ENGINE ROOM",
		"Trace the failed stop, isolate the drive, test, then return the wing",
		[
			{"point": Vector2(120, 595), "name": "Shaft", "detail": "E: return to rescued Erin's platform."},
			{"point": Vector2(330, 320), "name": "Diagram", "detail": "After clues, choose cause and repair order."},
			{"point": Vector2(570, 590), "name": "Isolator / Erin", "detail": "E: cut automatic feed before clearing."},
			{"point": Vector2(840, 590), "name": "Jam", "detail": "E: clear only after isolation."},
			{"point": Vector2(965, 430), "name": "Linkage", "detail": "E: check signal, brake and lock."},
			{"point": Vector2(1115, 315), "name": "Brake + Signal", "detail": "Inspect both before choosing a cause."},
			{"point": Vector2(1280, 585), "name": "Drive", "detail": "E after checks; hold Left to restore."},
			{"point": Vector2(1570, 580), "name": "Wing Door", "detail": "E after restoration: observatory."}
		]
	)
	if not await _save("04-engine-room.png"):
		quit(1)
		return
	await _remove_current()

	_reset_state(&"restored")
	state.flags["engine_restored"] = true
	state.flags["observatory_arrival_seen"] = true
	await _load_scene(OBSERVATORY)
	current.kath.position.x = 1290.0
	_add_diagram(
		"05   OBSERVATORY",
		"Record all three pages, stitch Kath's notebook, then return to Erin",
		[
			{"point": Vector2(310, 660), "name": "Archive Drawer", "detail": "E open; E read; Enter records each page."},
			{"point": Vector2(780, 450), "name": "Telescope", "detail": "Optional: inspect the steady tower view."},
			{"point": Vector2(1300, 660), "name": "Notebook Hotspot", "detail": "Near entry; after 3 pages, E stitch."},
			{"point": Vector2(1530, 555), "name": "Engine Passage", "detail": "E return to Erin for chapter ending."}
		]
	)
	if not await _save("05-observatory.png"):
		quit(1)
		return
	print("CHAPTER1_INTERACTION_DIAGRAMS_OK: 5 scene diagrams at %dx%d" % [SIZE.x, SIZE.y])
	quit(0)


func _reset_state(pose: StringName) -> void:
	state.flags.clear()
	state.notes.clear()
	state.pending_spawn_tag = &""
	state.castle_pose = pose


func _load_scene(scene: PackedScene) -> void:
	current = scene.instantiate()
	root.add_child(current)
	current_scene = current
	await process_frame
	current._close_overlay()
	current.mode = &"capture"
	current.ui.hint.visible = false
	current.ui.hide_prompt()


func _remove_current() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null
	if current != null:
		current.queue_free()
		current = null
	await process_frame


func _add_diagram(title: String, subtitle: String, items: Array[Dictionary]) -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 50
	root.add_child(overlay)
	var frame := Control.new()
	frame.size = SIZE
	overlay.add_child(frame)
	_panel(frame, Vector2.ZERO, Vector2(SIZE.x, 82), DARK)
	_panel(frame, Vector2(0, 80), Vector2(SIZE.x, 2), GOLD)
	_label(frame, Vector2(36, 8), Vector2(730, 48), title, 32, CREAM)
	_label(frame, Vector2(740, 19), Vector2(890, 40), subtitle, 21, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_panel(frame, Vector2(0, 755), Vector2(SIZE.x, 186), DARK)
	_panel(frame, Vector2(0, 755), Vector2(SIZE.x, 2), GOLD)
	for i in items.size():
		var item: Dictionary = items[i]
		_marker(frame, i + 1, item["point"])
		var column := i % 4
		var row := i / 4
		var x := 32.0 + float(column) * 410.0
		var y := 770.0 + float(row) * 82.0
		_label(frame, Vector2(x, y), Vector2(380, 27), "%d  %s" % [i + 1, item["name"]], 19, GOLD)
		_label(frame, Vector2(x + 20, y + 27), Vector2(375, 48), item["detail"], 15, CREAM)


func _panel(parent: Control, at: Vector2, bounds: Vector2, color: Color) -> void:
	var panel := ColorRect.new()
	panel.position = at
	panel.size = bounds
	panel.color = color
	parent.add_child(panel)


func _label(parent: Control, at: Vector2, bounds: Vector2, value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label := Label.new()
	label.position = at
	label.size = bounds
	label.text = value
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _marker(parent: Control, number: int, point: Vector2) -> void:
	var path := PackedVector2Array()
	for i in 49:
		var angle := TAU * float(i) / 48.0
		path.append(point + Vector2(cos(angle), sin(angle)) * 42.0)
	var ring := Line2D.new()
	ring.points = path
	ring.width = 5.0
	ring.default_color = GOLD
	ring.antialiased = true
	parent.add_child(ring)
	var badge_center := point + Vector2(37, -37)
	var circle := PackedVector2Array()
	for i in 48:
		var angle := TAU * float(i) / 48.0
		circle.append(Vector2(cos(angle), sin(angle)) * 24.0)
	var badge := Polygon2D.new()
	badge.position = badge_center
	badge.polygon = circle
	badge.color = DARK
	parent.add_child(badge)
	var outline := Line2D.new()
	outline.position = badge_center
	outline.points = circle + PackedVector2Array([circle[0]])
	outline.width = 3.0
	outline.default_color = GOLD
	outline.antialiased = true
	parent.add_child(outline)
	_label(parent, badge_center - Vector2(15, 19), Vector2(30, 38), str(number), 25, CREAM, HORIZONTAL_ALIGNMENT_CENTER)


func _save(name: String) -> bool:
	for i in 6:
		await process_frame
	var picture: Image = root.get_texture().get_image()
	if picture == null or picture.get_size() != SIZE:
		push_error("Could not capture full-size frame for " + name)
		return false
	var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(folder)
	if picture.save_png(folder.path_join(name)) != OK:
		push_error("Could not write " + name)
		return false
	return true
