extends Node2D
## A light, deterministic rain layer between the city and room architecture.

const WIDTH := 1672.0
const HEIGHT := 941.0

var strength := 0.0
var drift := 0.0


func set_strength(value: float) -> void:
	strength = clampf(value, 0.0, 1.0)
	visible = strength > 0.0
	set_process(visible)
	queue_redraw()


func _process(delta: float) -> void:
	drift = fmod(drift + delta * 180.0, HEIGHT)
	queue_redraw()


func _draw() -> void:
	if strength <= 0.0:
		return
	var count := roundi(18.0 + 105.0 * strength)
	var color := Color(0.84, 0.91, 1.0, 0.08 + 0.15 * strength)
	for index in count:
		var x := fmod(float((index * 1277 + 193) % 1672) + drift * 0.25, WIDTH)
		var y := fmod(float((index * 709 + 281) % 941) + drift, HEIGHT)
		draw_line(Vector2(x, y), Vector2(x - 12.0, y + 36.0), color, 1.0, true)
