extends CanvasLayer
## Close view of a hall prop. The room's camera pushes in first, then one of two
## presentations takes over:
##   * a close shot ("shot" in the view config): the prop fills the whole screen,
##     with Kath seen from behind reaching for it — no frame, no dimming, no captions;
##   * a framed detail picture that grows out of the prop's place on screen.
## The hall owns progress and input.

signal dismissed
signal gesture_progress(value: float)
signal gesture_committed(action: StringName)
## A gust knocked the unlatched door; `strength` fades as the bolt nears home.
signal rattled(strength: float)
signal broke_free

const Gesture = preload("res://scripts/focus_gesture.gd")

const CANVAS_SIZE := Vector2(1672, 941)
const IMAGE_RECT := Rect2(486, 109, 700, 700)
const CREAM := Color("fff4db")
const GOLD := Color("f5dba6")
const SHADE_ALPHA := 0.5
## The camera leads; the picture follows after this many seconds.
const OPEN_LEAD := 0.2
const OPEN_GROW := 0.3
const CLOSE_SECONDS := 0.36
const IDLE_HINT_SECONDS := 6.0
const RATTLE_EVERY := 3.5
const RATTLE_SECONDS := 0.28

var screen: Control
var shade: ColorRect
var vignette: TextureRect
var frame: Panel
## Everything painted on the prop itself; it drifts, shakes and breathes as one.
var stage: Control
var picture: TextureRect
var light_gap: ColorRect
var figure: Sprite2D
var esc_glyph: Label
var tip_label: Label
var title_label: Label
var detail_label: Label
var controls_label: Label
var parts_label: Label
var hold_label: Label
var hold_track: ColorRect
var hold_fill: ColorRect
var hook_labels: Label
var tag_card: ColorRect
var tag_label: Label
var inscription_label: Label
var config: Dictionary = {}
var selected_part := 0
var completed := false
var transitioning := false
## True while the current view is a full-screen close shot.
var shot := false
## Text shown once for a player's first hands-on part; the hall sets it before opening.
var first_time_tip := ""
var gesture: RefCounted
var view_rect := IMAGE_RECT
var _tween: Tween
var _tag_tween: Tween
var _drift_tween: Tween
var _figure_tween: Tween
var _changed_image: TextureRect
var _hold_preview: TextureRect
var _pieces: Array[TextureRect] = []
var _hint: Node2D
var _idle_seconds := 0.0
var _strain := 0.0
var _progress := 0.0
var _rattle_wait := RATTLE_EVERY * 0.5
var _rattle_left := 0.0
var _figure_ready := false
var _figure_release := Vector2.ZERO


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
	vignette = TextureRect.new()
	vignette.name = "Vignette"
	vignette.texture = _vignette_texture()
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.size = CANVAS_SIZE
	vignette.modulate.a = 0.0
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(vignette)
	frame = Panel.new()
	frame.name = "DetailFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("0b1024")
	frame_style.border_color = Color(GOLD, 0.6)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(10)
	frame_style.shadow_color = Color(0.0, 0.0, 0.03, 0.55)
	frame_style.shadow_size = 26
	frame.add_theme_stylebox_override("panel", frame_style)
	screen.add_child(frame)
	stage = Control.new()
	stage.name = "Stage"
	stage.size = CANVAS_SIZE
	stage.pivot_offset = CANVAS_SIZE / 2.0
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(stage)
	picture = TextureRect.new()
	picture.name = "PropImage"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(picture)
	light_gap = ColorRect.new()
	light_gap.name = "LightGap"
	light_gap.color = Color(0.74, 0.86, 1.0, 0.42)
	light_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light_gap.z_index = 2
	light_gap.visible = false
	stage.add_child(light_gap)
	figure = Sprite2D.new()
	figure.name = "ShotFigure"
	figure.centered = false
	figure.region_enabled = true
	figure.z_index = 3
	figure.visible = false
	screen.add_child(figure)
	inscription_label = _label("Inscription", Rect2(625, 390, 425, 220), 26, Color("33273b"))
	inscription_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The room itself names the prop now; the large heading stays out of the way.
	title_label = _label("Title", Rect2(92, 30, 1488, 62), 36, GOLD)
	title_label.visible = false
	detail_label = _label("Observation", Rect2(180, 818, 1312, 44), 24, CREAM)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label = _label("Controls", Rect2(180, 866, 1312, 38), 20, GOLD)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parts_label = _label("Parts", Rect2(1200, 218, 360, 240), 21, CREAM)
	parts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hook_labels = _label("HookNames", Rect2(1200, 305, 360, 170), 22, GOLD)
	hook_labels.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag_card = ColorRect.new()
	tag_card.name = "KeyTagReverse"
	tag_card.position = Vector2(1200, 520)
	tag_card.size = Vector2(350, 112)
	tag_card.pivot_offset = tag_card.size / 2.0
	tag_card.color = Color("e6c692")
	tag_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(tag_card)
	tag_label = _label("KeyTagText", Rect2(1215, 528, 320, 94), 27, Color("30283d"))
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hold_label = _label("HoldStatus", Rect2(1200, 505, 360, 38), 21, GOLD)
	hold_track = ColorRect.new()
	hold_track.name = "HoldTrack"
	hold_track.position = Vector2(1200, 556)
	hold_track.size = Vector2(328, 16)
	hold_track.color = Color("39374e")
	hold_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(hold_track)
	hold_fill = ColorRect.new()
	hold_fill.name = "HoldFill"
	hold_fill.position = hold_track.position
	hold_fill.size = Vector2(0, hold_track.size.y)
	hold_fill.color = GOLD
	hold_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(hold_fill)
	esc_glyph = _label("EscGlyph", Rect2(36, 26, 200, 34), 19, CREAM)
	esc_glyph.text = "ESC"
	esc_glyph.z_index = 5
	tip_label = _label("FirstTimeTip", Rect2(436, 388, 800, 40), 22, CREAM)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.z_index = 5
	screen.visible = false


