extends RefCounted
## A hands-on gesture inside a close-up. Mouse and keyboard reach the same result.
##
## SLIDE: drag the handle along `track`, or hold one of `hold_actions`.
## A stiff part first resists (`stick_pixels` / `stick_seconds`), then gives.
## Progress stays where the player leaves it; past `commit_at` the part
## settles home by itself and `committed` fires once.
## (Hold and pick-and-place kinds join this file with the clock, keys and stamp.)

signal progress_changed(value: float)
## 0..1 while the player leans on a part that has not given yet.
signal strained(value: float)
signal broke_free
signal committed

const SETTLE_SPEED := 5.0

## Screen-space area that starts a drag.
var handle := Rect2()
## Screen-space drag that carries the part the whole way.
var track := Vector2(80, 0)
var hold_actions: Array[StringName] = [&"interact"]
## Seconds of holding a key for the full travel.
var hold_seconds := 0.6
## A single key press nudges a free part, so a tap is never silently ignored.
var press_nudge := 0.12
var commit_at := 0.9
## Drag distance, and key-hold time, before a stiff part starts to move.
var stick_pixels := 0.0
var stick_seconds := 0.0

var progress := 0.0
var dragging := false
var settling := false
var done := false
var stuck := false
var _held := false
var _held_seconds := 0.0
var _drag_origin := Vector2.ZERO
var _drag_base := 0.0


## Call once after setting the stick values.
func arm() -> void:
	stuck = stick_pixels > 0.0 or stick_seconds > 0.0


## Returns true when the event belonged to the gesture.
func handle_event(event: InputEvent) -> bool:
	if done or settling:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and handle.has_point(event.position):
			dragging = true
			_drag_origin = event.position
			_drag_base = progress
			return true
		if not event.pressed and dragging:
			dragging = false
			_relax()
			return true
		return false
	if event is InputEventMouseMotion and dragging:
		var pull: float = (event.position - _drag_origin).dot(track.normalized())
		if stuck:
			if pull < stick_pixels:
				strained.emit(clampf(pull / stick_pixels, 0.0, 1.0))
				return true
			# It gives: measure the rest of the drag from here.
			_drag_origin += track.normalized() * stick_pixels
			pull -= stick_pixels
			_break_free()
		_set_progress(_drag_base + pull / track.length())
		return true
	for action in hold_actions:
		if event.is_action_pressed(action):
			_held = true
			_held_seconds = 0.0
			if stuck:
				strained.emit(0.5)
			else:
				_set_progress(progress + press_nudge)
			return true
		if event.is_action_released(action) and _held:
			_held = false
			_relax()
			return true
	return false


func process(delta: float) -> void:
	if done:
		return
	if settling:
		progress = move_toward(progress, 1.0, delta * SETTLE_SPEED)
		progress_changed.emit(progress)
		if progress >= 1.0:
			settling = false
			done = true
			committed.emit()
		return
	if not _held:
		return
	if stuck:
		_held_seconds += delta
		if _held_seconds < stick_seconds:
			strained.emit(clampf(_held_seconds / stick_seconds, 0.0, 1.0))
			return
		_break_free()
	_set_progress(progress + delta / hold_seconds)


## True while the player is actively moving the part.
func is_active() -> bool:
	return dragging or _held or settling


## Stop a drag or key hold without losing the progress made so far.
func let_go() -> void:
	dragging = false
	_held = false
	_relax()


func _break_free() -> void:
	stuck = false
	strained.emit(0.0)
	broke_free.emit()


func _relax() -> void:
	if stuck:
		strained.emit(0.0)


func _set_progress(value: float) -> void:
	var next := clampf(value, 0.0, 1.0)
	if is_equal_approx(next, progress):
		return
	progress = next
	progress_changed.emit(progress)
	if progress >= commit_at:
		dragging = false
		_held = false
		settling = true
