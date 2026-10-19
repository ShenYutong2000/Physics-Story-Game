extends Node2D
## Phase 2 art-only rig. It never writes PrologueState or opens a story exit.

const BASKET_EMPTY: Texture2D = preload("res://chapter1-assets/maintenance-shaft-layers-v1/basket-empty.png")
const BASKET_OPEN: Texture2D = preload("res://chapter1-assets/maintenance-shaft-layers-v1/basket-gate-open.png")
const BASKET_X := 1100.0
const HIGH_ROOT_Y := 358.0
const LOW_ROOT_Y := 703.0
const HIGH_LEDGE_Y := 430.0
const LOWER_FLOOR_Y := 790.0

@onready var rope_shadow: Line2D = $RopeShadow
@onready var rope_core: Line2D = $RopeCore
@onready var moving_pulley: Sprite2D = $MovingPulley
@onready var basket_rig: Node2D = $BasketRig
@onready var basket_body: Sprite2D = $BasketRig/BasketBody
@onready var tool_crate: Sprite2D = $BasketRig/ToolCrate
@onready var erin_in_basket: Node2D = $BasketRig/ErinInBasket
@onready var erin_on_ledge: Node2D = $ErinOnLedge

var rope_mode: StringName = &"tool"
var basket_height: StringName = &"high"
var load_state: StringName = &"tools"


func _ready() -> void:
	_refresh_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("interact"):
		set_preview_state(&"passenger" if rope_mode == &"tool" else &"tool", basket_height, &"person" if rope_mode == &"tool" else &"tools")
	elif event.is_action_pressed("move_up"):
		set_preview_state(rope_mode, &"high", load_state)
	elif event.is_action_pressed("move_down"):
		set_preview_state(rope_mode, &"low", load_state)
	elif event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_1:
				set_preview_state(&"tool", basket_height, &"empty")
			KEY_2:
				set_preview_state(&"tool", basket_height, &"tools")
			KEY_3:
				set_preview_state(&"passenger", basket_height, &"person")
			KEY_4:
				set_preview_state(&"passenger", &"high", &"docked")


func set_preview_state(mode: StringName, height: StringName, load: StringName) -> void:
	assert(mode == &"tool" or mode == &"passenger")
	assert(height == &"high" or height == &"low")
	assert(load == &"empty" or load == &"tools" or load == &"person" or load == &"docked")
	rope_mode = mode
	basket_height = height
	load_state = load
	_refresh_preview()


func _refresh_preview() -> void:
	if basket_rig == null:
		return
	basket_rig.position = Vector2(BASKET_X, HIGH_ROOT_Y if basket_height == &"high" else LOW_ROOT_Y)
	moving_pulley.visible = rope_mode == &"passenger"
	moving_pulley.position = Vector2(BASKET_X, basket_rig.position.y - 138.0)
	tool_crate.visible = load_state == &"tools"
	erin_in_basket.visible = load_state == &"person"
	erin_on_ledge.visible = load_state != &"person"
	basket_body.texture = BASKET_OPEN if load_state == &"docked" or (basket_height == &"high" and load_state == &"tools") else BASKET_EMPTY
	var path: PackedVector2Array = _rope_path()
	rope_shadow.points = path
	rope_core.points = path


func _rope_path() -> PackedVector2Array:
	# Winch -> upper fixed pulley is shared by both arrangements.
	var points := PackedVector2Array([
		Vector2(690, 665), Vector2(1028, 119), Vector2(1030, 98),
		Vector2(1042, 79), Vector2(1060, 72), Vector2(1080, 79),
		Vector2(1093, 99), Vector2(1095, 119)
	])
	if rope_mode == &"tool":
		# A direct hanging run gives one rope segment supporting the basket.
		points.append(Vector2(BASKET_X, basket_rig.position.y - 78.0))
	else:
		# The load is held by two runs: fixed pulley -> moving pulley -> top anchor.
		var wheel_y: float = moving_pulley.position.y
		points.append_array(PackedVector2Array([
			Vector2(1065, wheel_y - 5.0),
			Vector2(1066, wheel_y + 18.0), Vector2(1080, wheel_y + 34.0),
			Vector2(1100, wheel_y + 39.0), Vector2(1120, wheel_y + 34.0),
			Vector2(1135, wheel_y + 18.0), Vector2(1135, wheel_y - 5.0),
			Vector2(1160, 94)
		]))
	return points
