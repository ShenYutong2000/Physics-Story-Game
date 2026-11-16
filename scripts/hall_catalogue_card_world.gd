extends Sprite2D
## Small desk card cropped from the same two-state close-up sheet.

const SHEET: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/catalogue-card-states.png")
const CROP := Rect2(176, 342, 484, 302)

var flipped := false
var _tween: Tween


func _ready() -> void:
	texture = _atlas(false)


func set_flipped(value: bool, animate: bool = true) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	flipped = value
	if not animate or not is_inside_tree():
		texture = _atlas(value)
		scale.x = absf(scale.x)
		return
	var width := absf(scale.x)
	_tween = create_tween()
	_tween.tween_property(self, "scale:x", 0.0, 0.14)
	_tween.tween_callback(func() -> void: texture = _atlas(flipped))
	_tween.tween_property(self, "scale:x", width, 0.14)


func _atlas(value: bool) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(CROP.position + Vector2(836 if value else 0, 0), CROP.size)
	return atlas
