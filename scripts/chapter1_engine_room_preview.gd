extends Node2D
## Art-only engine-room inspection. Does not change castle_pose, notes or exits.

const STOP_TEXTURE: Texture2D = preload("res://chapter1-assets/engine-room-layers-v1/stop-signal.png")
const NORMAL_TEXTURE: Texture2D = preload("res://chapter1-assets/engine-room-layers-v1/normal-signal.png")
const FLOOR_Y := 725.0
const WALK_MIN_X := 115.0
const WALK_MAX_X := 1555.0

@onready var window_wing_pivot: Node2D = $WindowWingPivot
@onready var normal_linkage: Sprite2D = $NormalLinkage
@onready var backup_lock: Sprite2D = $BackupLock
@onready var brake_wheel: Sprite2D = $BrakeWheel
@onready var brake_pawl: Sprite2D = $BrakePawl
@onready var stop_signal: Sprite2D = $StopSignal
@onready var jam_debris: Sprite2D = $JamDebris

var preview_pose: StringName = &"inverted"
var repair_phase: StringName = &"jammed"


func _ready() -> void:
	var state: Node = get_node_or_null("/root/PrologueState")
	if state != null:
		preview_pose = state.castle_pose
		if preview_pose == &"upright" or preview_pose == &"restored":
			repair_phase = &"restored"
	_refresh_art()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1:
			set_preview_state(&"inverted", &"jammed")
		KEY_2:
			set_preview_state(&"inverted", &"cleared")
		KEY_3:
			set_preview_state(&"inverted", &"braked")
		KEY_4:
			set_preview_state(&"restored", &"restored")


func set_preview_state(pose: StringName, phase: StringName) -> void:
	assert(pose == &"upright" or pose == &"tilted" or pose == &"inverted" or pose == &"restored")
	assert(phase == &"jammed" or phase == &"cleared" or phase == &"braked" or phase == &"restored")
	preview_pose = pose
	repair_phase = phase
	_refresh_art()


func _refresh_art() -> void:
	if window_wing_pivot == null:
		return
	var state: Node = get_node_or_null("/root/PrologueState")
	if state != null:
		window_wing_pivot.rotation = state.castle_pose_angle_radians(preview_pose)
	else:
		window_wing_pivot.rotation = deg_to_rad(180.0 if preview_pose == &"inverted" else 12.0 if preview_pose == &"tilted" else 0.0)
	jam_debris.visible = repair_phase == &"jammed"
	# The normal linkage slides right only after the blocked track is cleared.
	normal_linkage.position = Vector2(852.0 + (0.0 if repair_phase == &"jammed" else 12.0 if repair_phase != &"restored" else 25.0), 460.0)
	# The independent backup bolt stays on the separate support until restoration.
	backup_lock.position.y = 310.0 if repair_phase != &"restored" else 250.0
	brake_wheel.modulate = Color(1, 1, 1, 1) if repair_phase == &"braked" or repair_phase == &"restored" else Color(0.72, 0.74, 0.82, 1)
	brake_pawl.visible = repair_phase == &"braked" or repair_phase == &"restored"
	stop_signal.texture = NORMAL_TEXTURE if repair_phase == &"restored" else STOP_TEXTURE
