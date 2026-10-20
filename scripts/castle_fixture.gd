@tool
extends Node2D
## Scalable Chapter I silhouette props. Origin and dimensions are local pixels.

enum Kind { RAIL, LAMP, DOORFRAME, SPEAKING_TUBE, ANGLE_NEEDLE, EXIT_MARKER }

const SHADOW := Color("17243b")
const STONE := Color("344968")
const BRASS := Color("82633f")
const EDGE := Color("a47b48")
const LAMP_LIGHT := Color("ffd18a")
const WARNING := Color("b94c51")

@export var kind: Kind = Kind.RAIL:
	set(value):
		kind = value
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.RAIL:
			_draw_rail()
		Kind.LAMP:
			_draw_lamp()
		Kind.DOORFRAME:
			_draw_doorframe()
		Kind.SPEAKING_TUBE:
			_draw_speaking_tube()
		Kind.ANGLE_NEEDLE:
			_draw_angle_needle()
		Kind.EXIT_MARKER:
			_draw_exit_marker()


func _draw_rail() -> void:
	# Segment is 160 px wide, with its top at local y=0 and feet at y=68.
	for x in [0.0, 80.0, 160.0]:
		draw_rect(Rect2(x - 7.0, 3.0, 14.0, 65.0), SHADOW)
		draw_rect(Rect2(x - 4.0, 5.0, 8.0, 61.0), STONE)
		draw_circle(Vector2(x, 2.0), 9.0, SHADOW)
		draw_circle(Vector2(x - 2.0, 0.0), 2.0, EDGE)
	draw_rect(Rect2(-4.0, 18.0, 168.0, 8.0), SHADOW)
	draw_rect(Rect2(-4.0, 20.0, 168.0, 2.0), EDGE)
	draw_line(Vector2(8, 60), Vector2(80, 25), SHADOW, 5.0)
	draw_line(Vector2(80, 25), Vector2(152, 60), SHADOW, 5.0)
	draw_line(Vector2(8, 25), Vector2(80, 60), SHADOW, 5.0)
	draw_line(Vector2(80, 60), Vector2(152, 25), SHADOW, 5.0)
	draw_line(Vector2(8, 60), Vector2(80, 25), BRASS, 1.5)
	draw_line(Vector2(80, 25), Vector2(152, 60), BRASS, 1.5)
	draw_line(Vector2(8, 25), Vector2(80, 60), BRASS, 1.5)
	draw_line(Vector2(80, 60), Vector2(152, 25), BRASS, 1.5)


func _draw_lamp() -> void:
	draw_line(Vector2(0, -56), Vector2(0, -40), BRASS, 5.0)
	draw_rect(Rect2(-17, -42, 34, 48), SHADOW)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -35), Vector2(12, -35), Vector2(10, 0), Vector2(-10, 0)]), LAMP_LIGHT)
	draw_line(Vector2(-17, -42), Vector2(17, -42), EDGE, 4.0)
	draw_line(Vector2(-17, 5), Vector2(17, 5), EDGE, 4.0)
	draw_line(Vector2(-14, -39), Vector2(-10, 3), BRASS, 3.0)
	draw_line(Vector2(14, -39), Vector2(10, 3), BRASS, 3.0)


func _draw_doorframe() -> void:
	# Fixed-tower service hatch, 112 x 222 px; origin is bottom center.
	draw_rect(Rect2(-56, -222, 112, 222), SHADOW)
	draw_rect(Rect2(-48, -214, 96, 205), STONE)
	draw_rect(Rect2(-40, -202, 80, 190), SHADOW)
	draw_line(Vector2(-56, -222), Vector2(56, -222), EDGE, 8.0)
	for x in [-55.0, 55.0]:
		draw_line(Vector2(x, -222), Vector2(x, 0), BRASS, 7.0)
	draw_circle(Vector2(25, -95), 5.0, EDGE)
	draw_rect(Rect2(-50, -9, 100, 9), BRASS)


func _draw_speaking_tube() -> void:
	draw_line(Vector2(-46, 0), Vector2(16, 0), BRASS, 7.0)
	draw_line(Vector2(-46, 0), Vector2(-46, 32), BRASS, 7.0)
	draw_colored_polygon(PackedVector2Array([Vector2(16, -13), Vector2(43, -29), Vector2(43, 29), Vector2(16, 13)]), BRASS)
	draw_line(Vector2(43, -29), Vector2(43, 29), EDGE, 5.0)
	draw_circle(Vector2(-46, 0), 8.0, EDGE)


func _draw_angle_needle() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-7, -14), Vector2(2, -100), Vector2(8, -14)]), WARNING)
	draw_circle(Vector2.ZERO, 12.0, SHADOW)
	draw_circle(Vector2.ZERO, 6.0, EDGE)


func _draw_exit_marker() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, -28), Vector2(26, 0), Vector2(0, 28), Vector2(-26, 0)]), SHADOW)
	draw_line(Vector2(-18, 0), Vector2(18, 0), EDGE, 4.0)
	draw_line(Vector2(7, -10), Vector2(18, 0), EDGE, 4.0)
	draw_line(Vector2(7, 10), Vector2(18, 0), EDGE, 4.0)
