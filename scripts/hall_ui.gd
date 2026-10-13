extends CanvasLayer
## Keyboard-only, mutually exclusive overlays for the Library Hall prototype.

const NOTEBOOK_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/ui/notebook-panel.png")
const SHEET_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/maintenance-sheet.png")
const GAUGE_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/gauge-face.png")
const NEWTON_NOTE_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/newton-note.png")
const HALL_NOTE_IDS := [&"archive-door", &"clock-housing", &"maintenance-sheet"]
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
var gauge_inspection: Control
var gauge_status: Label
var gauge_instruction: Label
var journal: Control
var journal_progress: Label
var journal_scroll: ScrollContainer
var journal_entries: RichTextLabel
var torn_page: Control
var torn_page_instruction: Label
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

	gauge_inspection = Control.new()
	gauge_inspection.name = "GaugeInspection"
	gauge_inspection.size = Vector2(1672, 941)
	gauge_inspection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(gauge_inspection)
	_dim(gauge_inspection)
	var gauge_panel := Panel.new()
	gauge_panel.position = Vector2(266, 146)
	gauge_panel.size = Vector2(1140, 650)
	gauge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gauge_style := StyleBoxFlat.new()
	gauge_style.bg_color = Color("f7edda")
	gauge_style.border_color = INK
	gauge_style.set_border_width_all(5)
	gauge_style.set_corner_radius_all(18)
	gauge_style.shadow_color = Color(INK, 0.6)
	gauge_style.shadow_size = 14
	gauge_panel.add_theme_stylebox_override("panel", gauge_style)
	gauge_inspection.add_child(gauge_panel)
	_texture(gauge_panel, GAUGE_TEXTURE, Rect2(90, 130, 470, 361))
	var dial_center := Vector2(325, 310)
	var old_mark := Line2D.new()
	old_mark.position = dial_center
	old_mark.points = PackedVector2Array([Vector2.ZERO, Vector2(126, 0)])
	old_mark.rotation = -1.5
	old_mark.width = 5.0
	old_mark.default_color = Color("697087")
	old_mark.antialiased = true
	gauge_panel.add_child(old_mark)
	var live_needle := Line2D.new()
	live_needle.position = dial_center
	live_needle.points = PackedVector2Array([Vector2.ZERO, Vector2(137, 0)])
	live_needle.rotation = -1.22
	live_needle.width = 7.0
	live_needle.default_color = Color("942f48")
	live_needle.antialiased = true
	gauge_panel.add_child(live_needle)
	var hub := Panel.new()
	hub.position = dial_center - Vector2(12, 12)
	hub.size = Vector2(24, 24)
	hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hub_style := StyleBoxFlat.new()
	hub_style.bg_color = Color("c8943e")
	hub_style.set_corner_radius_all(12)
	hub.add_theme_stylebox_override("panel", hub_style)
	gauge_panel.add_child(hub)
	_label(gauge_panel, Rect2(625, 105, 450, 52), "MACHINE ROOM · DIAL", 28, INK)
	_label(gauge_panel, Rect2(625, 176, 450, 55), "LAST ENTRY", 20, Color("697087"))
	_label(gauge_panel, Rect2(625, 220, 450, 58), "Pencil mark: one division lower", 25, INK)
	_label(gauge_panel, Rect2(625, 312, 450, 55), "CURRENT NEEDLE", 20, Color("942f48"))
	gauge_status = _label(gauge_panel, Rect2(625, 357, 450, 92), "Below the red sector. Compare it with the mark before writing.", 25, INK)
	gauge_instruction = _label(gauge_panel, Rect2(625, 535, 450, 42), "ENTER  RECORD READING", 20, INK)
	_label(gauge_panel, Rect2(625, 580, 450, 38), "ESC  BACK", 18, Color("697087"))
	gauge_inspection.visible = false

	journal = Control.new()
	journal.name = "Journal"
	journal.size = Vector2(1672, 941)
	journal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(journal)
	_dim(journal)
	_texture(journal, NOTEBOOK_TEXTURE, Rect2(240, 105, 1192, 795))
	_label(journal, Rect2(380, 227, 430, 58), "EVENING ROUNDS", 33, INK)
	journal_progress = _label(journal, Rect2(383, 310, 440, 390), "0 / 3 inspected", 25, INK)
	_label(journal, Rect2(884, 220, 400, 48), "OBSERVATIONS", 30, INK)
	journal_scroll = ScrollContainer.new()
	journal_scroll.position = Vector2(879, 292)
	journal_scroll.size = Vector2(414, 390)
	journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	journal_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal.add_child(journal_scroll)
	journal_entries = RichTextLabel.new()
	journal_entries.fit_content = true
	journal_entries.scroll_active = false
	journal_entries.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_entries.add_theme_font_size_override("normal_font_size", 25)
	journal_entries.add_theme_color_override("default_color", INK)
	journal_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_entries.custom_minimum_size.x = 390.0
	journal_entries.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal_scroll.add_child(journal_entries)
	_label(journal, Rect2(578, 700, 505, 40), "J / ESC   CLOSE  ·  ↑ / ↓ SCROLL  ·  ENTER PAGE", 18, INK)
	journal.visible = false

	torn_page = Control.new()
	torn_page.name = "TornPage"
	torn_page.size = Vector2(1672, 941)
	torn_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(torn_page)
	_dim(torn_page)
	var page_panel := Panel.new()
	page_panel.position = Vector2(251, 112)
	page_panel.size = Vector2(1170, 718)
	page_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color("f7edda")
	page_style.border_color = INK
	page_style.set_border_width_all(5)
	page_style.set_corner_radius_all(18)
	page_style.shadow_color = Color(INK, 0.6)
	page_style.shadow_size = 14
	page_panel.add_theme_stylebox_override("panel", page_style)
	torn_page.add_child(page_panel)
	_texture(page_panel, NEWTON_NOTE_TEXTURE, Rect2(54, 78, 490, 560))
	_label(page_panel, Rect2(584, 69, 520, 52), "A PAGE FROM KATH'S OLD NOTES", 27, INK)
	var equation := _label(page_panel, Rect2(584, 128, 520, 66), "F = ma", 43, INK)
	equation.add_theme_font_size_override("font_size", 43)
	var page_text := _label(page_panel, Rect2(584, 207, 520, 348), "First measurement wrong. Checked the rope. Still a difference.\n\nDon't erase it. Record the second attempt too.\n\nNext time at the castle, try again.\n\n— Kath", 24, INK)
	page_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	torn_page_instruction = _label(page_panel, Rect2(584, 605, 520, 43), "ENTER  KEEP PAGE     ·     ESC  CLOSE", 20, INK)
	torn_page.visible = false

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


