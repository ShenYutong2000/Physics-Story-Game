extends Sprite2D
## Small desk book switches from its checklist spread to the filed blank spread.

const SHEET: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/round-book-states.png")
const CROP := Rect2(28, 270, 794, 475)

var filed := false
var _tween: Tween


func _ready() -> void:
	texture = _atlas(false)


func set_filed(value: bool, animate: bool = true) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	filed = value
	if not animate or not is_inside_tree():
		texture = _atlas(value)
		return
	var changed := Sprite2D.new()
	changed.name = "FiledSpread"
	changed.texture = _atlas(value)
	changed.modulate.a = 0.0
	add_child(changed)
	_tween = create_tween()
	_tween.tween_property(changed, "modulate:a", 1.0, 0.28)
	_tween.tween_callback(func() -> void:
		texture = _atlas(filed)
		changed.queue_free()
	)


func _atlas(value: bool) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = SHEET
	result.region = Rect2(CROP.position + Vector2(887 if value else 0, 0), CROP.size)
	return result
