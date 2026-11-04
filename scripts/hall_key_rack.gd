extends Sprite2D
## Cropped room-scale rack, matching the two close-up states.

const SHEET: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/duty-keys-states.png")
const CROP := Rect2(58, 88, 770, 646)

var east_key_sorted := false
var _tween: Tween


func _ready() -> void:
	texture = _atlas(false)


func set_sorted(value: bool, animate: bool = true) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	east_key_sorted = value
	if not animate or not is_inside_tree():
		texture = _atlas(value)
		return
	var changed := Sprite2D.new()
	changed.name = "RackChanged"
	changed.texture = _atlas(value)
	changed.modulate.a = 0.0
	changed.position = Vector2(22 if value else -22, 0)
	add_child(changed)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(changed, "modulate:a", 1.0, 0.32)
	_tween.tween_property(changed, "position:x", 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(func() -> void:
		texture = _atlas(east_key_sorted)
		changed.queue_free()
	)


func _atlas(value: bool) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = SHEET
	result.region = Rect2(CROP.position + Vector2(887 if value else 0, 0), CROP.size)
	return result
