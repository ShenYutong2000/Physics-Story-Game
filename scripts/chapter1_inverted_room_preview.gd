extends Node2D
## Phase 2 art preview only. The official route and PrologueState stay untouched.

@onready var falling_water: Sprite2D = $FallingWater

var water_time: float = 0.0


func _process(delta: float) -> void:
	# A small opacity pulse keeps the detachable drip readable without moving its
	# source or splash endpoints. Gravity is always toward positive screen Y.
	water_time += delta
	falling_water.modulate.a = 0.74 + 0.06 * sin(water_time * 3.0)