func _process(delta: float) -> void:
	if not screen.visible:
		return
	if shot:
		_process_shot(delta)
	else:
		# The frame is the picture's shadow and rim, so it follows every transition.
		frame.position = picture.position - Vector2(5, 5)
		frame.size = picture.size + Vector2(10, 10)
		frame.modulate.a = picture.modulate.a
	if gesture == null:
		return
	gesture.process(delta)
	if _hint == null:
		return
	_idle_seconds = 0.0 if gesture.is_active() else _idle_seconds + delta
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	var reminder := _idle_seconds >= IDLE_HINT_SECONDS
	_hint.visible = not gesture.is_active() and not gesture.done
	_hint.modulate.a = (0.55 + 0.45 * pulse) if reminder else (0.22 + 0.2 * pulse)
	var home: Vector2 = _hint.get_meta("home")
	_hint.position = home + Vector2.RIGHT.rotated(_hint.rotation) * (pulse * 10.0 if reminder else pulse * 4.0)


## The close shot is never a still picture: the frame breathes with the mouse,
## and an unlatched door knocks in the draught until the bolt is home.
func _process_shot(delta: float) -> void:
	var sway := ((screen.get_local_mouse_position() / CANVAS_SIZE) - Vector2(0.5, 0.5)).clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	if not sway.is_finite():
		# No pointer to follow (a minimised or resizing window).
		sway = Vector2.ZERO
	var knock := Vector2.ZERO
	var loose := 1.0 - _progress
	if bool((config["shot"] as Dictionary).get("rattle", false)) and not completed and not transitioning:
		_rattle_wait -= delta
		if _rattle_wait <= 0.0:
			_rattle_wait = RATTLE_EVERY
			_rattle_left = RATTLE_SECONDS
			rattled.emit(loose)
		if _rattle_left > 0.0:
			_rattle_left -= delta
			knock = Vector2(sin(_rattle_left * 78.0) * 2.4 * loose * (_rattle_left / RATTLE_SECONDS), 0.0)
	stage.position = -sway * 10.0 + knock
	_place_light_gap(loose + (0.5 if _rattle_left > 0.0 else 0.0) * loose)
	if _figure_ready:
		figure.position = _figure_home() - sway * 20.0 + knock * 0.4


