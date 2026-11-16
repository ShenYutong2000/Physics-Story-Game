extends Node2D
## Room-scale winding handle and pendulum in the grandfather clock's open housing.

const PENDULUM_ART: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/layer-clock-pendulum.png")

var wound := false
var winding_progress := 0.0
var phase := 0.0
var pendulum: Node2D


func _ready() -> void:
	pendulum = Node2D.new()
	pendulum.name = "PendulumPivot"
	add_child(pendulum)
	var atlas := AtlasTexture.new()
	atlas.atlas = PENDULUM_ART
	atlas.region = Rect2(33, 136, 775, 1622)
	var art := Sprite2D.new()
	art.name = "PendulumArt"
	art.texture = atlas
	art.centered = false
	art.position = Vector2(-28, -8)
	art.scale = Vector2.ONE * 0.069
	pendulum.add_child(art)


func _process(delta: float) -> void:
	phase += delta * (4.5 if wound else 1.7)
	pendulum.rotation = sin(phase) * (0.13 if wound else 0.025)
	if winding_progress > 0.0 and not wound:
		queue_redraw()


func set_wound(value: bool) -> void:
	wound = value
	if value:
		winding_progress = 1.0
	queue_redraw()


func set_winding_progress(value: float) -> void:
	winding_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var base := Vector2(75, 23)
	var angle := winding_progress * PI * 0.5
	var tip := base + Vector2(19 * cos(angle), 19 * sin(angle))
	draw_circle(base, 10.0, Color("332a43"))
	draw_circle(base, 7.0, Color("c2914a"))
	draw_line(base, tip, Color("c2914a"), 7.0, true)
	draw_circle(tip, 5.2, Color("f5d490"))
	draw_circle(base, 2.6, Color("fff0b6"))
