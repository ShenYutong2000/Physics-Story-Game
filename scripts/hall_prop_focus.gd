extends CanvasLayer
## Reusable keyboard-only close-up for a hall prop. The hall owns progress and input.

signal dismissed

const CANVAS_SIZE := Vector2(1672, 941)
const IMAGE_RECT := Rect2(486, 109, 700, 700)
const CREAM := Color("fff4db")
const GOLD := Color("f5dba6")

var screen: Control
var shade: ColorRect
var picture: TextureRect
var title_label: Label
var detail_label: Label
var controls_label: Label
var parts_label: Label
var config: Dictionary = {}
var selected_part := 0
var completed := false
var transitioning := false
var _tween: Tween
var _changed_image: TextureRect


func _ready() -> void:
	layer = 30
	screen = Control.new()
	screen.name = "FocusCanvas"
	screen.size = CANVAS_SIZE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	shade = ColorRect.new()
	shade.name = "Backdrop"
	shade.size = CANVAS_SIZE
	shade.color = Color("0b1024")
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(shade)
	picture = TextureRect.new()
	picture.name = "PropImage"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(picture)
	title_label = _label("Title", Rect2(92, 30, 1488, 62), 36, GOLD)
	detail_label = _label("Observation", Rect2(180, 807, 1312, 47), 25, CREAM)
	controls_label = _label("Controls", Rect2(180, 858, 1312, 40), 22, GOLD)
	parts_label = _label("Parts", Rect2(1200, 218, 360, 240), 21, CREAM)
	parts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen.visible = false


func open_view(prop_config: Dictionary, already_completed: bool) -> void:
	_stop_tween()
	_clear_changed_image()
	config = prop_config
	completed = already_completed
	selected_part = 0
	screen.visible = true
	screen.modulate.a = 1.0
	shade.modulate.a = 0.0
	picture.texture = _state_texture(completed)
	picture.modulate.a = 1.0
	var source: Vector2 = config.get("source", Vector2(836, 470))
	picture.position = source - Vector2(65, 65)
	picture.size = Vector2(130, 130)
	_refresh_labels()
	_set_labels_alpha(0.0)
	transitioning = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(shade, "modulate:a", 0.91, 0.23)
	_tween.tween_property(picture, "position", IMAGE_RECT.position, 0.23).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(picture, "size", IMAGE_RECT.size, 0.23).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for label in [title_label, detail_label, controls_label, parts_label]:
		_tween.tween_property(label, "modulate:a", 1.0, 0.18).set_delay(0.05)
	_tween.finished.connect(func() -> void: transitioning = false)


func select_part(direction: int) -> void:
	if not screen.visible or transitioning:
		return
	var parts: Array = config.get("parts", [])
	if parts.size() < 2:
		return
	selected_part = posmod(selected_part + direction, parts.size())
	_refresh_labels()


func selected_action() -> StringName:
	if not screen.visible or transitioning or completed:
		return &""
	var parts: Array = config.get("parts", [])
	if parts.is_empty():
		return &""
	return StringName(parts[selected_part].get("action", ""))


func set_completed() -> void:
	if completed or not screen.visible:
		return
	completed = true
	_stop_tween()
	_changed_image = TextureRect.new()
	_changed_image.name = "ChangedImage"
	_changed_image.texture = _state_texture(true)
	_changed_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_changed_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_changed_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_changed_image.position = IMAGE_RECT.position + Vector2(-28, 0)
	_changed_image.size = IMAGE_RECT.size
	_changed_image.modulate.a = 0.0
	screen.add_child(_changed_image)
	transitioning = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_changed_image, "position", IMAGE_RECT.position, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_changed_image, "modulate:a", 1.0, 0.24)
	_tween.finished.connect(func() -> void:
		_clear_changed_image()
		transitioning = false
		_refresh_labels()
	)


func close_view() -> void:
	if not screen.visible:
		return
	_stop_tween()
	_clear_changed_image()
	transitioning = true
	_tween = create_tween()
	_tween.tween_property(screen, "modulate:a", 0.0, 0.14)
	_tween.finished.connect(func() -> void:
		screen.visible = false
		screen.modulate.a = 1.0
		transitioning = false
		dismissed.emit()
	)


func is_open() -> bool:
	return screen.visible


func _state_texture(is_done: bool) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = config["texture"]
	atlas.region = config["after_region"] if is_done else config["before_region"]
	return atlas


func _refresh_labels() -> void:
	title_label.text = config.get("title", "INSPECT")
	detail_label.text = config.get("after_text", "") if completed else config.get("before_text", "")
	var parts: Array = config.get("parts", [])
	var lines := PackedStringArray()
	for index in parts.size():
		lines.append(("› " if index == selected_part else "  ") + String(parts[index].get("label", "")))
	parts_label.text = "\n".join(lines)
	if completed:
		controls_label.text = "ESC  RETURN  ·  %s" % config.get("done_control", "ALREADY SECURED")
	else:
		controls_label.text = "E  %s  ·  ESC  RETURN%s" % [config.get("verb", "OPERATE"), "  ·  ← / →  SELECT" if parts.size() > 1 else ""]


func _set_labels_alpha(alpha: float) -> void:
	for label in [title_label, detail_label, controls_label, parts_label]:
		label.modulate.a = alpha


func _stop_tween() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()


func _clear_changed_image() -> void:
	if _changed_image != null:
		if completed:
			picture.texture = _state_texture(true)
		_changed_image.queue_free()
		_changed_image = null


func _label(node_name: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("071022"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(label)
	return label
