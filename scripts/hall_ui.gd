extends CanvasLayer
## Shared story UI for the prologue and Chapter I.

const StoryGuide = preload("res://scripts/story_guide.gd")

const NOTEBOOK_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/ui/notebook-panel.png")
const SHEET_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/maintenance-sheet.png")
const GAUGE_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/gauge-face.png")
const NEWTON_NOTE_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/newton-note.png")
const CASTLE_WING_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/props/castle-wing-upright.png")
const SERVICE_ROAD_FAR: Texture2D = preload("res://prologue-asset-pack-v1/far/05-service-road-far.png")
const HALL_NOTE_IDS := [&"archive-door", &"clock-housing", &"maintenance-sheet"]
const INK := Color("2b304c")
const CREAM := Color("fff4db")
const GOLD := Color("f5dba6")

var prompt: Label
var hint: Label
var discovery_markers: Array[Control] = []
var guide_bubble: Panel
var guide_text: Label
var guide_deadline := 0
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
var journal_progress_scroll: ScrollContainer
var journal_scroll: ScrollContainer
var journal_entries: RichTextLabel
var torn_page: Control
var torn_page_instruction: Label
var notebook_comparison: Control
var chapter1_notebook: Control
var shaft_winch: Control
var shaft_winch_status: Label
var shaft_winch_measure: Label
var shaft_winch_instruction: Label
var shaft_winch_fill: ColorRect
var shaft_winch_path: Label
var shaft_winch_footer: Label
var shaft_load_check: Control
var shaft_load_selection: Label
var shaft_load_detail: Label
var shaft_rigging: Control
var shaft_rigging_status: Label
var engine_panel: Control
var engine_title: Label
var engine_body: Label
var engine_status: Label
var engine_footer: Label
var emergency_console: Control
var emergency_status: Label
var emergency_selection: Label
var castle_rotation: Control
var chapter_end: Control
var chapter1_end: Control
var pause_menu: Control
var pause_save_error: Label
var hint_deadline: int = 0
var objective_id := ""
var objective_idle_seconds := 0.0
var objective_reminder_shown := false
var hint_level := 0


