extends SceneTree

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	await process_frame
	var kath: CharacterBody2D = hall.get_node("Kath")
	var sprite: AnimatedSprite2D = kath.get_node("AnimatedSprite2D")
	var starting_x: float = kath.position.x
	# Week 2 starts with a short line of dialogue before movement is unlocked.
	hall._advance_dialogue()

	if hall.get_node("Far").z_index >= hall.get_node("Mid").z_index \
		or hall.get_node("Mid").z_index >= hall.get_node("Foreground").z_index:
		_fail("Scene layers are out of order.")
		return
	if sprite.sprite_frames == null or not sprite.is_playing():
		_fail("Kath's idle animation did not load and start.")
		return
	if InputMap.action_get_events("move_left").size() != 2 \
		or InputMap.action_get_events("move_right").size() != 2:
		_fail("A/D and arrow key bindings are missing.")
		return
	if ProjectSettings.get_setting("display/window/size/viewport_width") != 1672 \
		or ProjectSettings.get_setting("display/window/size/viewport_height") != 941:
		_fail("The scene canvas dimensions changed.")
		return

	Input.action_press("move_right")
	for i in 30:
		await physics_frame
	Input.action_release("move_right")
	if kath.position.x <= starting_x or not kath.is_walking:
		_fail("Kath did not move right with the walking animation.")
		return

	Input.action_press("move_left")
	for i in 12:
		await physics_frame
	Input.action_release("move_left")
	if not sprite.flip_h:
		_fail("Kath did not face left.")
		return

	kath.position.x = kath.right_limit - 1.0
	Input.action_press("move_right")
	for i in 12:
		await physics_frame
	Input.action_release("move_right")
	if kath.position.x > kath.right_limit or kath.position.y != kath.floor_y:
		_fail("Kath left the room boundaries or the floor.")
		return

	kath.position.x = kath.left_limit + 1.0
	Input.action_press("move_left")
	for i in 12:
		await physics_frame
	Input.action_release("move_left")
	if kath.position.x < kath.left_limit:
		_fail("Kath crossed the left room boundary.")
		return

	for i in 20:
		await physics_frame
	if kath.is_walking:
		_fail("Kath did not return to idle after stopping.")
		return

	print("WEEK1_SMOKE_OK: scene, resources, input, movement, facing, bounds")
	quit(0)


func _fail(message: String) -> void:
	push_error("WEEK1_SMOKE_FAIL: " + message)
	quit(1)