## `screen_source` is where the prop sits on screen once the camera has settled.
## `switching` swaps the picture inside an already open close-up.
func open_view(prop_config: Dictionary, already_completed: bool, screen_source := Vector2(-1.0, -1.0), switching := false) -> void:
	_stop_tween()
	_stop_tag_tween()
	_clear_changed_image()
	_clear_hold_preview()
	_clear_gesture()
	_clear_shot()
	config = prop_config
	completed = already_completed
	shot = config.has("shot")
	selected_part = 0
	_progress = 1.0 if completed else 0.0
	var fresh := not screen.visible or not switching
	screen.visible = true
	screen.modulate.a = 1.0
	if fresh:
		shade.modulate.a = 0.0
		vignette.modulate.a = 0.0
	view_rect = Rect2(Vector2.ZERO, CANVAS_SIZE) if shot else IMAGE_RECT
	picture.stretch_mode = TextureRect.STRETCH_SCALE if shot else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = _state_texture(completed)
	picture.modulate.a = 0.0
	picture.scale = Vector2.ONE
	picture.pivot_offset = Vector2.ZERO
	stage.position = Vector2.ZERO
	stage.scale = Vector2.ONE
	frame.visible = not shot
	_refresh_labels()
	inscription_label.visible = not shot and (config.has("inscription_before") or config.has("inscription_after"))
	parts_label.visible = not shot and not bool(config.get("hide_parts", false)) and (config.get("parts", []) as Array).size() > 1
	hook_labels.visible = config.has("hook_labels")
	tag_card.visible = completed and config.has("tag_reveal")
	tag_label.visible = tag_card.visible
	tag_card.scale.x = 1.0
	hold_label.visible = bool(config.get("has_hold_progress", false))
	hold_track.visible = hold_label.visible
	hold_fill.visible = hold_label.visible
	detail_label.visible = not shot
	controls_label.visible = not shot
	esc_glyph.visible = shot
	_set_labels_alpha(0.0)
	transitioning = true
	var lead := OPEN_LEAD if fresh else 0.0
	_tween = create_tween().set_parallel(true)
	if shot:
		# One continuous push: the room's camera starts it, the close shot finishes it.
		picture.position = Vector2.ZERO
		picture.size = CANVAS_SIZE
		stage.scale = Vector2.ONE * 0.94
		_tween.tween_property(shade, "modulate:a", 0.0, 0.15)
		_tween.tween_property(vignette, "modulate:a", 0.0, 0.15)
		_tween.tween_property(stage, "scale", Vector2.ONE * 1.03, lead + OPEN_GROW).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(picture, "modulate:a", 1.0, OPEN_GROW).set_delay(lead)
		# Not part of the opening move: the shot is usable before the glyph has faded in.
		create_tween().tween_property(esc_glyph, "modulate:a", 0.4, 0.3).set_delay(lead + OPEN_GROW)
	else:
		var source: Vector2 = screen_source if screen_source.x >= 0.0 else config.get("source", Vector2(836, 470))
		picture.position = source - Vector2(90, 90)
		picture.size = Vector2(180, 180)
		_tween.tween_property(shade, "modulate:a", SHADE_ALPHA, lead + OPEN_GROW)
		_tween.tween_property(vignette, "modulate:a", 1.0, lead + OPEN_GROW)
		_tween.tween_property(picture, "position", IMAGE_RECT.position, OPEN_GROW).set_delay(lead).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(picture, "size", IMAGE_RECT.size, OPEN_GROW).set_delay(lead).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(picture, "modulate:a", 1.0, OPEN_GROW * 0.7).set_delay(lead)
		for label in _labels():
			_tween.tween_property(label, "modulate:a", 1.0, 0.18).set_delay(lead + OPEN_GROW - 0.18)
	_tween.finished.connect(func() -> void:
		transitioning = false
		if shot:
			_enter_shot()
		_start_gesture()
	)


