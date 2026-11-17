extends Node2D
## Small room-scale hardware that follows the same state as the close-up art.

enum Kind { DOOR, WINDOW }

@export var kind := Kind.DOOR

var secured := false
## While the player moves the part by hand in the close-up, the room copy follows.
var preview := 0.0
var progress := 0.0
var flutter_phase := 0.0


func _process(delta: float) -> void:
	progress = move_toward(progress, 1.0 if secured else preview, delta * 4.0)
	if kind == Kind.WINDOW and not secured:
		flutter_phase += delta * 6.2
	queue_redraw()


func set_preview(value: float) -> void:
	preview = clampf(value, 0.0, 1.0)


func set_secured(value: bool, animate: bool = true) -> void:
	secured = value
	preview = 0.0
	if not animate:
		progress = 1.0 if value else 0.0
	queue_redraw()


func _draw() -> void:
	var brass := Color("bd8743")
	var gold := Color("f0c57a")
	var shadow := Color("302540")
	if kind == Kind.DOOR:
		draw_rect(Rect2(-43, -15, 84, 30), shadow)
		draw_rect(Rect2(-39, -12, 24, 24), brass)
		draw_rect(Rect2(22, -11, 18, 22), brass)
		draw_rect(Rect2(-17 + progress * 18.0, -5, 30, 10), gold)
		draw_line(Vector2(-16 + progress * 18.0, -5), Vector2(12 + progress * 18.0, -5), Color("fff0b5"), 2.0)
		draw_circle(Vector2(-28, 0), 3.0, gold)
		draw_circle(Vector2(31, 0), 2.8, shadow)
	else:
		draw_rect(Rect2(-34, -17, 67, 34), shadow)
		draw_rect(Rect2(12, -13, 19, 26), brass)
		var angle := lerpf(-0.52 + sin(flutter_phase) * 0.045, 0.0, progress)
		var tip := Vector2(27.0 * cos(angle), 27.0 * sin(angle))
		draw_line(Vector2(-15, 0), tip, brass, 10.0, true)
		draw_line(Vector2(-15, -2), tip + Vector2(0, -2), gold, 3.0, true)
		draw_circle(Vector2(-15, 0), 5.0, gold)
		draw_circle(Vector2(22, 0), 3.0, shadow)
