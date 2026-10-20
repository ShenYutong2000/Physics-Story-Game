extends Node2D
## Uses the official deck art without triggering its dialogue, notes, exits or spawn-tag consumption.

const FLOOR_Y := 755.0
const WALK_MIN_X := 85.0
const WALK_MAX_X := 625.0
const SOURCE_WING_ANGLE := 12.0

@onready var kath: CharacterBody2D = $Kath
@onready var wing_pivot: Node2D = $CastleWingPivot
@onready var needle_pivot: Node2D = $DialNeedlePivot

var preview_pose: StringName = &"tilted"


func _ready() -> void:
	$HallUI.visible = false
	kath.floor_y = FLOOR_Y
	kath.floor_slope = 0.0
	kath.left_limit = WALK_MIN_X
	kath.right_limit = WALK_MAX_X
	set_preview_pose(&"tilted")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1:
			set_preview_pose(&"tilted")
		KEY_2:
			set_preview_pose(&"inverted")
		KEY_3:
			set_preview_pose(&"restored")


func set_preview_pose(pose: StringName) -> void:
	assert(pose == &"tilted" or pose == &"inverted" or pose == &"restored")
	preview_pose = pose
	var state: Node = get_node_or_null("/root/PrologueState")
	var angle: float = state.castle_pose_angle_radians(pose) if state != null else deg_to_rad(12.0 if pose == &"tilted" else 180.0 if pose == &"inverted" else 0.0)
	wing_pivot.rotation = angle - deg_to_rad(SOURCE_WING_ANGLE)
	needle_pivot.rotation = deg_to_rad(0.0 if pose == &"tilted" else 40.0 if pose == &"inverted" else -12.0)