func set_hold_progress(value: float) -> void:
	if not screen.visible or not bool(config.get("has_hold_progress", false)):
		return
	var amount := clampf(value, 0.0, 1.0)
	hold_fill.size.x = hold_track.size.x * amount
	hold_label.text = "SPRING WOUND  %d%%" % roundi(amount * 100.0)
	if completed or amount <= 0.0:
		_clear_hold_preview()
		return
	if _hold_preview == null:
		_hold_preview = TextureRect.new()
		_hold_preview.name = "WindingPreview"
		_hold_preview.texture = _state_texture(true)
		_hold_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_hold_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hold_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_preview.position = IMAGE_RECT.position
		_hold_preview.size = IMAGE_RECT.size
		screen.add_child(_hold_preview)
	_hold_preview.modulate.a = amount * 0.9


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


## True when this view is operated by hand rather than by one key press.
func uses_gesture() -> bool:
	return config.has("gesture")


## Offer an input event to the hands-on gesture. Returns true when it was used.
func handle_event(event: InputEvent) -> bool:
	if gesture == null or transitioning or completed:
		return false
	return gesture.handle_event(event)


## True for a click that lands on the hall around a framed detail picture.
## A close shot fills the screen, so nothing is outside it.
func is_outside_picture(point: Vector2) -> bool:
	return not shot and not IMAGE_RECT.grow(40.0).has_point(point)


## The other view a click at `point` leads to (the nameplate beside the bolt), or &"".
func link_at(point: Vector2) -> StringName:
	if not shot or transitioning:
		return &""
	for link: Dictionary in (config["shot"] as Dictionary).get("links", []):
		if (link["rect"] as Rect2).has_point(point):
			return link["view"]
	return &""


