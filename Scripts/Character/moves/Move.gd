extends Node
class_name Move

# all move flags and variables here
var player: CharacterBody3D
var animation: String

# Shared physics constants/variables used by move states.
const JUMP_VELOCITY: float = 4.5
var gravity: float = 9.8
const TRACKING_ANGULAR_SPEED: float = 12.0
const COMBAT_FACING_SPEED: float = 12.0

static var moves_priority: Dictionary = {
	"idle": 1,
	"walk": 2,
	"run": 3,
	"jump": 20, # be generous to not edit this too much when sprint, dash, couch etc are added.
}

static func moves_priority_sort(a: String, b: String):
	if moves_priority[a] > moves_priority[b]:
		return true
	else:
		return false


func check_relevance(_input: InputPackage) -> String:
	print_debug("error, implement the check_relevance function in your state")
	return "error, implement the check_relevance function in your state"

func update(_input: InputPackage, _delta: float):
	player.velocity.x = 0.0
	player.velocity.z = 0.0

func on_enter_state():
	pass

func on_exit_state():
	pass

func get_camera_basis() -> Basis:
	var rig := get_tree().get_first_node_in_group("camera_rig")
	if rig == null:
		return player.global_transform.basis
	var pivot := rig.get_node_or_null("camera_pivot") as Node3D
	if pivot == null:
		return player.global_transform.basis
	return pivot.global_transform.basis

func process_input_vector(input: InputPackage, delta: float, speed: float, _turn_speed: float) -> void:
	if input.input_direction == Vector2.ZERO:
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		if not player.is_on_floor():
			player.velocity.y -= gravity * delta
		return

	var camera_basis := get_camera_basis()
	var direction := camera_basis * Vector3(input.input_direction.x, 0, input.input_direction.y)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()

	var current_basis := player.global_transform.basis
	player.look_at(player.global_position - direction, Vector3.UP)
	var target_basis := player.global_transform.basis
	player.global_transform.basis = current_basis.slerp(
		target_basis,
		clampf(delta * TRACKING_ANGULAR_SPEED, 0.0, 1.0)
	)

	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	if not player.is_on_floor():
		player.velocity.y -= gravity * delta

func process_combat_input(input: InputPackage, delta: float, speed: float) -> void:
	var facing_target := get_facing_target()
	if facing_target.is_finite():
		_face_world_position(facing_target, delta)

	if input.input_direction != Vector2.ZERO:
		var camera_basis := get_camera_basis()
		var strafe := camera_basis * Vector3(input.input_direction.x, 0, input.input_direction.y)
		strafe.y = 0.0
		strafe = strafe.normalized()
		player.velocity.x = strafe.x * speed
		player.velocity.z = strafe.z * speed
	else:
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	if not player.is_on_floor():
		player.velocity.y -= gravity * delta

func _face_world_position(world_position: Vector3, delta: float) -> void:
	var dir := world_position - player.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var target_angle := atan2(dir.x, dir.z)
	player.rotation.y = lerp_angle(
		player.rotation.y,
		target_angle,
		clampf(delta * COMBAT_FACING_SPEED, 0.0, 1.0)
	)

func get_facing_target() -> Vector3:
	if _is_player_controlled():
		return _get_look_target_position()
	var target := get_ai_target()
	if target != null and is_instance_valid(target):
		return target.global_position
	return Vector3.INF

func get_ai_target() -> Node3D:
	return null

func _is_player_controlled() -> bool:
	var party := Gamemanager.local_party
	if party == null:
		return false
	var member := Gamemanager.get_party_member(party, player)
	if member == null:
		return false
	return member.controller_peer_id == Gamemanager.local_peer_id

func _get_look_target_position() -> Vector3:
	var lt := player.get_node_or_null("look_target") as Node3D
	if lt == null:
		return Vector3.INF
	return lt.global_position
