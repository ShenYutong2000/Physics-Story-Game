extends SceneTree
## Visual QA only: render the proposed hall art at both supported window sizes.

const ART := "res://prologue-asset-pack-v1/hall-closeups-v2/"
const OUTPUT := ART + "review-captures/"
const CASES := [
	["door", "door-latch-states.png", 887, 887, 887, "DOOR LATCH", "The bolt has slipped short of its keeper.", "The bolt is set. I still need to check the window."],
	["window", "window-catch-states.png", 768, 1024, 768, "EAST WINDOW", "The loose catch lets the frame knock in the wind.", "The frame's quiet now. The wind isn't."],
	["clock", "clock-winding-detail-states.png", 836, 941, 836, "HALL CLOCK", "The pendulum is slowing. The winding crank is ready.", "Steady again. I'll write down the hour."],
	["keys", "duty-keys-states.png", 887, 887, 887, "DUTY KEYS", "The east key hangs on a temporary nail.", "The east key hangs on the EAST SERVICE WAY hook."],
	["book", "round-book-page-states.png", 836, 941, 836, "EVENING ROUND", "Three boxes: doors and windows, clock, duty keys.", "ROUND FILED. The current task page is blank."],
]

var stage: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	stage = Node2D.new()
	stage.name = "HallArtReview"
	root.add_child(stage)
	current_scene = stage
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_draw_hall()
	if not await _capture("00-hall-prestorm"):
		quit(1)
		return
	for entry in CASES:
		for after in [false, true]:
			_clear_stage()
			if not _draw_prop(entry, after):
				quit(1)
				return
			if not await _capture("%s-%s" % [entry[0], "after" if after else "before"]):
				quit(1)
				return
	_clear_stage()
	_draw_emergency()
	if not await _capture("emergency-page"):
		quit(1)
		return
	print("HALL_ART_CAPTURE_OK: hall, five before/after props, emergency page, two sizes")
	quit(0)


func _clear_stage() -> void:
	for child in stage.get_children():
		stage.remove_child(child)
		child.free()


func _draw_hall() -> void:
	for path in [ART + "archive-prestorm-city.png", "res://prologue-asset-pack-v1/mid/01-library-hall-mid.png", "res://prologue-asset-pack-v1/foregrounds/01-library-hall-front.png"]:
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = load(path)
		stage.add_child(sprite)
	_draw_caption("PRE-STORM EVENING", "The windows are dry. Kath begins her evening round.")


func _draw_prop(entry: Array, after: bool) -> bool:
	_draw_backdrop()
	var sheet: Texture2D = load(ART + entry[1])
	if sheet == null:
		push_error("Missing art texture: " + entry[1])
		return false
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2i(entry[4] if after else 0, 0, entry[2], entry[3])
	_draw_art(atlas, Vector2(entry[2], entry[3]))
	if entry[0] == "book" and not after:
		_draw_book_page_text()
	_draw_caption(entry[5] + (" · AFTER" if after else " · BEFORE"), entry[7] if after else entry[6])
	return true


func _draw_emergency() -> void:
	_draw_backdrop()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ART + "round-book-emergency-page.png")
	atlas.region = Rect2i(0, 0, 1672, 941)
	_draw_art(atlas, Vector2(1672, 941))
	_draw_emergency_page_text()
	_draw_caption("EMERGENCY PROCEDURE", "If the upper needle crosses the red line, pull lever 2, then lever 4. Check the needle again.")


func _draw_backdrop() -> void:
	var back := ColorRect.new()
	back.size = Vector2(1672, 941)
	back.color = Color("151b30")
	stage.add_child(back)


func _draw_art(texture: Texture2D, art_size: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = Vector2(836, 405)
	var factor: float = minf(1372.0 / art_size.x, 750.0 / art_size.y)
	sprite.scale = Vector2.ONE * factor
	stage.add_child(sprite)


func _draw_page_label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("39344d"))
	stage.add_child(label)


func _draw_book_page_text() -> void:
	_draw_page_label("EVENING ROUND", Vector2(665, 100), Vector2(440, 48), 32)
	_draw_page_label("Check doors and windows before the storm", Vector2(680, 210), Vector2(435, 95), 28)
	_draw_page_label("Wind the hall clock", Vector2(680, 350), Vector2(435, 48), 28)
	_draw_page_label("Check the duty keys", Vector2(680, 490), Vector2(435, 48), 28)


func _draw_emergency_page_text() -> void:
	_draw_page_label("EMERGENCY PROCEDURE", Vector2(495, 175), Vector2(760, 58), 40)
	_draw_page_label("If the upper needle crosses the red line,\npull lever 2, then lever 4.", Vector2(385, 330), Vector2(910, 150), 37)
	_draw_page_label("Check the needle again.", Vector2(385, 555), Vector2(910, 65), 37)


func _draw_caption(heading: String, detail: String) -> void:
	var band := ColorRect.new()
	band.position = Vector2(0, 791)
	band.size = Vector2(1672, 150)
	band.color = Color(0.06, 0.10, 0.18, 0.94)
	stage.add_child(band)
	var title := Label.new()
	title.position = Vector2(55, 805)
	title.size = Vector2(1550, 42)
	title.text = heading
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("f8d997"))
	stage.add_child(title)
	var body := Label.new()
	body.position = Vector2(55, 850)
	body.size = Vector2(1550, 80)
	body.text = detail
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 27)
	body.add_theme_color_override("font_color", Color("fff4da"))
	stage.add_child(body)


func _capture(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 6:
			await process_frame
		var frame: Image = root.get_texture().get_image()
		# Canvas scaling can round the 1280-wide viewport down by one pixel.
		# Restore the requested screenshot bounds with the review backdrop.
		if frame.get_size() != resolution:
			frame.convert(Image.FORMAT_RGBA8)
			var normalized := Image.create_empty(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
			normalized.fill(Color("151b30"))
			normalized.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ZERO)
			frame = normalized
		var filename := "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if frame.save_png(ProjectSettings.globalize_path(OUTPUT + filename)) != OK:
			push_error("Could not save " + filename)
			return false
	return true
