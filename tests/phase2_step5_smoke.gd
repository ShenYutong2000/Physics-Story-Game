extends SceneTree
## Verify both future rescue rig paths and keep the art preview out of story state.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft_preview.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	var notes_before: int = state.notes.size()
	var pose_before: StringName = state.castle_pose
	var shaft := SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	var kath: CharacterBody2D = shaft.get_node("Kath")
	if not is_equal_approx(kath.position.y, 790.0) or kath.left_limit != 90.0 or kath.right_limit != 815.0:
		_fail("Kath can walk off the lower work platform.")
		return
	if shaft.get_node("FarWheelworks").z_index >= shaft.get_node("FixedArchitecture").z_index:
		_fail("Far wheelworks appear in front of the fixed shaft.")
		return
	if shaft.get_node("FrontOccluders").z_index <= kath.z_index:
		_fail("The near masonry cannot occlude Kath.")
		return
	if shaft.get_node("ReceivingRail").z_index <= shaft.get_node("ErinOnLedge").z_index:
		_fail("The receiving rail cannot cover Erin's lower silhouette.")
		return
	if shaft.get_node("MovingPulley").visible:
		_fail("The tool configuration wrongly shows the moving pulley.")
		return
	var basket: Node2D = shaft.get_node("BasketRig")
	var tool_path: PackedVector2Array = shaft.get_node("RopeCore").points
	if tool_path.size() != 9 or tool_path[-1].distance_to(Vector2(1100, basket.position.y - 78.0)) > 0.1:
		_fail("The direct tool rope does not end at the basket eye.")
		return
	if not is_equal_approx(basket.position.y + 87.0, 445.0):
		_fail("The high basket floor is not aligned with Erin's ledge.")
		return
	shaft.set_preview_state(&"passenger", &"high", &"person")
	var person_path: PackedVector2Array = shaft.get_node("RopeCore").points
	if person_path.size() <= tool_path.size() or person_path[-1].distance_to(Vector2(1160, 94)) > 0.1:
		_fail("The passenger rope does not return through the moving pulley to the top anchor.")
		return
	if not shaft.get_node("MovingPulley").visible or not shaft.get_node("BasketRig/ErinInBasket").visible or shaft.get_node("ErinOnLedge").visible:
		_fail("The passenger basket visuals are inconsistent.")
		return
	if shaft.get_node("BasketRig/ToolCrate").visible:
		_fail("The tool crate remained in the passenger basket.")
		return
	if shaft.get_node("BasketRig/ErinInBasket").z_index <= shaft.get_node("BasketRig/BasketBody").z_index:
		_fail("The passenger is hidden behind the basket texture.")
		return
	shaft.set_preview_state(&"tool", &"low", &"tools")
	if not is_equal_approx(basket.position.y + 87.0, shaft.LOWER_FLOOR_Y):
		_fail("The low basket floor is not aligned with the loading spur.")
		return
	if not shaft.get_node("BasketRig/ToolCrate").visible or not shaft.get_node("LoadingSpur").visible:
		_fail("The lower tool-loading state is incomplete.")
		return
	if shaft.get_node("BasketRig/ToolCrate").z_index <= shaft.get_node("BasketRig/BasketBody").z_index:
		_fail("The tool crate is hidden behind the basket texture.")
		return
	shaft.set_preview_state(&"passenger", &"high", &"docked")
	if not shaft.get_node("ErinOnLedge").visible or shaft.get_node("BasketRig/ErinInBasket").visible:
		_fail("The docked state does not put Erin on the receiving ledge.")
		return
	if shaft.get_node("BasketRig/BasketBody").texture != shaft.BASKET_OPEN:
		_fail("The docked basket gate did not open.")
		return
	if state.notes.size() != notes_before or state.castle_pose != pose_before:
		_fail("The art preview modified official story progress.")
		return
	print("PHASE2_STEP5_SMOKE_OK: safe platforms, two real rope paths, cargo/passenger/dock layers, untouched story")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
