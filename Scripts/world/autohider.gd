# Autohider.gd
extends CSGBox3D

var layer: int = 1
var _is_occluding: bool = false


func _process(_delta: float) -> void:
	var camera_rig := \
		get_tree().get_first_node_in_group("camera_rig")

	if camera_rig == null:
		return

	var player: Node = \
		camera_rig.get_controlled_character()

	if player == null:
		return

	var camera: Camera3D = \
		Gamemanager.camera

	if camera == null:
		return

	var player_pos: Vector3 = \
		player.global_position

	if box_occludes_line_of_sight_to_player(
		player_pos,
		camera
	):
		set_to_foreground()

		if not _is_occluding:
			_is_occluding = true
			camera_rig.add_foreground_occluder()
	else:
		set_to_background()

		if _is_occluding:
			_is_occluding = false
			camera_rig.remove_foreground_occluder()


func _exit_tree() -> void:
	if not _is_occluding:
		return

	_is_occluding = false

	var tree := get_tree()
	if tree == null:
		return

	var camera_rig := tree.get_first_node_in_group("camera_rig")
	if camera_rig == null:
		return

	if is_instance_valid(camera_rig):
		camera_rig.remove_foreground_occluder()


func set_to_foreground() -> void:
	if layer == 2:
		return

	layer = 2

	set_layer_mask_value(1, false)
	set_layer_mask_value(2, true)


func set_to_background() -> void:
	if layer == 1:
		return

	layer = 1

	set_layer_mask_value(1, true)
	set_layer_mask_value(2, false)


func box_occludes_line_of_sight_to_player(
	player_pos: Vector3,
	camera: Camera3D
) -> bool:
	var camera_pos: Vector3 = camera.global_position
	var world_to_local: Transform3D = global_transform.affine_inverse()

	var local_camera: Vector3 = world_to_local * camera_pos
	var local_player: Vector3 = world_to_local * player_pos
	var local_dir: Vector3 = local_player - local_camera

	var local_ray_length: float = local_dir.length()

	if local_ray_length < 0.001:
		return false


	var local_unit_dir: Vector3 = local_dir / local_ray_length

	var box: AABB = get_aabb()
	var box_min: Vector3 = box.position
	var box_max: Vector3 = box.position + box.size


	var t_min: float = 0.0
	var t_max: float = local_ray_length


	for i in range(3):
		var rd: float = local_unit_dir[i]
		var ro: float = local_camera[i]

		if abs(rd) < 0.000001:
			if ro < box_min[i] or ro > box_max[i]:
				return false
		else:
			var inv_d: float = 1.0 / rd
			var t1: float = (box_min[i] - ro) * inv_d
			var t2: float = (box_max[i] - ro) * inv_d
			var t_near: float = min(t1, t2)
			var t_far: float = max(t1, t2)
			t_min = max(t_min, t_near)
			t_max = min(t_max, t_far)

			if t_min > t_max:
				return false


	return t_max >= 0.0 and t_min <= local_ray_length