func set_completed() -> void:
	if completed or not screen.visible:
		return
	completed = true
	_progress = 1.0
	if config.has("tag_reveal"):
		tag_card.visible = true
		tag_label.visible = true
		tag_card.scale.x = 0.0
		tag_label.modulate.a = 0.0
		_tag_tween = create_tween().set_parallel(true)
		_tag_tween.tween_property(tag_card, "scale:x", 1.0, 0.34).set_delay(0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tag_tween.tween_property(tag_label, "modulate:a", 1.0, 0.18).set_delay(0.28)
	_stop_tween()
	_clear_hold_preview()
	set_hold_progress(1.0)
	if config.get("transition", "") == "flip":
		transitioning = true
		picture.pivot_offset = IMAGE_RECT.size / 2.0
		_tween = create_tween()
		_tween.tween_property(picture, "scale:x", 0.0, 0.18).set_trans(Tween.TRANS_CUBIC)
		_tween.tween_callback(func() -> void:
			picture.texture = _state_texture(true)
			_refresh_labels()
		)
		_tween.tween_property(picture, "scale:x", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC)
		_tween.finished.connect(func() -> void: transitioning = false)
		return
	# A part the player moved by hand is already in place: settle into the
	# finished art without the sideways drift used for one-press changes.
	var by_hand := uses_gesture()
	if by_hand:
		# A small knock along the travel gives the part weight as it seats.
		var knock: Vector2 = (config["gesture"] as Dictionary).get("track", Vector2.RIGHT).normalized() * 6.0
		var thunk := create_tween()
		thunk.tween_property(screen, "position", knock, 0.04)
		thunk.tween_property(screen, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_changed_image = TextureRect.new()
	_changed_image.name = "ChangedImage"
	_changed_image.texture = _state_texture(true)
	_changed_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_changed_image.stretch_mode = picture.stretch_mode
	_changed_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_changed_image.position = view_rect.position + (Vector2.ZERO if by_hand else Vector2(-28, 0))
	_changed_image.size = view_rect.size
	_changed_image.modulate.a = 0.0
	stage.add_child(_changed_image)
	transitioning = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_changed_image, "position", view_rect.position, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_changed_image, "modulate:a", 1.0, 0.24)
	if shot:
		_finish_shot()
	_tween.finished.connect(func() -> void:
		_clear_changed_image()
		_clear_gesture()
		transitioning = false
		_refresh_labels()
	)


func close_view() -> void:
	if not screen.visible:
		return
	_stop_tween()
	_stop_tag_tween()
	_clear_changed_image()
	_clear_hold_preview()
	_clear_gesture()
	transitioning = true
	# The room's camera eases back over the same time; control returns when both are done.
	_tween = create_tween()
	_tween.tween_property(screen, "modulate:a", 0.0, CLOSE_SECONDS * 0.6)
	_tween.tween_interval(CLOSE_SECONDS * 0.4)
	_tween.finished.connect(func() -> void:
		screen.visible = false
		screen.modulate.a = 1.0
		screen.position = Vector2.ZERO
		_clear_shot()
		transitioning = false
		dismissed.emit()
	)


func is_open() -> bool:
	return screen.visible


# --- Close shot ----------------------------------------------------------------

## The picture is in place: bring Kath into the frame and let the shot keep drifting in.
func _enter_shot() -> void:
	var settings: Dictionary = config["shot"]
	_drift_tween = create_tween()
	_drift_tween.tween_property(stage, "scale", Vector2.ONE * 1.05, 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	light_gap.visible = settings.has("light_gap") and not completed
	if settings.has("figure"):
		var who: Dictionary = settings["figure"]
		figure.texture = who["texture"]
		figure.region_rect = who["region"]
		figure.offset = -(who["grip"] as Vector2)
		figure.scale = Vector2.ONE * float(who.get("scale", 1.2))
		figure.rotation = float(who.get("rotation", 0.0))
		figure.modulate = Color(0.9, 0.88, 0.94, 0.0)
		figure.visible = true
		_figure_release = Vector2(-46, 30) if completed else Vector2.ZERO
		_figure_ready = false
		figure.position = _figure_home() + Vector2(-30, 130)
		_figure_tween = create_tween().set_parallel(true)
		_figure_tween.tween_property(figure, "position", _figure_home(), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_figure_tween.tween_property(figure, "modulate:a", 1.0, 0.2)
		_figure_tween.finished.connect(func() -> void: _figure_ready = true)
	if not completed and not first_time_tip.is_empty():
		tip_label.text = first_time_tip
		tip_label.modulate.a = 0.0
		var tip := create_tween()
		tip.tween_property(tip_label, "modulate:a", 0.85, 0.3)
		tip.tween_interval(3.0)
		tip.tween_property(tip_label, "modulate:a", 0.0, 0.5)
	first_time_tip = ""


## Where Kath's hand rests: on the part, moving with it, straining when it sticks.
func _figure_home() -> Vector2:
	var who: Dictionary = (config["shot"] as Dictionary)["figure"]
	var at: Vector2 = who["at"]
	var travel: Vector2 = who.get("travel", Vector2.ZERO)
	return at + travel * _progress + Vector2(_strain * 3.0, 0.0) + _figure_release


func _finish_shot() -> void:
	light_gap.visible = false
	tip_label.modulate.a = 0.0
	# Kath lets go of the bolt once it is home.
	if figure.visible:
		var release := create_tween()
		release.tween_interval(0.3)
		release.tween_property(self, "_figure_release", Vector2(-46, 30), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if config.has("after_text"):
		detail_label.text = config["after_text"]
		detail_label.position = (config["shot"] as Dictionary).get("status_at", Vector2(180, 742))
		detail_label.visible = true
		detail_label.modulate.a = 0.0
		var status := create_tween()
		status.tween_property(detail_label, "modulate:a", 0.9, 0.2)
		status.tween_interval(1.6)
		status.tween_property(detail_label, "modulate:a", 0.0, 0.5)


## A sliver of light at the door's edge that closes as the bolt goes home.
func _place_light_gap(open: float) -> void:
	if not light_gap.visible:
		return
	var gap: Dictionary = (config["shot"] as Dictionary)["light_gap"]
	var width := float(gap.get("width", 7.0)) * clampf(open, 0.0, 1.5)
	light_gap.position = Vector2(float(gap["x"]) - width * 0.5, float(gap.get("top", 0.0)))
	light_gap.size = Vector2(width, float(gap.get("bottom", CANVAS_SIZE.y)) - light_gap.position.y)


func _clear_shot() -> void:
	for tween in [_drift_tween, _figure_tween]:
		if tween != null and tween.is_running():
			tween.kill()
	figure.visible = false
	light_gap.visible = false
	esc_glyph.modulate.a = 0.0
	tip_label.modulate.a = 0.0
	detail_label.position = Vector2(180, 818)
	_figure_ready = false
	_figure_release = Vector2.ZERO
	_strain = 0.0
	_rattle_wait = RATTLE_EVERY * 0.5
	_rattle_left = 0.0


# --- Hands-on gesture ----------------------------------------------------------

func _start_gesture() -> void:
	if completed or not config.has("gesture"):
		return
	var settings: Dictionary = config["gesture"]
	gesture = Gesture.new()
	gesture.handle = settings.get("handle", view_rect)
	gesture.track = settings.get("track", Vector2(80, 0))
	gesture.stick_pixels = float(settings.get("stick_pixels", 0.0))
	gesture.stick_seconds = float(settings.get("stick_seconds", 0.0))
	gesture.arm()
	gesture.progress_changed.connect(_on_gesture_progress)
	gesture.strained.connect(_on_gesture_strained)
	gesture.broke_free.connect(func() -> void: broke_free.emit())
	gesture.committed.connect(_on_gesture_committed)
	_idle_seconds = 0.0
	for region: Rect2 in (config.get("stretch_slide", {}) as Dictionary).get("regions", []):
		var atlas := AtlasTexture.new()
		atlas.atlas = config["texture"]
		atlas.region = Rect2(region.position + (config["before_region"] as Rect2).position, region.size)
		atlas.filter_clip = true
		var piece := TextureRect.new()
		piece.name = "SlidePiece"
		piece.texture = atlas
		piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		piece.stretch_mode = TextureRect.STRETCH_SCALE
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.z_index = 1
		piece.set_meta("region", region)
		stage.add_child(piece)
		_pieces.append(piece)
	_place_pieces(0.0)
	_hint = _make_hint(gesture.track)
	_hint.z_index = 4
	var hint_home: Vector2 = settings.get("hint", gesture.handle.position + Vector2(gesture.handle.size.x * 0.5, -6.0))
	_hint.position = hint_home
	_hint.set_meta("home", hint_home)
	screen.add_child(_hint)


func _on_gesture_progress(value: float) -> void:
	_progress = value
	_place_pieces(value)
	gesture_progress.emit(value)


## A stiff part only shivers until it gives.
func _on_gesture_strained(value: float) -> void:
	_strain = value
	_place_pieces(_progress)


func _on_gesture_committed() -> void:
	var parts: Array = config.get("parts", [])
	if not parts.is_empty():
		gesture_committed.emit(StringName(parts[0].get("action", "")))


## The part of the state sheet that this view shows, in sheet pixels.
func _sheet_crop() -> Rect2:
	if shot:
		return (config["shot"] as Dictionary)["crop"]
	return Rect2(Vector2.ZERO, (config["before_region"] as Rect2).size)


## The bolt is drawn as part of the sheet. Stretching its free end from a fixed
## point carries the tip into the keeper and always covers the painted bolt.
func _place_pieces(value: float) -> void:
	if _pieces.is_empty():
		return
	var slide: Dictionary = config["stretch_slide"]
	var origin_x: float = slide["origin_x"]
	var grow := 1.0 + float(slide["stretch"]) * value
	var crop := _sheet_crop()
	var pixel: float = view_rect.size.x / crop.size.x
	for piece in _pieces:
		var region: Rect2 = piece.get_meta("region")
		var left := origin_x + (region.position.x - origin_x) * grow
		piece.position = view_rect.position + (Vector2(left, region.position.y) - crop.position) * pixel + Vector2(_strain * 2.0, 0.0)
		piece.size = Vector2(region.size.x * grow, region.size.y) * pixel


func _make_hint(track: Vector2) -> Node2D:
	var hint := Node2D.new()
	hint.name = "GestureHint"
	hint.rotation = track.angle()
	for index in 3:
		var chevron := Line2D.new()
		chevron.points = PackedVector2Array([Vector2(-7, -9), Vector2(3, 0), Vector2(-7, 9)])
		chevron.position = Vector2((index - 1) * 17.0, 0.0)
		chevron.width = 3.0
		chevron.default_color = GOLD
		chevron.joint_mode = Line2D.LINE_JOINT_ROUND
		chevron.begin_cap_mode = Line2D.LINE_CAP_ROUND
		chevron.end_cap_mode = Line2D.LINE_CAP_ROUND
		chevron.antialiased = true
		hint.add_child(chevron)
	return hint


func _clear_gesture() -> void:
	gesture = null
	_strain = 0.0
	for piece in _pieces:
		piece.queue_free()
	_pieces.clear()
	if _hint != null:
		_hint.queue_free()
		_hint = null


# --- Helpers -------------------------------------------------------------------

func _state_texture(is_done: bool) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = config["texture"]
	var state: Rect2 = config["after_region"] if is_done else config["before_region"]
	if config.has("shot"):
		var crop: Rect2 = (config["shot"] as Dictionary)["crop"]
		state = Rect2(state.position + crop.position, crop.size)
	atlas.region = state
	return atlas


func _vignette_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.02, 0.03, 0.08, 0.0), Color(0.02, 0.03, 0.08, 0.0), Color(0.02, 0.03, 0.08, 0.72)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = 256
	texture.height = 144
	return texture


func _refresh_labels() -> void:
	title_label.text = config.get("title", "INSPECT")
	inscription_label.text = config.get("inscription_after", "") if completed else config.get("inscription_before", "")
	inscription_label.position = config.get("inscription_position", Vector2(625, 390))
	inscription_label.size = config.get("inscription_size", Vector2(425, 220))
	inscription_label.add_theme_font_size_override("font_size", int(config.get("inscription_font_size", 26)))
	inscription_label.add_theme_color_override("font_color", config.get("inscription_color", Color("33273b")))
	hook_labels.text = config.get("hook_labels_after", "") if completed and config.has("hook_labels_after") else config.get("hook_labels", "")
	tag_label.text = config.get("tag_reveal", "")
	if shot:
		return
	detail_label.text = config.get("after_text", "") if completed else config.get("before_text", "")
	var parts: Array = config.get("parts", [])
	var lines := PackedStringArray()
	for index in parts.size():
		lines.append(("› " if index == selected_part else "  ") + String(parts[index].get("label", "")))
	parts_label.text = "\n".join(lines)
	if completed:
		controls_label.text = "ESC  RETURN  ·  %s" % config.get("done_control", "ALREADY SECURED")
	elif config.has("control_override"):
		controls_label.text = config["control_override"]
	else:
		controls_label.text = "E  %s  ·  ESC  RETURN%s" % [config.get("verb", "OPERATE"), "  ·  ← / →  SELECT" if parts.size() > 1 else ""]


func _labels() -> Array:
	return [title_label, detail_label, controls_label, parts_label, hold_label, hook_labels, tag_label, inscription_label]


func _set_labels_alpha(alpha: float) -> void:
	for label in _labels():
		label.modulate.a = alpha
	esc_glyph.modulate.a = 0.0
	tip_label.modulate.a = 0.0


func _stop_tween() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()


func _stop_tag_tween() -> void:
	if _tag_tween != null and _tag_tween.is_running():
		_tag_tween.kill()


func _clear_changed_image() -> void:
	if _changed_image != null:
		if completed:
			picture.texture = _state_texture(true)
		_changed_image.queue_free()
		_changed_image = null


func _clear_hold_preview() -> void:
	if _hold_preview != null:
		_hold_preview.queue_free()
		_hold_preview = null


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
