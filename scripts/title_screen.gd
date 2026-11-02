extends Node2D
## Single-slot entry point for a fresh playthrough or a saved checkpoint.

@onready var state: Node = get_node("/root/PrologueState")
@onready var new_game: Label = $Menu/NewGame
@onready var continue_game: Label = $Menu/ContinueGame
@onready var help: Label = $Menu/Help

var selection := 0
var confirming_new_game := false
var has_save := false


func _ready() -> void:
	has_save = state.has_checkpoint()
	selection = 1 if has_save else 0
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_cancel") and confirming_new_game:
		confirming_new_game = false
		get_viewport().set_input_as_handled()
		_refresh()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		if not confirming_new_game and has_save:
			selection = 1 - selection
		_refresh()
	elif event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		if selection == 1 and has_save and not confirming_new_game:
			if not state.resume_checkpoint():
				has_save = false
				selection = 0
				_refresh()
		elif has_save and not confirming_new_game:
			confirming_new_game = true
			_refresh()
		else:
			state.start_new_game()
	elif event.keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		get_tree().quit()


func _refresh() -> void:
	new_game.text = ("›  " if selection == 0 else "   ") + "NEW GAME"
	continue_game.text = ("›  " if selection == 1 else "   ") + "CONTINUE"
	continue_game.modulate = Color.WHITE if has_save else Color(0.53, 0.55, 0.62)
	if confirming_new_game:
		help.text = "Replace the current journey?\nENTER CONFIRM  ·  ESC BACK"
	elif has_save:
		help.text = "↑ / ↓ SELECT  ·  ENTER START\nContinue resumes at a safe room entrance."
	else:
		help.text = "ENTER START\nProgress saves at safe checkpoints."
