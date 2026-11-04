extends CanvasLayer
## The patrol book has a live task page, a filed archive, and a red emergency tab.

signal dismissed
signal stamped
signal page_turned(page_name: StringName)

const PAGE_SHEET: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/round-book-page-states.png")
const EMERGENCY_PAGE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/round-book-emergency-page.png")
const STAMP_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/layer-round-stamp.png")
const INK := Color("33314a")
const RED := Color("9b3547")
const GOLD := Color("f5dba6")

var screen: Control
var shade: ColorRect
var picture: TextureRect
var task_title: Label
var task_rows: Array[Label] = []
var task_marks: Array[Label] = []
var archived_stamp: Label
var blank_label: Label
var emergency_title: Label
var emergency_body: Label
var page_instruction: Label
var status_label: Label
var stamp_image: TextureRect
var page_kind: StringName = &"current"
var filed := false
var tasks := [false, false, false]
var door_secured := false
var window_secured := false
var busy := false
var _tween: Tween


func _ready() -> void:
	layer = 31
	screen = Control.new()
	screen.size = Vector2(1672, 941)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	shade = ColorRect.new()
	shade.size = screen.size
	shade.color = Color(0.04, 0.06, 0.12, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(shade)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(picture)
	task_title = _label(Rect2(626, 143, 470, 62), 36, INK)
	for i in 3:
		task_marks.append(_label(Rect2(590, 240 + i * 150, 72, 70), 43, RED))
		task_rows.append(_label(Rect2(675, 238 + i * 150, 450, 104), 28, INK))
	archived_stamp = _label(Rect2(670, 704, 390, 64), 44, RED)
	archived_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blank_label = _label(Rect2(630, 320, 450, 150), 31, INK)
	blank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emergency_title = _label(Rect2(370, 253, 930, 70), 43, RED)
	emergency_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emergency_body = _label(Rect2(348, 355, 974, 270), 37, INK)
	emergency_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_instruction = _label(Rect2(1200, 250, 400, 240), 25, GOLD)
	status_label = _label(Rect2(180, 864, 1320, 50), 24, GOLD)
	stamp_image = TextureRect.new()
	stamp_image.texture = STAMP_TEXTURE
	stamp_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stamp_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stamp_image.position = Vector2(835, 485)
	stamp_image.size = Vector2(185, 220)
	stamp_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(stamp_image)
	stamp_image.visible = false
	screen.visible = false


func open_view(door_done: bool, window_done: bool, clock_done: bool, keys_done: bool, already_filed: bool) -> void:
	_stop_tween()
	door_secured = door_done
	window_secured = window_done
	tasks = [door_done and window_done, clock_done, keys_done]
	filed = already_filed
	page_kind = &"current"
	busy = false
	screen.visible = true
	screen.modulate.a = 0.0
	_refresh()
	_tween = create_tween()
	_tween.tween_property(screen, "modulate:a", 1.0, 0.18)


func turn(direction: int) -> void:
	if not screen.visible or busy:
		return
	var pages: Array = [&"current", &"archive", &"emergency"] if filed else [&"current", &"emergency"]
	page_kind = pages[posmod(pages.find(page_kind) + direction, pages.size())]
	_refresh()
	page_turned.emit(page_kind)


func act() -> void:
	if not screen.visible or busy:
		return
	if page_kind != &"current":
		page_kind = &"current"
		_refresh()
		page_turned.emit(page_kind)
		return
	if filed:
		page_kind = &"emergency"
		_refresh()
		page_turned.emit(page_kind)
		return
	if not tasks.all(func(done: bool) -> bool: return done):
		status_label.text = "Complete the unchecked tasks before filing this round."
		return
	busy = true
	stamp_image.visible = true
	stamp_image.modulate.a = 1.0
	stamp_image.position.y = 450.0
	_tween = create_tween()
	_tween.tween_property(stamp_image, "position:y", 564.0, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_interval(0.12)
	_tween.tween_callback(func() -> void:
		stamp_image.visible = false
		filed = true
		page_kind = &"archive"
		_refresh()
		stamped.emit()
	)
	_tween.tween_interval(0.65)
	_tween.tween_callback(func() -> void:
		if page_kind == &"archive":
			page_kind = &"current"
			_refresh()
		busy = false
	)


func close_view() -> void:
	if not screen.visible:
		return
	_stop_tween()
	stamp_image.visible = false
	busy = false
	_tween = create_tween()
	_tween.tween_property(screen, "modulate:a", 0.0, 0.14)
	_tween.tween_callback(func() -> void:
		screen.visible = false
		dismissed.emit()
	)


func _refresh() -> void:
	var emergency := page_kind == &"emergency"
	var archive := page_kind == &"archive"
	picture.texture = EMERGENCY_PAGE if emergency else _page_texture(filed and not archive)
	picture.position = Vector2(155, 86) if emergency else Vector2(470, 66)
	picture.size = Vector2(1362, 768) if emergency else Vector2(710, 800)
	task_title.visible = not emergency and (archive or not filed)
	task_title.text = "EVENING ROUND" if not archive else "FILED ROUND"
	for i in 3:
		var show_tasks := not emergency and (archive or not filed)
		task_marks[i].visible = show_tasks
		task_rows[i].visible = show_tasks
		task_marks[i].text = "✓" if tasks[i] else ""
	task_rows[0].text = "Check doors and windows\nDoor %s · Window %s" % ["latched" if door_secured else "loose", "fixed" if window_secured else "loose"]
	task_rows[1].text = "Wind the hall clock"
	task_rows[2].text = "Check the duty keys"
	archived_stamp.visible = archive
	archived_stamp.text = "ROUND FILED"
	blank_label.visible = filed and not archive and not emergency
	blank_label.text = "Current task page is blank."
	emergency_title.visible = emergency
	emergency_title.text = "EMERGENCY PROCEDURE"
	emergency_body.visible = emergency
	emergency_body.text = "If the upper needle crosses the red line,\npull lever 2, then lever 4.\n\nCheck the needle again."
	page_instruction.visible = not emergency
	if emergency:
		status_label.text = "← / →  TURN PAGE   ·   E  RETURN TO TASKS   ·   ESC  CLOSE"
	elif archive:
		page_instruction.text = "ARCHIVED ROUND\n\n← / →  TURN PAGE\nE  CURRENT PAGE\nESC  CLOSE"
		status_label.text = "The completed list remains available for review."
	elif filed:
		page_instruction.text = "CURRENT TASKS\n\nE  OPEN RED TAB\n← / →  TURN PAGE\nESC  CLOSE"
		status_label.text = "The filed list is in the archive. No new tasks are assigned."
	else:
		page_instruction.text = "EVENING ROUND\n\nE  STAMP WHEN READY\n← / →  RED TAB\nESC  CLOSE"
		status_label.text = "%d / 3 checks complete" % tasks.count(true)


func _page_texture(after: bool) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = PAGE_SHEET
	result.region = Rect2(836 if after else 0, 0, 836, 941)
	return result


func _label(rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(label)
	return label


func _stop_tween() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
