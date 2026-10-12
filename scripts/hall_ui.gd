extends CanvasLayer
## Keyboard-only, mutually exclusive overlays for the Library Hall prototype.

const NOTEBOOK_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/ui/notebook-panel.png")
const SHEET_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/maintenance-sheet.png")
const INK := Color("2b304c")
const CREAM := Color("fff4db")
const GOLD := Color("f5dba6")

var prompt: Label
var hint: Label
var dialogue: Control
var dialogue_panel: Panel
var dialogue_tail: Polygon2D
var dialogue_tail_outline: Line2D
var dialogue_text: Label
var dialogue_continue: Label
var sheet: Control
var journal: Control
var journal_progress: Label
var journal_entries: Label
var pause_menu: Control
var hint_deadline: int = 0


func _ready() -> void:
	layer = 20
	var canvas := Control.new()
	canvas.name = "Canvas"
	canvas.size = Vector2(1672, 941)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)

	prompt = _label(canvas, Rect2(0, 0, 320, 52), "", 27, CREAM)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.1, 1.0))
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 3)
	prompt.visible = false

	hint = _label(canvas, Rect2(1160, 60, 410, 48), "", 25, GOLD)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.visible = false

	dialogue = Control.new()
	dialogue.name = "Dialogue"
	dialogue.size = Vector2(1672, 941)
	dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(dialogue)
	dialogue_tail = Polygon2D.new()
	dialogue_tail.color = CREAM
	dialogue_tail.antialiased = true
	dialogue.add_child(dialogue_tail)
	dialogue_panel = Panel.new()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = CREAM
	bubble_style.border_color = INK
	bubble_style.set_border_width_all(4)
	bubble_style.set_corner_radius_all(22)
	bubble_style.shadow_color = Color(INK, 0.48)
	bubble_style.shadow_size = 9
	bubble_style.shadow_offset = Vector2(0, 6)
	dialogue_panel.add_theme_stylebox_override("panel", bubble_style)
	dialogue.add_child(dialogue_panel)
	dialogue_tail_outline = Line2D.new()
	dialogue_tail_outline.width = 4.0
	dialogue_tail_outline.default_color = INK
	dialogue_tail_outline.antialiased = true
	dialogue.add_child(dialogue_tail_outline)
	dialogue_text = _label(dialogue_panel, Rect2(34, 22, 692, 122), "", 29, INK)
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_continue = _label(dialogue_panel, Rect2(490, 145, 234, 28), "ENTER  ›", 18, INK)
	dialogue_continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue.visible = false

	sheet = Control.new()
	sheet.name = "SheetInspection"
	sheet.size = Vector2(1672, 941)
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sheet)
	_dim(sheet)
	var cropped_sheet := AtlasTexture.new()
	cropped_sheet.atlas = SHEET_TEXTURE
	cropped_sheet.region = Rect2(344, 73, 714, 978)
	_texture(sheet, cropped_sheet, Rect2(556, 67, 560, 805))
	_label(sheet, Rect2(661, 226, 370, 57), "EVENING CHECKS", 30, INK)
	var items := ["Lamps", "Pipes", "Pressure", "Doors", "Upper Shelves"]
	for i in items.size():
		_label(sheet, Rect2(682, 298 + i * 97, 352, 48), items[i], 29, INK)
	_label(sheet, Rect2(615, 790, 440, 40), "ESC / ENTER   CLOSE", 20, INK)
	sheet.visible = false

	journal = Control.new()
	journal.name = "Journal"
	journal.size = Vector2(1672, 941)
	journal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(journal)
	_dim(journal)
	_texture(journal, NOTEBOOK_TEXTURE, Rect2(240, 105, 1192, 795))
	_label(journal, Rect2(380, 227, 430, 58), "EVENING ROUNDS", 33, INK)
	journal_progress = _label(journal, Rect2(383, 310, 440, 275), "0 / 3 inspected", 27, INK)
	_label(journal, Rect2(884, 220, 400, 48), "OBSERVATIONS", 30, INK)
	journal_entries = _label(journal, Rect2(879, 292, 414, 450), "", 25, INK)
	_label(journal, Rect2(578, 700, 505, 40), "J / ESC   CLOSE", 20, INK)
	journal.visible = false

	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.size = Vector2(1672, 941)
	pause_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(pause_menu)
	_dim(pause_menu)
	_label(pause_menu, Rect2(630, 340, 415, 76), "PAUSED", 49, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(pause_menu, Rect2(540, 445, 595, 65), "ENTER / ESC   RESUME", 29, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(pause_menu, Rect2(540, 510, 595, 65), "Q   QUIT GAME", 25, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu.visible = false


func _process(_delta: float) -> void:
	if hint.visible and Time.get_ticks_msec() >= hint_deadline:
		hint.visible = false


func show_prompt(name: String, screen_x: float) -> void:
	prompt.text = "E  INSPECT  ·  " + name.to_upper()
	prompt.position = Vector2(clampf(screen_x - 160.0, 24.0, 1328.0), 415)
	prompt.visible = true


func hide_prompt() -> void:
	prompt.visible = false


func show_hint(message: String, seconds: float = 4.0) -> void:
	hint.text = message
	hint_deadline = Time.get_ticks_msec() + int(seconds * 1000.0)
	hint.visible = true


func show_dialogue(line: String, speaker_position: Vector2) -> void:
	hide_modals()
	dialogue_text.text = line
	var bubble_size := Vector2(760, 190)
	var bubble_position := Vector2(
		clampf(speaker_position.x - bubble_size.x * 0.5, 24.0, 888.0),
		clampf(speaker_position.y - 520.0, 35.0, 570.0)
	)
	dialogue_panel.position = bubble_position
	dialogue_panel.size = bubble_size
	var tail_x := clampf(speaker_position.x - bubble_position.x, 70.0, bubble_size.x - 70.0)
	dialogue_tail.position = bubble_position
	dialogue_tail.polygon = PackedVector2Array([
		Vector2(tail_x - 23.0, bubble_size.y - 3.0),
		Vector2(tail_x + 23.0, bubble_size.y - 3.0),
		Vector2(tail_x + 2.0, bubble_size.y + 36.0)
	])
	dialogue_tail_outline.position = bubble_position
	dialogue_tail_outline.points = PackedVector2Array([
		Vector2(tail_x - 23.0, bubble_size.y - 2.0),
		Vector2(tail_x + 2.0, bubble_size.y + 36.0),
		Vector2(tail_x + 23.0, bubble_size.y - 2.0)
	])
	dialogue.visible = true
	hide_prompt()


func show_sheet() -> void:
	hide_modals()
	sheet.visible = true
	hide_prompt()


func show_journal(entries: Array) -> void:
	hide_modals()
	var discovered: Dictionary = {}
	for entry in entries:
		discovered[entry["id"]] = true
	journal_progress.text = "%d / 3 inspected\n\n%s  Archive door\n%s  Old clock\n%s  Maintenance sheet" % [
		entries.size(),
		"[x]" if discovered.has(&"archive-door") else "[ ]",
		"[x]" if discovered.has(&"clock-housing") else "[ ]",
		"[x]" if discovered.has(&"maintenance-sheet") else "[ ]"
	]
	var lines := PackedStringArray()
	for entry in entries:
		lines.append("• %s\n%s" % [entry["title"], entry["body"]])
	journal_entries.text = "\n\n".join(lines) if not lines.is_empty() else "Nothing recorded yet.\n\nLook around the hall and press E near an object."
	journal.visible = true
	hide_prompt()


func show_pause() -> void:
	hide_modals()
	pause_menu.visible = true
	hide_prompt()


func hide_modals() -> void:
	dialogue.visible = false
	sheet.visible = false
	journal.visible = false
	pause_menu.visible = false
	hint.visible = false


func _dim(parent: Control) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.09, 0.76)
	shade.size = Vector2(1672, 941)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)


func _texture(parent: Control, asset: Texture2D, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = asset
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2.ZERO
	parent.add_child(picture)
	picture.position = rect.position
	picture.size = rect.size
	return picture


func _label(parent: Control, rect: Rect2, value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.position = rect.position
	result.size = rect.size
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result