func _ready() -> void:
	layer = 20
	var canvas := Control.new()
	canvas.name = "Canvas"
	canvas.size = Vector2(1672, 941)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)

	prompt = _label(canvas, Rect2(0, 0, 480, 74), "", 22, CREAM)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.1, 1.0))
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 3)
	prompt.visible = false

	hint = _label(canvas, Rect2(1040, 54, 550, 128), "", 22, GOLD)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.1, 0.95))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 3)
	hint.visible = false

	for i in 2:
		var marker := _make_discovery_marker(canvas)
		marker.visible = false
		discovery_markers.append(marker)
	guide_bubble = Panel.new()
	guide_bubble.size = Vector2(590, 140)
	guide_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thought_style := StyleBoxFlat.new()
	thought_style.bg_color = CREAM
	thought_style.border_color = INK
	thought_style.set_border_width_all(3)
	thought_style.set_corner_radius_all(17)
	thought_style.shadow_color = Color(INK, 0.35)
	thought_style.shadow_size = 6
	guide_bubble.add_theme_stylebox_override("panel", thought_style)
	canvas.add_child(guide_bubble)
	var thought_tail := Polygon2D.new()
	thought_tail.position = Vector2(58, 137)
	thought_tail.polygon = PackedVector2Array([Vector2(0, 0), Vector2(25, 0), Vector2(8, 20)])
	thought_tail.color = CREAM
	thought_tail.antialiased = true
	guide_bubble.add_child(thought_tail)
	guide_text = _label(guide_bubble, Rect2(22, 10, 546, 120), "", 21, INK)
	guide_bubble.visible = false

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
	journal_progress_scroll = ScrollContainer.new()
	journal_progress_scroll.position = Vector2(383, 310)
	journal_progress_scroll.size = Vector2(440, 390)
	journal_progress_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	journal_progress_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal.add_child(journal_progress_scroll)
	journal_progress = _label(journal_progress_scroll, Rect2(0, 0, 418, 390), "0 / 3 inspected", 25, INK)
	journal_progress.custom_minimum_size = Vector2(418, 390)
	journal_progress.vertical_alignment = VERTICAL_ALIGNMENT_TOP
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
	page_panel.name = "PagePanel"
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
	_add_incomplete_hoist_sketch(page_panel)
	_label(page_panel, Rect2(584, 69, 520, 52), "A PAGE FROM KATH'S OLD NOTES", 27, INK)
	var equation := _label(page_panel, Rect2(584, 128, 520, 66), "F = ma", 43, INK)
	equation.add_theme_font_size_override("font_size", 43)
	var page_text := _label(page_panel, Rect2(584, 207, 520, 348), "First measurement wrong. Checked the rope. Still a difference.\n\nDon't erase it. Record the second attempt too.\n\nNext time at the castle, try again.\n\n— Kath", 24, INK)
	page_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	torn_page_instruction = _label(page_panel, Rect2(584, 605, 520, 43), "ENTER  KEEP PAGE     ·     ESC  CLOSE", 20, INK)
	torn_page.visible = false

	notebook_comparison = Control.new()
	notebook_comparison.name = "NotebookComparison"
	notebook_comparison.size = Vector2(1672, 941)
	notebook_comparison.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(notebook_comparison)
	_dim(notebook_comparison)
	var comparison_panel := Panel.new()
	comparison_panel.position = Vector2(236, 112)
	comparison_panel.size = Vector2(1200, 718)
	comparison_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var comparison_style := StyleBoxFlat.new()
	comparison_style.bg_color = Color("f7edda")
	comparison_style.border_color = INK
	comparison_style.set_border_width_all(5)
	comparison_style.set_corner_radius_all(18)
	comparison_panel.add_theme_stylebox_override("panel", comparison_style)
	notebook_comparison.add_child(comparison_panel)
	_label(comparison_panel, Rect2(62, 30, 1076, 52), "TWO PAGES · ONE MISSING LEAF", 30, INK)
	_texture(comparison_panel, NEWTON_NOTE_TEXTURE, Rect2(62, 104, 435, 490))
	_texture(comparison_panel, NOTEBOOK_TEXTURE, Rect2(560, 104, 575, 490))
	_label(comparison_panel, Rect2(587, 178, 500, 300), "The torn edge fits the empty place in my notebook.\n\nA route entry remains beneath it: OBSERVATORY CASTLE — return visit pending.\n\nThe handwriting is mine. I still don't know what F = ma means.", 24, INK)
	_label(comparison_panel, Rect2(300, 620, 600, 45), "ENTER  RECORD MATCH     ·     ESC  CLOSE", 20, INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notebook_comparison.visible = false

	chapter1_notebook = Control.new()
	chapter1_notebook.name = "Chapter1Notebook"
	chapter1_notebook.size = Vector2(1672, 941)
	chapter1_notebook.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(chapter1_notebook)
	_dim(chapter1_notebook)
	_texture(chapter1_notebook, NOTEBOOK_TEXTURE, Rect2(230, 84, 1212, 810))
	_label(chapter1_notebook, Rect2(356, 198, 465, 55), "THE MISSING LEAF", 33, INK)
	_texture(chapter1_notebook, NEWTON_NOTE_TEXTURE, Rect2(360, 270, 390, 397))
	_label(chapter1_notebook, Rect2(370, 683, 420, 56), "F = ma  ·  Kath's old hand", 24, INK)
	_label(chapter1_notebook, Rect2(870, 204, 440, 50), "NOTES FROM THIS VISIT", 29, INK)
	_label(chapter1_notebook, Rect2(880, 276, 420, 415), "Same empty basket: two support\nstrands used more rope per rise.\n\nWith Erin aboard, rope tension\nchanged. Weight pulls downward;\nthe dial reads neither mass nor\nweight directly.\n\nBraking changed our speed.\nCould F be net force?\nFriction remains unmeasured.", 21, INK)
	_label(chapter1_notebook, Rect2(875, 708, 420, 35), "ENTER  STITCH PAGE     ·     ESC  CLOSE", 18, INK)
	chapter1_notebook.visible = false

	shaft_winch = Control.new()
	shaft_winch.name = "ShaftWinch"
	shaft_winch.size = Vector2(1672, 941)
	shaft_winch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shaft_winch)
	_dim(shaft_winch)
	var winch_panel := Panel.new()
	winch_panel.position = Vector2(366, 205)
	winch_panel.size = Vector2(940, 530)
	winch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var winch_style := StyleBoxFlat.new()
	winch_style.bg_color = Color("1c2944")
	winch_style.border_color = Color("bd9257")
	winch_style.set_border_width_all(6)
	winch_style.set_corner_radius_all(16)
	winch_style.shadow_color = Color(INK, 0.65)
	winch_style.shadow_size = 16
	winch_panel.add_theme_stylebox_override("panel", winch_style)
	shaft_winch.add_child(winch_panel)
	_label(winch_panel, Rect2(65, 42, 810, 50), "MAINTENANCE SHAFT · HAND WINCH", 31, GOLD)
	shaft_winch_path = _label(winch_panel, Rect2(65, 108, 810, 70), "One cable crosses the fixed pulley and holds the basket.", 25, CREAM)
	var winch_track := ColorRect.new()
	winch_track.position = Vector2(120, 237)
	winch_track.size = Vector2(700, 26)
	winch_track.color = Color("58637b")
	winch_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	winch_panel.add_child(winch_track)
	shaft_winch_fill = ColorRect.new()
	shaft_winch_fill.position = winch_track.position
	shaft_winch_fill.size = Vector2(0, 26)
	shaft_winch_fill.color = Color("b67e43")
	shaft_winch_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	winch_panel.add_child(shaft_winch_fill)
	_label(winch_panel, Rect2(93, 190, 300, 37), "LOWER BERTH", 19, GOLD)
	_label(winch_panel, Rect2(650, 190, 200, 37), "ERIN'S LEDGE", 19, GOLD)
	shaft_winch_status = _label(winch_panel, Rect2(80, 290, 780, 62), "", 26, CREAM)
	shaft_winch_measure = _label(winch_panel, Rect2(80, 351, 780, 36), "", 20, GOLD)
	shaft_winch_instruction = _label(winch_panel, Rect2(80, 393, 780, 50), "", 22, CREAM)
	shaft_winch_footer = _label(winch_panel, Rect2(80, 450, 780, 38), "ESC  CLOSE  ·  Release keys to hold position", 19, GOLD)
	shaft_winch.visible = false

	shaft_load_check = Control.new()
	shaft_load_check.name = "ShaftLoadCheck"
	shaft_load_check.size = Vector2(1672, 941)
	shaft_load_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shaft_load_check)
	_dim(shaft_load_check)
	var load_panel := Panel.new()
	load_panel.position = Vector2(346, 185)
	load_panel.size = Vector2(980, 570)
	load_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var load_style := StyleBoxFlat.new()
	load_style.bg_color = Color("1c2944")
	load_style.border_color = Color("bd9257")
	load_style.set_border_width_all(6)
	load_style.set_corner_radius_all(16)
	load_panel.add_theme_stylebox_override("panel", load_style)
	shaft_load_check.add_child(load_panel)
	_label(load_panel, Rect2(65, 34, 850, 50), "CHECK THE LOAD · UPPER CATCH SECURED", 29, GOLD)
	_label(load_panel, Rect2(65, 93, 850, 68), "The rope is taut. Check what still supports the occupied basket before Erin releases the catch.", 23, CREAM)
	shaft_load_selection = _label(load_panel, Rect2(78, 188, 830, 202), "", 27, CREAM)
	shaft_load_detail = _label(load_panel, Rect2(78, 404, 830, 67), "", 22, GOLD)
	_label(load_panel, Rect2(78, 510, 830, 36), "← / →  SELECT     ·     E  CHECK     ·     ENTER  CONFIRM     ·     ESC  CANCEL", 18, GOLD)
	shaft_load_check.visible = false

	shaft_rigging = Control.new()
	shaft_rigging.name = "ShaftRigging"
	shaft_rigging.size = Vector2(1672, 941)
	shaft_rigging.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shaft_rigging)
	_dim(shaft_rigging)
	var rig_panel := Panel.new()
	rig_panel.position = Vector2(326, 172)
	rig_panel.size = Vector2(1020, 590)
	rig_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rig_style := StyleBoxFlat.new()
	rig_style.bg_color = Color("1c2944")
	rig_style.border_color = Color("bd9257")
	rig_style.set_border_width_all(6)
	rig_style.set_corner_radius_all(16)
	rig_panel.add_theme_stylebox_override("panel", rig_style)
	shaft_rigging.add_child(rig_panel)
	_label(rig_panel, Rect2(65, 35, 900, 55), "PASSENGER ROPE · MAINTENANCE GUIDE", 30, GOLD)
	_label(rig_panel, Rect2(72, 105, 880, 100), "The empty basket is locked to the lower dock. Pull the long rope along the thin pilot line from this platform.", 25, CREAM)
	var diagram := Line2D.new()
	diagram.points = PackedVector2Array([Vector2(180, 274), Vector2(346, 230), Vector2(420, 345), Vector2(510, 345), Vector2(580, 230), Vector2(765, 274)])
	diagram.width = 7.0
	diagram.default_color = Color("d1a96f")
	diagram.antialiased = true
	rig_panel.add_child(diagram)
	_label(rig_panel, Rect2(72, 355, 880, 60), "WINCH   →   FIXED WHEEL   →   BASKET WHEEL   →   TOP ANCHOR", 21, GOLD)
	shaft_rigging_status = _label(rig_panel, Rect2(72, 425, 880, 75), "", 24, CREAM)
	_label(rig_panel, Rect2(72, 525, 880, 38), "ENTER  CONTINUE     ·     ESC  CANCEL", 19, GOLD)
	shaft_rigging.visible = false

	engine_panel = Control.new()
	engine_panel.name = "EngineMaintenance"
	engine_panel.size = Vector2(1672, 941)
	engine_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(engine_panel)
	_dim(engine_panel)
	(engine_panel.get_child(0) as ColorRect).color = Color(0.025, 0.035, 0.09, 0.48)
	var engine_card := Panel.new()
	engine_card.position = Vector2(65, 170)
	engine_card.size = Vector2(965, 600)
	engine_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var engine_style := StyleBoxFlat.new()
	engine_style.bg_color = Color("182639")
	engine_style.border_color = Color("b28755")
	engine_style.set_border_width_all(6)
	engine_style.set_corner_radius_all(17)
	engine_card.add_theme_stylebox_override("panel", engine_style)
	engine_panel.add_child(engine_card)
	engine_title = _label(engine_card, Rect2(65, 35, 835, 53), "", 30, GOLD)
	engine_body = _label(engine_card, Rect2(65, 105, 835, 150), "", 25, CREAM)
	engine_status = _label(engine_card, Rect2(65, 275, 835, 225), "", 26, CREAM)
	engine_footer = _label(engine_card, Rect2(65, 522, 835, 52), "", 20, GOLD)
	engine_panel.visible = false

	emergency_console = Control.new()
	emergency_console.name = "EmergencyConsole"
	emergency_console.size = Vector2(1672, 941)
	emergency_console.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(emergency_console)
	_dim(emergency_console)
	var emergency_panel := Panel.new()
	emergency_panel.position = Vector2(336, 180)
	emergency_panel.size = Vector2(1000, 580)
	emergency_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var emergency_style := StyleBoxFlat.new()
	emergency_style.bg_color = Color("f7edda")
	emergency_style.border_color = INK
	emergency_style.set_border_width_all(5)
	emergency_style.set_corner_radius_all(18)
	emergency_panel.add_theme_stylebox_override("panel", emergency_style)
	emergency_console.add_child(emergency_panel)
	_label(emergency_panel, Rect2(70, 38, 860, 55), "EMERGENCY LINE CONTROL", 31, INK)
	_label(emergency_panel, Rect2(70, 105, 860, 92), "Archive auxiliary line only: open return lever 2 and isolate lever 4. If the needle keeps rising, stop this drive.", 25, INK)
	emergency_selection = _label(emergency_panel, Rect2(100, 238, 800, 70), "‹  LEVER 2 · RETURN  ›", 31, INK)
	emergency_selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emergency_status = _label(emergency_panel, Rect2(90, 340, 820, 90), "Lever 2: pending     ·     Lever 4: pending     ·     Drive: running", 24, INK)
	emergency_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(emergency_panel, Rect2(100, 470, 800, 44), "← / →  SELECT     ·     E  OPERATE     ·     ESC  CLOSE", 20, INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emergency_console.visible = false

	castle_rotation = Control.new()
	castle_rotation.name = "CastleRotation"
	castle_rotation.size = Vector2(1672, 941)
	castle_rotation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(castle_rotation)
	var rotation_backdrop := TextureRect.new()
	rotation_backdrop.texture = SERVICE_ROAD_FAR
	rotation_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rotation_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	rotation_backdrop.size = Vector2(1672, 941)
	rotation_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	castle_rotation.add_child(rotation_backdrop)
	var rotation_pivot := Node2D.new()
	rotation_pivot.name = "CastleWingPivot"
	rotation_pivot.position = Vector2(1480, 185)
	castle_rotation.add_child(rotation_pivot)
	var rotation_wing := Sprite2D.new()
	rotation_wing.texture = CASTLE_WING_TEXTURE
	rotation_wing.centered = false
	rotation_wing.scale = Vector2(0.27, 0.27)
	rotation_wing.position = Vector2(-627.0, -600.0) * rotation_wing.scale
	rotation_pivot.add_child(rotation_wing)
	_label(castle_rotation, Rect2(100, 48, 1472, 70), "OBSERVATORY CASTLE · LOCAL CONTROL SIGNAL UNSTABLE", 30, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	castle_rotation.visible = false

	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.size = Vector2(1672, 941)
	pause_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(pause_menu)
	_dim(pause_menu)
	_label(pause_menu, Rect2(630, 340, 415, 76), "PAUSED", 49, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(pause_menu, Rect2(540, 445, 595, 65), "ENTER / ESC   RESUME", 29, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(pause_menu, Rect2(540, 510, 595, 65), "S   SETTINGS", 25, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(pause_menu, Rect2(540, 573, 595, 65), "Q   SAVE & QUIT", 25, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_save_error = _label(pause_menu, Rect2(360, 650, 950, 70), "SAVE FAILED · CHECK STORAGE AND TRY AGAIN", 23, CREAM)
	pause_save_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_save_error.visible = false
	pause_menu.visible = false

	chapter_end = Control.new()
	chapter_end.name = "ChapterEnd"
	chapter_end.size = Vector2(1672, 941)
	chapter_end.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(chapter_end)
	_dim(chapter_end)
	var end_panel := Panel.new()
	end_panel.position = Vector2(336, 250)
	end_panel.size = Vector2(1000, 440)
	end_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var end_style := StyleBoxFlat.new()
	end_style.bg_color = Color("202746")
	end_style.border_color = Color("c59a58")
	end_style.set_border_width_all(4)
	end_style.set_corner_radius_all(14)
	end_panel.add_theme_stylebox_override("panel", end_style)
	chapter_end.add_child(end_panel)
	_label(end_panel, Rect2(70, 70, 860, 48), "FOOTNOTES TO THE WORLD", 25, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(end_panel, Rect2(70, 150, 860, 90), "CHAPTER I", 34, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(end_panel, Rect2(70, 230, 860, 85), "UPSIDE-DOWN CASTLE", 46, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(end_panel, Rect2(70, 335, 860, 38), "PROLOGUE COMPLETE", 22, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(end_panel, Rect2(70, 385, 860, 38), "ENTER  CONTROL WALKWAY     ·     ESC  SERVICE ROAD", 20, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_end.visible = false

	chapter1_end = Control.new()
	chapter1_end.name = "Chapter1End"
	chapter1_end.size = Vector2(1672, 941)
	chapter1_end.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(chapter1_end)
	_dim(chapter1_end)
	var chapter1_panel := Panel.new()
	chapter1_panel.position = Vector2(296, 207)
	chapter1_panel.size = Vector2(1080, 525)
	chapter1_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chapter1_style := StyleBoxFlat.new()
	chapter1_style.bg_color = Color("172536")
	chapter1_style.border_color = Color("b28755")
	chapter1_style.set_border_width_all(5)
	chapter1_style.set_corner_radius_all(18)
	chapter1_panel.add_theme_stylebox_override("panel", chapter1_style)
	chapter1_end.add_child(chapter1_panel)
	_label(chapter1_panel, Rect2(90, 58, 900, 45), "FOOTNOTES TO THE WORLD", 26, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(chapter1_panel, Rect2(90, 135, 900, 68), "CHAPTER I COMPLETE", 47, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(chapter1_panel, Rect2(105, 230, 870, 74), "UPSIDE-DOWN CASTLE", 36, CREAM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(chapter1_panel, Rect2(120, 328, 840, 65), "Next: Floating Isles · Buoyancy Station", 28, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(chapter1_panel, Rect2(120, 438, 840, 38), "ENTER / ESC  RETURN TO THE CASTLE", 21, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter1_end.visible = false


func _process(delta: float) -> void:
	if hint.visible and Time.get_ticks_msec() >= hint_deadline:
		hint.visible = false
	if guide_bubble.visible and Time.get_ticks_msec() >= guide_deadline:
		guide_bubble.visible = false
	var objective := _sync_objective()
	var scene := get_parent()
	if objective.is_empty() or scene == null or scene.get("mode") != &"roam":
		_hide_discovery()
		guide_bubble.visible = false
		return
	_update_discovery(scene, objective)
	if not get_node("/root/GameSettings").hints_enabled:
		guide_bubble.visible = false
		return
	var kath: Node2D = scene.get_node_or_null("Kath")
	if kath != null and kath.get("locomotion_mode") != &"walk":
		return
	if objective["id"] == "complete":
		return
	objective_idle_seconds += delta
	get_node("/root/PrologueState").guide_idle_seconds = objective_idle_seconds
	if not objective_reminder_shown and hint_level == 0 and objective_idle_seconds >= 75.0:
		objective_reminder_shown = true
		get_node("/root/PrologueState").guide_reminder_shown = true
		_point_wick(objective)
		var area_lead := " Try %s." % objective["next_area"] if scene.scene_file_path != objective["focus_scene"] else ""
		_show_guide("Still looking? %s.%s Press H for a closer hint, or J for your notes." % [objective["title"], area_lead], 7.0)


func _unhandled_input(event: InputEvent) -> void:
	if not get_node("/root/GameSettings").hints_enabled or not event.is_action_pressed("request_hint") or (event is InputEventKey and event.echo):
		return
	var scene := get_parent()
	if scene == null or scene.get("mode") != &"roam":
		return
	var objective := _sync_objective()
	if objective.is_empty():
		return
	get_viewport().set_input_as_handled()
	hint_level = mini(hint_level + 1, 3)
	objective_reminder_shown = true
	var story_state: Node = get_node("/root/PrologueState")
	story_state.guide_hint_level = hint_level
	story_state.guide_reminder_shown = true
	var kath: Node2D = scene.get_node_or_null("Kath")
	var kath_x := kath.position.x if kath != null else 0.0
	_show_guide("HINT %d/3 · %s" % [hint_level, StoryGuide.hint_text(story_state, objective, hint_level, scene.scene_file_path, kath_x)], 11.0)
	_point_wick(objective)


func _sync_objective() -> Dictionary:
	var story_state: Node = get_node_or_null("/root/PrologueState")
	if story_state == null:
		return {}
	var objective: Dictionary = StoryGuide.current(story_state)
	if story_state.guide_objective_id != objective["id"]:
		story_state.reset_guide_progress()
		story_state.guide_objective_id = objective["id"]
	var progress_signature: String = StoryGuide.progress_signature(story_state)
	if story_state.guide_progress_signature != progress_signature:
		story_state.guide_progress_signature = progress_signature
		story_state.guide_idle_seconds = 0.0
		story_state.guide_reminder_shown = false
		story_state.guide_hint_level = 0
		guide_bubble.visible = false
	if objective_id != objective["id"]:
		guide_bubble.visible = false
		objective_id = objective["id"]
	objective_idle_seconds = story_state.guide_idle_seconds
	objective_reminder_shown = story_state.guide_reminder_shown
	hint_level = story_state.guide_hint_level
	return objective


func _point_wick(objective: Dictionary) -> bool:
	var scene := get_parent()
	if scene == null:
		return false
	var kath: Node2D = scene.get_node_or_null("Kath")
	if kath == null:
		return false
	var target: Dictionary = StoryGuide.focus_target(get_node("/root/PrologueState"), objective, scene.scene_file_path, kath.position.x)
	if target.is_empty():
		return false
	var focus: Vector2 = target["position"]
	if objective["id"] == "page" and kath.get("locomotion_mode") == &"climb":
		focus = Vector2(1012, 315)
	if scene.scene_file_path == objective["focus_scene"]:
		for child in scene.get_children():
			if child.has_method("marker_position") and child.interaction_id == target["id"]:
				focus = child.marker_position()
				break
	var wick: Node = scene.get_node_or_null("Wick")
	if wick != null:
		wick.react_to(focus.x, focus.y)
		return true
	return false


func _show_guide(message: String, seconds: float) -> void:
	var scene := get_parent()
	var kath: Node2D = scene.get_node_or_null("Kath") if scene != null else null
	if kath == null:
		return
	hint.visible = false
	guide_text.text = get_node("/root/GameSettings").control_text(message)
	guide_bubble.position = Vector2(clampf(kath.position.x - 295.0, 24.0, 1058.0), clampf(kath.position.y - 425.0, 42.0, 665.0))
	guide_deadline = Time.get_ticks_msec() + int(seconds * 1000.0)
	guide_bubble.visible = true


func _make_discovery_marker(canvas: Control) -> Control:
	var marker := Control.new()
	marker.size = Vector2(34, 34)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(marker)
	var diamond := Polygon2D.new()
	diamond.position = Vector2(17, 17)
	diamond.polygon = PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)])
	diamond.color = CREAM
	diamond.antialiased = true
	marker.add_child(diamond)
	var ink := Line2D.new()
	ink.position = Vector2(17, 17)
	ink.points = PackedVector2Array([Vector2(0, -12), Vector2(10, 0), Vector2(0, 12), Vector2(-10, 0), Vector2(0, -12)])
	ink.width = 1.8
	ink.default_color = INK
	ink.antialiased = true
	marker.add_child(ink)
	return marker


func _hide_discovery() -> void:
	for marker in discovery_markers:
		marker.visible = false


func _update_discovery(scene: Node, objective: Dictionary) -> void:
	var kath: Node2D = scene.get_node_or_null("Kath")
	if kath == null or kath.get("locomotion_mode") == &"push" or (kath.get("locomotion_mode") == &"climb" and not scene.has_method("discovery_candidates")):
		_hide_discovery()
		return
	var nearby: Array[Dictionary] = []
	var focus: Dictionary = StoryGuide.focus_target(get_node("/root/PrologueState"), objective, scene.scene_file_path, kath.position.x)
	var focus_id: StringName = focus.get("id", &"")
	for child in [] if kath.get("locomotion_mode") == &"climb" else scene.get_children():
		if not child.has_method("marker_position"):
			continue
		# A marker must never promise an E action that nearest_hotspot would reject.
		if scene.has_method("nearest_hotspot") and scene.nearest_hotspot(child.approach_x) != child:
			continue
		var distance: float = absf(kath.position.x - child.approach_x)
		if distance <= 260.0:
			nearby.append({"distance": distance, "position": child.marker_position(), "id": child.interaction_id})
	if scene.has_method("discovery_candidates"):
		for item in scene.discovery_candidates():
			var distance: float = absf(kath.position.x - float(item["x"]))
			if distance <= 260.0:
				nearby.append({"distance": distance, "position": item["position"], "id": item.get("id", &"")})
	nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["id"] == focus_id and b["id"] != focus_id:
			return true
		if b["id"] == focus_id and a["id"] != focus_id:
			return false
		return a["distance"] < b["distance"])
	for i in discovery_markers.size():
		var marker := discovery_markers[i]
		if i >= nearby.size():
			marker.visible = false
			continue
		var anchor: Vector2 = nearby[i]["position"]
		marker.position = Vector2(clampf(anchor.x - 17.0, 8.0, 1630.0), clampf(anchor.y - 17.0 + sin(Time.get_ticks_msec() * 0.004 + i) * 3.0, 35.0, 830.0))
		marker.modulate.a = clampf((260.0 - float(nearby[i]["distance"])) / 75.0, 0.0, 1.0) * 0.9
		marker.visible = marker.modulate.a > 0.02


func show_prompt(name: String, screen_x: float, action: String = "INSPECT", screen_y: float = 415.0) -> void:
	prompt.text = "%s  %s  ·  %s" % [get_node("/root/GameSettings").key_label("interact"), action, name.to_upper()]
	prompt.position = Vector2(clampf(screen_x - 240.0, 24.0, 1168.0), clampf(screen_y, 24.0, 850.0))
	prompt.visible = true


func hide_prompt() -> void:
	prompt.visible = false


func show_hint(message: String, seconds: float = 4.0) -> void:
	guide_bubble.visible = false
	hint.text = get_node("/root/GameSettings").control_text(message)
	hint_deadline = Time.get_ticks_msec() + int(seconds * 1000.0)
	hint.visible = true


func show_dialogue(line: String, speaker_position: Vector2, beside_high_speaker: bool = false) -> void:
	hide_modals()
	dialogue_text.text = line
	var body_height := maxi(122, dialogue_text.get_line_count() * dialogue_text.get_line_height() + 12)
	dialogue_text.size.y = body_height
	var bubble_size := Vector2(760, maxi(190, body_height + 68))
	dialogue_continue.position.y = bubble_size.y - 45
	if beside_high_speaker:
		var side_position := Vector2(clampf(speaker_position.x - 930.0, 24.0, 888.0), 35.0)
		dialogue_panel.position = side_position
		dialogue_panel.size = bubble_size
		var tail_tip := Vector2(speaker_position.x - side_position.x - 55.0, speaker_position.y - side_position.y - 175.0)
		dialogue_tail.position = side_position
		dialogue_tail.polygon = PackedVector2Array([
			Vector2(bubble_size.x - 3.0, bubble_size.y - 65.0),
			Vector2(bubble_size.x - 3.0, bubble_size.y - 24.0),
			tail_tip
		])
		dialogue_tail_outline.position = side_position
		dialogue_tail_outline.points = PackedVector2Array([
			Vector2(bubble_size.x - 3.0, bubble_size.y - 65.0),
			tail_tip,
			Vector2(bubble_size.x - 3.0, bubble_size.y - 24.0)
		])
		dialogue.visible = true
		hide_prompt()
		return
	var bubble_position := Vector2(
		clampf(speaker_position.x - bubble_size.x * 0.5, 24.0, 888.0),
		clampf(speaker_position.y - 520.0, 35.0, 890.0 - bubble_size.y)
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


func show_journal(entries: Array, hall_complete: bool, machine_recorded: bool, leak_contained: bool = false, page_collected: bool = false, room_compared: bool = false, incident_complete: bool = false, room_prepared: bool = false, incident_active: bool = false, service_gate_open: bool = false, service_road_end_reached: bool = false) -> void:
	hide_modals()
	var objective := _sync_objective()
	var discovered: Dictionary = {}
	for entry in entries:
		discovered[entry["id"]] = true
	var hall_count := 0
	for note_id in HALL_NOTE_IDS:
		if discovered.has(note_id):
			hall_count += 1
	journal_progress.text = "HALL PATROL  %d / 3\n%s  Archive door\n%s  Old clock\n%s  Maintenance sheet\n\nMACHINE ROOM  %s\n\nUPPER STACKS  %d / 2\n%s  Leak caught\n%s  Page recovered\n\nKATH'S ROOM  %s\n\nMACHINE INCIDENT  %s" % [
		hall_count,
		"[x]" if discovered.has(&"archive-door") else "[ ]",
		"[x]" if discovered.has(&"clock-housing") else "[ ]",
		"[x]" if discovered.has(&"maintenance-sheet") else "[ ]",
		"1 / 1  Reading recorded" if machine_recorded else "0 / 1  Reading pending",
		int(leak_contained) + int(page_collected),
		"[x]" if leak_contained else "[ ]",
		"[x]" if page_collected else "[ ]",
		"Prepared to leave" if room_prepared else ("Page matched" if room_compared else "Compare the torn page"),
		"Recorded" if incident_complete else ("In progress" if incident_active else ("Alarm pending" if room_compared else "Not yet"))
	]
	if hall_complete and hall_count == 3:
		journal_progress.text = journal_progress.text.replace("HALL PATROL  3 / 3", "HALL PATROL  3 / 3  COMPLETE")
	journal_progress.text += "\n\nSERVICE ROAD  %s" % ("Castle entrance reached" if service_road_end_reached else ("Gate open" if service_gate_open else "Not reached"))
	if discovered.has(&"castle-on-site-inversion"):
		journal_progress.text += "\n\nCASTLE WING  %s" % ("Restored" if discovered.has(&"engine-wing-restored") else "Inverted")
		journal_progress.text += "\n%s  Falling water\n%s  Hanging weight\n%s  Lower ledge\n%s  Shaft access" % [
			"[x]" if discovered.has(&"castle-water-path") else "[ ]",
			"[x]" if discovered.has(&"castle-plumb-weight") else "[ ]",
			"[x]" if discovered.has(&"castle-down-confirmed") else "[ ]",
			"[x]" if discovered.has(&"castle-shaft-access") else "[ ]"
		]
	if discovered.has(&"shaft-rescue") or discovered.has(&"engine-orientation-chart"):
		journal_progress.text += "\n\nENGINE ROOM  %d / 4\n%s  Fault traced\n%s  Track cleared\n%s  Stop path tested\n%s  Wing restored" % [
			int(discovered.has(&"engine-fault-chain")) + int(discovered.has(&"engine-track-cleared")) + int(discovered.has(&"engine-home-stop-test")) + int(discovered.has(&"engine-wing-restored")),
			"[x]" if discovered.has(&"engine-fault-chain") else "[ ]",
			"[x]" if discovered.has(&"engine-track-cleared") else "[ ]",
			"[x]" if discovered.has(&"engine-home-stop-test") else "[ ]",
			"[x]" if discovered.has(&"engine-wing-restored") else "[ ]"
		]
	if discovered.has(&"engine-wing-restored"):
		journal_progress.text += "\n\nOBSERVATORY  %d / 4\n%s  Work record\n%s  Floating Isles slip\n%s  Withdrawn page\n%s  Notebook repaired" % [
			int(discovered.has(&"observatory-work-record")) + int(discovered.has(&"observatory-floating-slip")) + int(discovered.has(&"observatory-withdrawn")) + int(discovered.has(&"observatory-page-stitched")),
			"[x]" if discovered.has(&"observatory-work-record") else "[ ]",
			"[x]" if discovered.has(&"observatory-floating-slip") else "[ ]",
			"[x]" if discovered.has(&"observatory-withdrawn") else "[ ]",
			"[x]" if discovered.has(&"observatory-page-stitched") else "[ ]"
		]
		if discovered.has(&"chapter1-departure"):
			journal_progress.text += "\n\nCHAPTER I  COMPLETE"
	var thread_text := ""
	if discovered.has(&"machine-reading") or discovered.has(&"leak-observation") or discovered.has(&"newton-note"):
		var thread := PackedStringArray(["OBSERVATION THREAD"])
		if discovered.has(&"machine-reading"):
			thread.append("• Needle: one division above the old mark, still below red.")
		if discovered.has(&"leak-observation"):
			thread.append("• Leak: the water still falls; the bucket changes where it lands.")
		if discovered.has(&"newton-note"):
			thread.append("• Torn page: F = ma and an unfinished basket sketch in my hand.")
		if discovered.has(&"machine-reading") and discovered.has(&"leak-observation"):
			thread.append("Compare: both are observations before any cause is known.")
		if discovered.has(&"newton-note"):
			thread.append("The formula's meaning is still unknown. Keep the page for comparison.")
		thread_text = "\n".join(thread) + "\n\n"
	if not objective.is_empty():
		var story_state: Node = get_node("/root/PrologueState")
		var clues: PackedStringArray = StoryGuide.discovered_clues(story_state, objective)
		var clue_text := "\n• ".join(clues) if not clues.is_empty() else "No related observation recorded yet."
		var hint_status := "%s  OPTIONAL HINT" % get_node("/root/GameSettings").key_label("request_hint") if get_node("/root/GameSettings").hints_enabled else "OPTIONAL HINTS OFF"
		journal_progress.text = "CURRENT OBJECTIVE\n%s\nNEXT RELEVANT AREA  %s\n\nDISCOVERED CLUES\n• %s\n\n%s\n\n" % [objective["title"], objective["next_area"], clue_text, hint_status] + thread_text + journal_progress.text
	else:
		journal_progress.text = thread_text + journal_progress.text
	var progress_lines: int = maxi(journal_progress.get_line_count(), journal_progress.text.count("\n") + 1)
	var progress_height: float = maxf(390.0, float(progress_lines) * 37.0 + 24.0)
	journal_progress.custom_minimum_size.y = progress_height
	journal_progress.size.y = progress_height
	var lines := PackedStringArray()
	for entry in entries:
		lines.append("• %s\n%s" % [entry["title"], entry["body"]])
	journal_entries.text = "\n\n".join(lines) if not lines.is_empty() else get_node("/root/GameSettings").control_text("Nothing recorded yet.\n\nLook around the hall and press E to examine an object.")
	journal_scroll.scroll_vertical = 0
	journal_progress_scroll.scroll_vertical = 0
	journal.visible = true
	hide_prompt()


func show_torn_page(from_journal: bool) -> void:
	hide_modals()
	torn_page_instruction.text = "ESC  BACK TO NOTES" if from_journal else "ENTER  KEEP PAGE     ·     ESC  CLOSE"
	torn_page.visible = true
	hide_prompt()


func show_notebook_comparison() -> void:
	hide_modals()
	notebook_comparison.visible = true
	hide_prompt()


func show_chapter1_notebook() -> void:
	hide_modals()
	chapter1_notebook.visible = true
	hide_prompt()


func show_shaft_winch(progress: float, rail_removed: bool, passenger_test: bool = false, operation: StringName = &"", speed: float = 0.0, tension_level: float = 0.0, safety_stop: bool = false) -> void:
	hide_modals()
	shaft_winch.visible = true
	update_shaft_winch(progress, rail_removed, passenger_test, operation, speed, tension_level, safety_stop)
	hide_prompt()


func update_shaft_winch(progress: float, rail_removed: bool, passenger_test: bool = false, operation: StringName = &"", speed: float = 0.0, tension_level: float = 0.0, safety_stop: bool = false) -> void:
	shaft_winch_fill.size.x = 700.0 * clampf(progress, 0.0, 1.0)
	shaft_winch_footer.text = "ESC  CLOSE  ·  Closing engages the brake" if operation == &"passenger_descent" else "ESC  CLOSE  ·  Release keys to hold position"
	shaft_winch_measure.text = "Rope marks: ~%d  ·  Basket marks: %d" % [roundi(progress * (200.0 if passenger_test else 100.0)), roundi(progress * 100.0)]
	if operation == &"load_tension":
		shaft_winch_measure.text = "Indicator: empty mark → occupied mark (rope tension, not mass)"
		shaft_winch_fill.size.x = 700.0 * clampf(tension_level, 0.0, 1.0)
		shaft_winch_path.text = "Erin is inside. The upper catch stays secured while the winch takes up slack."
		shaft_winch_status.text = "Rope tension: %s" % ("stable" if tension_level >= 0.995 else "increasing" if tension_level > 0.01 else "not yet checked")
		shaft_winch_instruction.text = get_node("/root/GameSettings").control_text("The brake held. Close this view, then E at the winch to check the load.") if tension_level >= 0.995 and not Input.is_action_pressed("move_up") else "Hold ↑ until the indicator settles, then release ↑ to test the brake."
		return
	if operation == &"passenger_descent":
		shaft_winch_measure.text = "Two supporting strands · brake before the lower berth"
		shaft_winch_path.text = "Erin: The lower berth is close. Leave room to brake." if progress <= 0.25 else "Erin is aboard. The rope supports the basket; the upper catch is released."
		shaft_winch_status.text = "Travel left: %d%%  ·  Descent: %s" % [roundi(progress * 100.0), "stopped" if speed < 0.002 else "slow" if speed < 0.055 else "gaining speed"]
		shaft_winch_instruction.text = "Safety catch engaged. Press Space to reset, then lower carefully." if safety_stop else "Brake early: allow room to stop." if progress <= 0.2 else "Hold ↓ to pay out rope. Release to slow; Space brakes harder."
		return
	if operation == &"passenger_raise":
		shaft_winch_measure.text = "Same empty basket: ~2 rope marks per basket mark of rise"
		shaft_winch_path.text = "The empty basket runs on two supporting strands. Bring it level with Erin's ledge."
		shaft_winch_status.text = "Empty basket: %d%% of the full lift" % roundi(progress * 100.0)
		shaft_winch_instruction.text = "Basket level: release the key, close this view, then call Erin." if progress >= 0.995 else "Hold ↑ to raise or ↓ to lower. Release to stop."
		return
	if passenger_test:
		shaft_winch_path.text = "Two rope runs support the empty basket. Reel in about two rope marks to lift it one mark."
		shaft_winch_status.text = "Empty test: basket %d%% · rope taken in ~%d%%" % [roundi(progress * 100.0), roundi(progress * 200.0)]
		shaft_winch_instruction.text = "Hold ↑ for a short lift, release to hold, then hold ↓ to return."
	else:
		shaft_winch_path.text = "One cable crosses the fixed pulley and holds the basket."
		shaft_winch_status.text = "Basket position: %d%% of the lift" % roundi(progress * 100.0)
		shaft_winch_measure.text = "One support strand · fixed wheel redirects the pull"
	if passenger_test:
		return
	if rail_removed:
		shaft_winch_instruction.text = "Hold ↓ to lower the empty basket."
	elif progress >= 0.995:
		shaft_winch_instruction.text = get_node("/root/GameSettings").control_text("Basket at Erin's ledge. E to dock and pass the tools.")
	else:
		shaft_winch_instruction.text = "Hold ↑ to reel in. Hold ↓ to lower."


func show_shaft_load_check(checked: Array[StringName], selected: int) -> void:
	hide_modals()
	shaft_load_check.visible = true
	update_shaft_load_check(checked, selected)
	hide_prompt()


func update_shaft_load_check(checked: Array[StringName], selected: int) -> void:
	var ids: Array[StringName] = [&"rope", &"anchor", &"indicator", &"brake"]
	var titles := ["ROPE IN BOTH WHEELS", "TOP ANCHOR CLOSED", "LOAD INDICATOR STABLE", "BRAKE HOLDS AT REST"]
	var details := [
		"Both supporting strands remain in their wheel grooves.",
		"Erin confirms the top latch is closed.",
		"The needle settled at a new position after the rope took Erin's load.",
		"The basket stayed still after Kath released the winch."
	]
	var lines: Array[String] = []
	for index in 4:
		lines.append("%s  %s  %s" % ["›" if index == selected else " ", "✓" if checked.has(ids[index]) else "○", titles[index]])
	shaft_load_selection.text = "\n".join(lines)
	shaft_load_detail.text = details[selected] if checked.has(ids[selected]) else get_node("/root/GameSettings").control_text("E to compare: ") + details[selected]


func show_shaft_rigging(step: int) -> void:
	hide_modals()
	shaft_rigging.visible = true
	update_shaft_rigging(step)
	hide_prompt()


func show_engine_maintenance(title: String, body: String, status: String, footer: String) -> void:
	hide_modals()
	engine_title.text = title
	engine_body.text = body
	engine_status.text = status
	engine_footer.text = get_node("/root/GameSettings").control_text(footer)
	engine_panel.visible = true
	hide_prompt()


func update_engine_maintenance(status: String, footer: String = "") -> void:
	engine_status.text = status
	if footer != "":
		engine_footer.text = get_node("/root/GameSettings").control_text(footer)


func update_shaft_rigging(step: int) -> void:
	match step:
		0:
			shaft_rigging_status.text = "1 / 3  Attach the long rope to the waiting pilot line."
		1:
			shaft_rigging_status.text = "2 / 3  Pull it over the fixed wheel and around the basket wheel."
		2:
			shaft_rigging_status.text = "3 / 3  Seat the free end in the top anchor and secure the winch."


func show_emergency_console(valve_two_open: bool, valve_four_open: bool, drive_stopped: bool, selected_lever: int) -> void:
	hide_modals()
	update_emergency_console(valve_two_open, valve_four_open, drive_stopped, selected_lever)
	emergency_console.visible = true
	hide_prompt()


func update_emergency_console(valve_two_open: bool, valve_four_open: bool, drive_stopped: bool, selected_lever: int) -> void:
	var selected_name := "LEVER 2 · RETURN" if selected_lever == 2 else "LEVER 4 · ARCHIVE ISOLATION"
	emergency_selection.text = "‹  %s  ›" % selected_name
	emergency_status.text = "Lever 2: %s     ·     Lever 4: %s     ·     Drive: %s" % [
		"open" if valve_two_open else "pending",
		"isolated" if valve_four_open else "pending",
		"stopped" if drive_stopped else "running"
	]


func play_castle_tilt() -> void:
	hide_modals()
	castle_rotation.visible = true
	var pivot := castle_rotation.get_node("CastleWingPivot") as Node2D
	var state: Node = get_node("/root/PrologueState")
	var start_angle: float = state.castle_pose_angle_radians(&"upright")
	var target_angle: float = state.castle_pose_angle_radians(&"tilted")
	pivot.rotation = start_angle
	var rotation_tween := create_tween()
	rotation_tween.tween_property(pivot, "rotation", target_angle, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await rotation_tween.finished
	await get_tree().create_timer(0.35).timeout
	castle_rotation.visible = false


func scroll_journal(direction: int) -> void:
	journal_scroll.scroll_vertical = maxi(0, journal_scroll.scroll_vertical + direction * 72)
	journal_progress_scroll.scroll_vertical = maxi(0, journal_progress_scroll.scroll_vertical + direction * 72)


func show_pause() -> void:
	hide_modals()
	pause_save_error.visible = false
	pause_menu.visible = true
	hide_prompt()


func show_save_error() -> void:
	pause_save_error.visible = true


func show_chapter_end() -> void:
	hide_modals()
	chapter_end.visible = true
	chapter_end.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(chapter_end, "modulate:a", 1.0, 0.7)
	hide_prompt()


func show_chapter1_end() -> void:
	hide_modals()
	chapter1_end.visible = true
	chapter1_end.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(chapter1_end, "modulate:a", 1.0, 0.6)
	hide_prompt()


func hide_modals() -> void:
	dialogue.visible = false
	sheet.visible = false
	gauge_inspection.visible = false
	journal.visible = false
	torn_page.visible = false
	notebook_comparison.visible = false
	chapter1_notebook.visible = false
	shaft_winch.visible = false
	shaft_load_check.visible = false
	shaft_rigging.visible = false
	engine_panel.visible = false
	emergency_console.visible = false
	castle_rotation.visible = false
	chapter_end.visible = false
	chapter1_end.visible = false
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


func _add_incomplete_hoist_sketch(page_panel: Control) -> void:
	var sketch := Node2D.new()
	sketch.name = "IncompleteHoistSketch"
	sketch.position = Vector2(237, 482)
	sketch.scale = Vector2(1.16, 1.16)
	page_panel.add_child(sketch)
	# The rope breaks off above the basket; the page never shows a full reeving path.
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(72, 22), Vector2(75, 13), Vector2(84, 8), Vector2(96, 10), Vector2(103, 19)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(77, 25), Vector2(69, 38), Vector2(64, 45)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(58, 55), Vector2(52, 67)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(100, 24), Vector2(114, 49), Vector2(123, 67)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(48, 66), Vector2(137, 67)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(50, 68), Vector2(60, 83), Vector2(126, 84), Vector2(137, 68)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(79, 70), Vector2(82, 82)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(109, 70), Vector2(106, 83)]))
	_page_sketch_stroke(sketch, PackedVector2Array([Vector2(88, 2), Vector2(91, -4)]))


func _page_sketch_stroke(parent: Node2D, points: PackedVector2Array) -> void:
	var blurred_ink := Line2D.new()
	blurred_ink.points = points
	blurred_ink.width = 6.0
	blurred_ink.default_color = Color(0.16, 0.20, 0.32, 0.10)
	blurred_ink.antialiased = true
	parent.add_child(blurred_ink)
	var worn_ink := Line2D.new()
	worn_ink.points = points
	worn_ink.width = 1.8
	worn_ink.default_color = Color(0.16, 0.20, 0.32, 0.52)
	worn_ink.antialiased = true
	parent.add_child(worn_ink)


func _label(parent: Control, rect: Rect2, value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = get_node("/root/GameSettings").control_text(value)
	result.set_meta("control_base_text", value)
	result.set_meta("control_rendered_text", result.text)
	result.position = rect.position
	result.size = rect.size
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result