func show_prompt(name: String, screen_x: float, action: String = "INSPECT", screen_y: float = 415.0) -> void:
	prompt.text = "E  %s  ·  %s" % [action, name.to_upper()]
	prompt.position = Vector2(clampf(screen_x - 160.0, 24.0, 1328.0), clampf(screen_y, 24.0, 865.0))
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


func show_gauge_inspection(recorded: bool) -> void:
	hide_modals()
	if recorded:
		gauge_instruction.text = "ENTER  CLOSE"
		gauge_status.text = "The mark is in the notebook. The needle remains below the red sector."
	else:
		gauge_instruction.text = "ENTER  RECORD READING"
		gauge_status.text = "Below the red sector. Compare it with the mark before writing."
	gauge_inspection.visible = true
	hide_prompt()


func show_journal(entries: Array, hall_complete: bool, machine_recorded: bool, leak_contained: bool = false, page_collected: bool = false) -> void:
	hide_modals()
	var discovered: Dictionary = {}
	for entry in entries:
		discovered[entry["id"]] = true
	var hall_count := 0
	for note_id in HALL_NOTE_IDS:
		if discovered.has(note_id):
			hall_count += 1
	journal_progress.text = "HALL PATROL  %d / 3\n%s  Archive door\n%s  Old clock\n%s  Maintenance sheet\n\nMACHINE ROOM  %s\n\nUPPER STACKS  %d / 2\n%s  Leak caught\n%s  Page recovered" % [
		hall_count,
		"[x]" if discovered.has(&"archive-door") else "[ ]",
		"[x]" if discovered.has(&"clock-housing") else "[ ]",
		"[x]" if discovered.has(&"maintenance-sheet") else "[ ]",
		"1 / 1  Reading recorded" if machine_recorded else "0 / 1  Reading pending",
		int(leak_contained) + int(page_collected),
		"[x]" if leak_contained else "[ ]",
		"[x]" if page_collected else "[ ]"
	]
	if hall_complete and hall_count == 3:
		journal_progress.text = journal_progress.text.replace("HALL PATROL  3 / 3", "HALL PATROL  3 / 3  COMPLETE")
	var lines := PackedStringArray()
	for entry in entries:
		lines.append("• %s\n%s" % [entry["title"], entry["body"]])
	journal_entries.text = "\n\n".join(lines) if not lines.is_empty() else "Nothing recorded yet.\n\nLook around the hall and press E near an object."
	journal_scroll.scroll_vertical = 0
	journal.visible = true
	hide_prompt()


func show_torn_page(from_journal: bool) -> void:
	hide_modals()
	torn_page_instruction.text = "ESC  BACK TO NOTES" if from_journal else "ENTER  KEEP PAGE     ·     ESC  CLOSE"
	torn_page.visible = true
	hide_prompt()


func scroll_journal(direction: int) -> void:
	journal_scroll.scroll_vertical = maxi(0, journal_scroll.scroll_vertical + direction * 72)


func show_pause() -> void:
	hide_modals()
	pause_menu.visible = true
	hide_prompt()


func hide_modals() -> void:
	dialogue.visible = false
	sheet.visible = false
	gauge_inspection.visible = false
	journal.visible = false
	torn_page.visible = false
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
