extends Node2D
## Standalone art/legibility inspection; it never advances Chapter I or changes PrologueState.

const FLOOR_Y := 820.0
const WALK_MIN_X := 155.0
const WALK_MAX_X := 1530.0
const RECORDS_X := 445.0
const TELESCOPE_X := 810.0
const INSPECT_DISTANCE := 155.0

const DOCUMENTS := [
	{
		"title": "WORK RECORD",
		"body": "Positioning trial 18\n\nAfter the drive stopped, the load kept moving.\n\nEarlier estimate struck through. Retain measured result.\n\nSigned: Control team"
	},
	{
		"title": "FIELD COMPARISON",
		"body": "Copy for the Floating Isles station\n\nCompare the behavior of empty and loaded hulls. Keep the original observations with the revised explanation."
	},
	{
		"title": "WITHDRAWN",
		"body": "An earlier explanation did not fit the latest trials.\n\nDo not discard the readings. Mark the conditions, then repeat the test."
	}
]

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var telescope_pivot: Node2D = $TelescopePivot
@onready var drawer: Sprite2D = $ArchiveDrawer
@onready var document_modal: Node2D = $DocumentModal
@onready var document_title: Label = $DocumentModal/DocumentTitle
@onready var document_body: Label = $DocumentModal/DocumentBody

var drawer_open := false
var document_index := 0
var telescope_angle_degrees := 0.0


func _ready() -> void:
	# This room is in the rotating wing; the preview depicts the post-restoration visit.
	# Never set the shared pose here: official access belongs to a later gameplay stage.
	set_telescope_angle(0.0)
	set_drawer_open(false)
	close_document()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if document_modal.visible:
		match event.physical_keycode:
			KEY_1, KEY_2, KEY_3:
				show_document(event.physical_keycode - KEY_1)
			KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER:
				close_document()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_ESCAPE:
		set_drawer_open(false)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		inspect_nearest()
		get_viewport().set_input_as_handled()


func inspect_nearest() -> void:
	var records_distance: float = absf(kath.position.x - RECORDS_X)
	var telescope_distance: float = absf(kath.position.x - TELESCOPE_X)
	if records_distance <= INSPECT_DISTANCE and records_distance <= telescope_distance:
		if not drawer_open:
			set_drawer_open(true)
			wick.react_to(RECORDS_X, 505.0)
		else:
			show_document(0)
	elif telescope_distance <= INSPECT_DISTANCE:
		set_telescope_angle(-6.0 if is_zero_approx(telescope_angle_degrees) else 0.0)
		wick.react_to(TELESCOPE_X, 350.0)


func set_drawer_open(open: bool) -> void:
	drawer_open = open
	drawer.visible = open


func set_telescope_angle(angle: float) -> void:
	telescope_angle_degrees = angle
	telescope_pivot.rotation_degrees = angle


func show_document(index: int) -> void:
	assert(index >= 0 and index < DOCUMENTS.size())
	set_drawer_open(true)
	document_index = index
	document_title.text = DOCUMENTS[index]["title"]
	document_body.text = DOCUMENTS[index]["body"]
	document_modal.visible = true
	kath.controls_enabled = false


func close_document() -> void:
	document_modal.visible = false
	kath.controls_enabled = true
