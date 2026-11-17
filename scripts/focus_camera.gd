extends Camera2D
## Eases toward one object for a close look, then back to the room's fixed framing.
## At rest the view is identical to a room without a camera.

const CANVAS := Vector2(1672, 941)

var rest_position := CANVAS / 2.0
var _tween: Tween


func _ready() -> void:
	rest_position = position


## The view centre that shows `point` at `zoom_factor` without leaving the canvas.
func centre_for(point: Vector2, zoom_factor: float) -> Vector2:
	var half := CANVAS / (2.0 * maxf(zoom_factor, 1.0))
	return point.clamp(half, CANVAS - half)


## Where a world point lands on screen once the camera has settled on it.
func screen_point_after_focus(point: Vector2, zoom_factor: float) -> Vector2:
	return (point - centre_for(point, zoom_factor)) * zoom_factor + CANVAS / 2.0


func focus_on(point: Vector2, zoom_factor: float, seconds: float = 0.4) -> void:
	_move(centre_for(point, zoom_factor), Vector2.ONE * maxf(zoom_factor, 1.0), seconds)


func release(seconds: float = 0.35) -> void:
	_move(rest_position, Vector2.ONE, seconds)


func is_at_rest() -> bool:
	return position.is_equal_approx(rest_position) and zoom.is_equal_approx(Vector2.ONE)


## Can be called mid-move: the new move starts from wherever the camera is.
func _move(target: Vector2, target_zoom: Vector2, seconds: float) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	if seconds <= 0.0:
		position = target
		zoom = target_zoom
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "position", target, seconds)
	_tween.tween_property(self, "zoom", target_zoom, seconds)
