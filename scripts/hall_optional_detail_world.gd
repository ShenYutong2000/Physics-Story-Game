extends Sprite2D
## A small, painted room-scale reminder of an optional close-up action.

const PLAQUE_SHEET: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/old-plaque-states.png")
const CLOCK_SHEET: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/clock-inner-cover-states.png")
const PLAQUE_CROP := Rect2(589, 456, 255, 110)
const CLOCK_CROP := Rect2(245, 415, 405, 237)

@export_enum("Plaque", "Clock cover") var kind := 0

var revealed := false
var _tween: Tween


func _ready() -> void:
	texture = _atlas(false)


func set_revealed(value: bool, animate: bool = true) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	revealed = value
	if not animate or not is_inside_tree():
		texture = _atlas(value)
		modulate.a = 1.0
		return
	modulate.a = 0.4
	texture = _atlas(value)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _atlas(value: bool) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CLOCK_SHEET if kind == 1 else PLAQUE_SHEET
	var crop: Rect2 = CLOCK_CROP if kind == 1 else PLAQUE_CROP
	atlas.region = Rect2(crop.position + Vector2(887 if value else 0, 0), crop.size)
	return atlas
