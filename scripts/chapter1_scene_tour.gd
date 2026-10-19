extends Node2D
## Developer-only five-room art route. Room instances are cached, but never write official story state.

const ROOMS := [
	preload("res://scenes/chapter1_control_walkway_preview.tscn"),
	preload("res://scenes/chapter1_inverted_room_preview.tscn"),
	preload("res://scenes/chapter1_maintenance_shaft_preview.tscn"),
	preload("res://scenes/chapter1_engine_room_preview.tscn"),
	preload("res://scenes/chapter1_observatory_preview.tscn")
]
const NAMES := ["Control Walkway", "Inverted Room", "Maintenance Shaft", "Engine Room", "Observatory"]
const HINTS := [
	"A/D or arrows: walk  |  1–3: castle pose  |  E at the right edge: next art scene",
	"A/D or arrows: walk  |  E at an edge: art-scene travel (no story inversion)",
	"A/D or arrows: walk  |  E: rope preview  |  W/S: basket  |  1–4: load state",
	"A/D or arrows: walk  |  1–4: repair-state art  |  E at an edge: travel",
	"A/D: walk  |  E near desk: open / read  |  1–3 while reading: pages"
]
const PREVIOUS_EXIT_X := [-1.0, 140.0, 130.0, 130.0, 1510.0]
const NEXT_EXIT_X := [590.0, 1410.0, 780.0, 1515.0, -1.0]
const SPAWN_FROM_PREVIOUS := [430.0, 260.0, 260.0, 310.0, 1360.0]
const SPAWN_FROM_NEXT := [500.0, 1300.0, 690.0, 1390.0, 1360.0]
const EXIT_RADIUS := 74.0

@onready var room_host: Node2D = $RoomHost
@onready var room_title: Label = $TourHUD/RoomTitle
@onready var controls_hint: Label = $TourHUD/ControlsHint
@onready var exit_backdrop: ColorRect = $TourHUD/ExitBackdrop
@onready var exit_prompt: Label = $TourHUD/ExitPrompt

var room_index := -1
var active_room: Node2D
var cached_rooms: Array[Node2D] = []
var transition_pending := false


func _ready() -> void:
	for i in ROOMS.size():
		cached_rooms.append(null)
	show_room(0, -1)


func _exit_tree() -> void:
	# Detached cached rooms are not owned by RoomHost while another room is active.
	for room in cached_rooms:
		if room != null and room.get_parent() == null:
			room.free()


func _process(_delta: float) -> void:
	var target: int = nearby_exit_target()
	exit_backdrop.visible = target >= 0
	exit_prompt.visible = target >= 0
	if target >= 0:
		exit_prompt.text = "E  Preview %s  →" % NAMES[target] if target > room_index else "←  E  Preview %s" % NAMES[target]


func _input(event: InputEvent) -> void:
	if transition_pending or not event.is_action_pressed("interact"):
		return
	if event is InputEventKey and event.echo:
		return
	var target: int = nearby_exit_target()
	if target < 0:
		return
	transition_pending = true
	get_viewport().set_input_as_handled()
	call_deferred("_finish_transition", target, room_index)


func nearby_exit_target() -> int:
	if active_room == null or transition_pending:
		return -1
	var kath: CharacterBody2D = active_room.get_node("Kath")
	if not kath.controls_enabled:
		return -1
	if room_index > 0 and absf(kath.position.x - PREVIOUS_EXIT_X[room_index]) <= EXIT_RADIUS:
		return room_index - 1
	if room_index < ROOMS.size() - 1 and absf(kath.position.x - NEXT_EXIT_X[room_index]) <= EXIT_RADIUS:
		return room_index + 1
	return -1


func _finish_transition(target: int, source: int) -> void:
	show_room(target, source)
	transition_pending = false


func show_room(index: int, from_index: int) -> void:
	assert(index >= 0 and index < ROOMS.size())
	if active_room != null:
		room_host.remove_child(active_room)
	if cached_rooms[index] == null:
		cached_rooms[index] = ROOMS[index].instantiate()
	active_room = cached_rooms[index]
	room_host.add_child(active_room)
	room_index = index
	var old_hint: CanvasItem = active_room.get_node_or_null("PreviewHint") as CanvasItem
	if old_hint != null:
		old_hint.visible = false
	var old_ui: CanvasItem = active_room.get_node_or_null("HallUI") as CanvasItem
	if old_ui != null:
		old_ui.visible = false
	var kath: CharacterBody2D = active_room.get_node("Kath")
	var spawn_x: float = SPAWN_FROM_PREVIOUS[index] if from_index < index else SPAWN_FROM_NEXT[index]
	kath.position = Vector2(spawn_x, kath.floor_height_at(spawn_x))
	kath.velocity = Vector2.ZERO
	kath.controls_enabled = true
	var wick: Node2D = active_room.get_node("Wick")
	wick.reaction_time = 0.0
	wick.position = kath.position + Vector2(-90, -225)
	room_title.text = "CHAPTER I · ART TOUR       %d / %d       %s" % [index + 1, ROOMS.size(), NAMES[index]]
	controls_hint.text = HINTS[index]
	exit_backdrop.visible = false
	exit_prompt.visible = false
