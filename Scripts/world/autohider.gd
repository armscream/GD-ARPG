extends CSGBox3D


var layer: int = 1

@export var trigger_margin: float = 0.05
@export var camera_corner_distance: float = 0.1


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

	if box_intersects_camera_pyramid(
		player_pos,
		camera
	):
		set_to_foreground()
	else:
		set_to_background()


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


func box_intersects_camera_pyramid(
	player_pos: Vector3,
	camera: Camera3D
) -> bool:

	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return false


	# ---------------------------------------------------------
	# CAMERA
	# ---------------------------------------------------------

	var camera_pos: Vector3 = camera.global_position

	var camera_forward: Vector3 = (
		-camera.global_transform.basis.z.normalized()
	)


	# ---------------------------------------------------------
	# GET THE FOUR CORNERS OF THE CAMERA VIEW
	# ---------------------------------------------------------

	var screen_corners: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(viewport_size.x, 0.0),
		Vector2(viewport_size.x, viewport_size.y),
		Vector2(0.0, viewport_size.y)
	]


	# Put the camera corners slightly in front of the camera.
	var corner_plane_pos: Vector3 = (
		camera_pos
		+ camera_forward * camera_corner_distance
	)

	var corner_plane := Plane(
		camera_forward,
		-camera_forward.dot(corner_plane_pos)
	)


	var camera_corners: Array[Vector3] = []


	for screen_corner in screen_corners:

		var ray_origin: Vector3 = (
			camera.project_ray_origin(screen_corner)
		)

		var ray_direction: Vector3 = (
			camera.project_ray_normal(screen_corner).normalized()
		)


		var denominator: float = (
			corner_plane.normal.dot(ray_direction)
		)


		if abs(denominator) < 0.00001:
			return false


		var t: float = -(
			corner_plane.normal.dot(ray_origin)
			+ corner_plane.d
		) / denominator


		if t < 0.0:
			return false


		camera_corners.append(
			ray_origin + ray_direction * t
		)


	# ---------------------------------------------------------
	# BUILD THE CAMERA PYRAMID
	# ---------------------------------------------------------

	var pyramid: Array[Vector3] = [
		player_pos,
		camera_corners[0],
		camera_corners[1],
		camera_corners[2],
		camera_corners[3]
	]


	# ---------------------------------------------------------
	# PYRAMID EDGES
	# ---------------------------------------------------------

	var pyramid_edges: Array[Vector3] = [

		# Four edges from player to camera corners.
		pyramid[1] - pyramid[0],
		pyramid[2] - pyramid[0],
		pyramid[3] - pyramid[0],
		pyramid[4] - pyramid[0],

		# Four edges around camera rectangle.
		pyramid[2] - pyramid[1],
		pyramid[3] - pyramid[2],
		pyramid[4] - pyramid[3],
		pyramid[1] - pyramid[4]
	]


	# ---------------------------------------------------------
	# GET THE CSG BOX AS AN OBB
	# ---------------------------------------------------------

	var local_box: AABB = get_aabb()

	var local_center: Vector3 = (
		local_box.get_center()
	)

	var local_half_size: Vector3 = (
		local_box.size * 0.5
	)


	# Transform local center into world space.
	var box_center: Vector3 = (
		global_transform * local_center
	)


	var box_basis: Basis = global_transform.basis


	# Three local axes of the CSG box.
	var box_axes: Array[Vector3] = [
		box_basis.x.normalized(),
		box_basis.y.normalized(),
		box_basis.z.normalized()
	]


	# Account for scaling.
	var box_half_extents: Vector3 = Vector3(
		local_half_size.x * box_basis.x.length(),
		local_half_size.y * box_basis.y.length(),
		local_half_size.z * box_basis.z.length()
	)


	# ---------------------------------------------------------
	# PYRAMID FACES
	# ---------------------------------------------------------

	var face_indices: Array = [

		# Four triangular side faces.
		[0, 1, 2],
		[0, 2, 3],
		[0, 3, 4],
		[0, 4, 1],

		# Camera rectangle.
		[1, 4, 3],
		[1, 3, 2]
	]


	# ---------------------------------------------------------
	# SAT TEST
	#
	# Test normals of every pyramid face.
	# ---------------------------------------------------------

	for face in face_indices:

		var a: Vector3 = pyramid[face[0]]
		var b: Vector3 = pyramid[face[1]]
		var c: Vector3 = pyramid[face[2]]


		var axis: Vector3 = (
			(b - a).cross(c - a)
		)


		if axis.length_squared() > 0.000001:

			if obb_separates_from_pyramid(
				box_center,
				box_axes,
				box_half_extents,
				pyramid,
				axis
			):
				return false


	# ---------------------------------------------------------
	# TEST THREE AXES OF THE BOX
	# ---------------------------------------------------------

	for axis in box_axes:

		if obb_separates_from_pyramid(
			box_center,
			box_axes,
			box_half_extents,
			pyramid,
			axis
		):
			return false


	# ---------------------------------------------------------
	# TEST CROSS PRODUCTS
	#
	# Pyramid edges × box edges.
	# ---------------------------------------------------------

	for edge in pyramid_edges:

		for box_axis in box_axes:

			var axis: Vector3 = (
				edge.cross(box_axis)
			)


			if axis.length_squared() < 0.000001:
				continue


			if obb_separates_from_pyramid(
				box_center,
				box_axes,
				box_half_extents,
				pyramid,
				axis
			):
				return false


	# ---------------------------------------------------------
	# NO SEPARATING AXIS
	#
	# The CSG box intersects the camera pyramid.
	# ---------------------------------------------------------

	return true


func obb_separates_from_pyramid(
	box_center: Vector3,
	box_axes: Array[Vector3],
	box_half_extents: Vector3,
	pyramid: Array[Vector3],
	axis: Vector3
) -> bool:

	var normalized_axis: Vector3 = (
		axis.normalized()
	)


	# ---------------------------------------------------------
	# PROJECT PYRAMID
	# ---------------------------------------------------------

	var pyramid_min: float = INF
	var pyramid_max: float = -INF


	for point in pyramid:

		var projection: float = (
			point.dot(normalized_axis)
		)

		pyramid_min = minf(
			pyramid_min,
			projection
		)

		pyramid_max = maxf(
			pyramid_max,
			projection
		)


	# ---------------------------------------------------------
	# PROJECT OBB
	# ---------------------------------------------------------

	var box_center_projection: float = (
		box_center.dot(normalized_axis)
	)


	var box_radius: float = (
		abs(
			box_axes[0].dot(normalized_axis)
		) * box_half_extents.x

		+ abs(
			box_axes[1].dot(normalized_axis)
		) * box_half_extents.y

		+ abs(
			box_axes[2].dot(normalized_axis)
		) * box_half_extents.z
	)


	var box_min: float = (
		box_center_projection
		- box_radius
	)

	var box_max: float = (
		box_center_projection
		+ box_radius
	)


	# ---------------------------------------------------------
	# MARGIN
	# ---------------------------------------------------------

	pyramid_min -= trigger_margin
	pyramid_max += trigger_margin


	# ---------------------------------------------------------
	# SEPARATING AXIS
	# ---------------------------------------------------------

	if box_max < pyramid_min:
		return true

	if box_min > pyramid_max:
		return true

	return false
