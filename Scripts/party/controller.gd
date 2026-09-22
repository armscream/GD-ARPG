extends CharacterBody3D

const JUMP_VELOCITY := 4.5

@onready var input_gatherer: InputGatherer = $Input
@onready var model = $Model as PlayerModel

@export var start_as_player: bool = false

# ================================================================
# PHYSICS
# ================================================================
func _physics_process(delta: float) -> void:
	var input = input_gatherer.gather_input() # Player input
	model.update(input, delta)
	move_and_slide()
