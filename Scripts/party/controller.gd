# controller.gd
extends CharacterBody3D

const JUMP_VELOCITY := 4.5

@onready var input_gatherer: InputGatherer = $Input
@onready var model = $Model as PlayerModel
@onready var visuals: Node3D = $Visuals
@onready var look_target: Node3D = $look_target

@export var start_as_player: bool = false
var is_locally_controlled: bool = false

func _ready() -> void:
	visuals.accept_skeleton(model.skeleton)
	_register_with_game_manager()

# ================================================================
# PHYSICS
# ================================================================
func _physics_process(delta: float) -> void:
	if is_locally_controlled:
		var input = input_gatherer.gather_input() # Player input
		model.update(input, delta)
	move_and_slide()


# GAME MANAGER / PARTY
func _register_with_game_manager() -> void:
	if start_as_player:
		Gamemanager.register_initial_player(self)
	else:
		Gamemanager.register_ai_character(self)

func set_controller_peer(peer_id: int) -> void:
	is_locally_controlled = peer_id == Gamemanager.local_peer_id
