extends Node3D


# ================================================================
# CAMERA NODES
# ================================================================

@onready var camera_pivot: Node3D = $camera_pivot

@onready var foreground_viewport: SubViewport = \
	$base_camera/foreground_viewport_container/foreground_viewport

@onready var background_viewport: SubViewport = \
	$base_camera/background_viewport_container/background_viewport

@onready var foreground_camera: Camera3D = \
	$base_camera/foreground_viewport_container/foreground_viewport/foreground_camera

@onready var background_camera: Camera3D = \
	$base_camera/background_viewport_container/background_viewport/background_camera

@onready var foreground_viewport_container: SubViewportContainer = \
	$base_camera/foreground_viewport_container


# ================================================================
# PLAYER / PARTY
# ================================================================

var current_party: Gamemanager.Party = null
var player: Node = null


# ================================================================
# ORBIT
# ================================================================

var is_orbiting := false

var yaw: float = 0.0
var pitch: float = 0.0

@export var sensitivity: float = 0.15
@export var camera_distance: float = 5.0
@export var camera_target_height: float = 1.5


# ================================================================
# CAMERA SWITCHING
# ================================================================

var is_switching := false
var switch_elapsed: float = 0.0

@export var switch_duration: float = 0.5

var switch_start_transform := Transform3D.IDENTITY
var switch_target_transform := Transform3D.IDENTITY

var switch_target_character: Node = null


# ================================================================
# FOREGROUND SHADER
# ================================================================

@export var foreground_fade_time: float = 0.1

var foreground_shader_material: ShaderMaterial
var foreground_fade_tween: Tween
var foreground_occluder_count: int = 0


# ================================================================
# READY
# ================================================================

func _ready() -> void:
	add_to_group("camera_rig")

	resize()

	Gamemanager.set_camera(foreground_camera)

	setup_foreground_shader()

	current_party = Gamemanager.get_or_create_local_party()

	update_controlled_character()


# ================================================================
# PARTY
# ================================================================

func set_party(party: Gamemanager.Party) -> void:
	current_party = party
	update_controlled_character()


func get_controlled_character() -> Node:
	if current_party == null:
		return null

	var member := \
		Gamemanager.get_local_controlled_character(current_party)

	if member == null:
		return null

	if member.character == null:
		return null

	return member.character


# ================================================================
# CHARACTER CAMERA POINT
# ================================================================

func _get_character_camera_point(character: Node) -> Node3D:
	if character == null:
		return null

	if not character.has_node("camera_point"):
		push_warning(
			"Character does not have a camera_point."
		)
		return null

	return character.get_node("camera_point") as Node3D


# ================================================================
# CONTROLLED CHARACTER
# ================================================================

func update_controlled_character() -> void:
	var new_character := get_controlled_character()

	if new_character == null:
		player = null
		switch_target_character = null
		is_switching = false
		return

	# Already controlling this character.
	if new_character == player:
		return

	# Don't restart the same switch every frame.
	if is_switching and new_character == switch_target_character:
		return

	# ------------------------------------------------------------
	# FIRST CHARACTER
	# ------------------------------------------------------------

	if player == null:
		player = new_character

		adopt_character_camera(new_character)

		return

	# ------------------------------------------------------------
	# SWITCH CHARACTER
	# ------------------------------------------------------------

	switch_to_character(new_character)


# ================================================================
# ADOPT CHARACTER CAMERA
# ================================================================

func adopt_character_camera(character: Node) -> void:
	if character == null:
		return

	var camera_point := \
		_get_character_camera_point(character)

	if camera_point == null:
		return

	# camera_point contains the character's default camera position
	# and orientation.
	#
	# Copy that transform into the CameraRig's camera_pivot.
	camera_pivot.global_transform = \
		camera_point.global_transform

	foreground_camera.global_transform = \
		camera_pivot.global_transform

	background_camera.global_transform = \
		camera_pivot.global_transform

	# Derive orbit angles from the adopted camera position.
	update_angles_from_camera()


# ================================================================
# CALCULATE YAW / PITCH FROM CAMERA
# ================================================================

func update_angles_from_camera() -> void:
	if player == null:
		return

	var orbit_center: Vector3 = \
		player.global_position

	orbit_center.y += camera_target_height

	var offset: Vector3 = \
		camera_pivot.global_position - orbit_center

	if offset.length_squared() <= 0.0001:
		return

	var horizontal_distance := \
		Vector2(offset.x, offset.z).length()

	# Our orbit formula uses:
	#
	# x = sin(yaw) * horizontal_distance
	# z = cos(yaw) * horizontal_distance
	#
	# Therefore:
	yaw = rad_to_deg(
		atan2(
			offset.x,
			offset.z
		)
	)

	pitch = rad_to_deg(
		atan2(
			offset.y,
			horizontal_distance
		)
	)

	pitch = clampf(
		pitch,
		-89.0,
		89.0
	)


# ================================================================
# CAMERA ORBIT
# ================================================================

func update_camera_orbit() -> void:
	if player == null:
		return

	var orbit_center: Vector3 = \
		player.global_position

	orbit_center.y += camera_target_height

	var yaw_radians: float = \
		deg_to_rad(yaw)

	var pitch_radians: float = \
		deg_to_rad(pitch)

	var horizontal_distance: float = \
		cos(pitch_radians) * camera_distance

	var vertical_distance: float = \
		sin(pitch_radians) * camera_distance

	var offset := Vector3(
		sin(yaw_radians) * horizontal_distance,
		vertical_distance,
		cos(yaw_radians) * horizontal_distance
	)

	# camera_pivot belongs to the CameraRig.
	#
	# The PLAYER is the orbit center.
	camera_pivot.global_position = \
		orbit_center + offset

	camera_pivot.look_at(
		orbit_center,
		Vector3.UP
	)

	foreground_camera.global_transform = \
		camera_pivot.global_transform

	background_camera.global_transform = \
		camera_pivot.global_transform


# ================================================================
# SWITCH TO CHARACTER
# ================================================================

func switch_to_character(new_character: Node) -> void:
	if new_character == null:
		return

	if new_character == player:
		return

	var camera_point := \
		_get_character_camera_point(new_character)

	if camera_point == null:
		return

	# ------------------------------------------------------------
	# START
	# ------------------------------------------------------------

	switch_start_transform = \
		foreground_camera.global_transform

	# ------------------------------------------------------------
	# TARGET
	#
	# Use the NEW CHARACTER'S camera_point.
	#
	# This is its default camera position/orientation.
	# ------------------------------------------------------------

	switch_target_transform = \
		camera_point.global_transform

	switch_target_character = new_character

	switch_elapsed = 0.0
	is_switching = true


# ================================================================
# UPDATE CAMERA SWITCH
# ================================================================

func update_camera_switch(delta: float) -> void:
	if switch_target_character == null:
		is_switching = false
		return

	if switch_duration <= 0.0:
		foreground_camera.global_transform = \
			switch_target_transform

		background_camera.global_transform = \
			switch_target_transform

		camera_pivot.global_transform = \
			switch_target_transform

		_finish_character_switch()

		return

	switch_elapsed += delta

	var t: float = \
		switch_elapsed / switch_duration

	t = clampf(
		t,
		0.0,
		1.0
	)

	t = smoothstep(
		0.0,
		1.0,
		t
	)

	var new_position: Vector3 = \
		switch_start_transform.origin.lerp(
			switch_target_transform.origin,
			t
		)

	var new_basis: Basis = \
		switch_start_transform.basis.slerp(
			switch_target_transform.basis,
			t
		)

	var new_transform := Transform3D(
		new_basis,
		new_position
	)

	foreground_camera.global_transform = \
		new_transform

	background_camera.global_transform = \
		new_transform

	camera_pivot.global_transform = \
		new_transform

	if t >= 1.0:
		_finish_character_switch()


# ================================================================
# FINISH SWITCH
# ================================================================

func _finish_character_switch() -> void:
	if switch_target_character == null:
		is_switching = false
		return

	# The new character becomes the orbit center.
	player = switch_target_character

	switch_target_character = null

	is_switching = false
	switch_elapsed = 0.0

	# The camera_pivot is already sitting at the new character's
	# camera_point transform.
	#
	# Convert that position into our orbit angles so the first
	# orbit frame doesn't snap somewhere else.
	update_angles_from_camera()

	# Now normal orbiting can take over.
	update_camera_orbit()


# ================================================================
# PROCESS
# ================================================================

func _process(delta: float) -> void:
	update_controlled_character()

	if player == null:
		return

	if is_switching:
		update_camera_switch(delta)
	else:
		update_camera_orbit()


# ================================================================
# MOUSE ORBIT
# ================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_orbiting = event.pressed

	elif event is InputEventMouseMotion:
		if is_orbiting:
			yaw -= event.relative.x * sensitivity

			pitch += event.relative.y * sensitivity

			pitch = clampf(
				pitch,
				-89.0,
				89.0
			)


# ================================================================
# FOREGROUND SHADER
# ================================================================

func setup_foreground_shader() -> void:
	foreground_shader_material = \
		foreground_viewport_container.material as ShaderMaterial

	if foreground_shader_material == null:
		push_warning(
			"foreground_viewport_container does not have a ShaderMaterial."
		)
		return

	foreground_shader_material.set_shader_parameter(
		"BLEND",
		0.0
	)


func add_foreground_occluder() -> void:
	foreground_occluder_count += 1

	update_foreground_shader()


func remove_foreground_occluder() -> void:
	foreground_occluder_count = maxi(
		foreground_occluder_count - 1,
		0
	)

	update_foreground_shader()


func update_foreground_shader() -> void:
	if foreground_shader_material == null:
		return

	var target: float = 0.0

	if foreground_occluder_count > 0:
		target = 1.0

	fade_foreground_shader(target)


func fade_foreground_shader(target: float) -> void:
	if foreground_shader_material == null:
		return

	if foreground_fade_tween != null:
		foreground_fade_tween.kill()

	var current: float = float(
		foreground_shader_material.get_shader_parameter(
			"BLEND"
		)
	)

	if is_equal_approx(current, target):
		return

	foreground_fade_tween = create_tween()

	foreground_fade_tween.set_trans(
		Tween.TRANS_SINE
	)

	foreground_fade_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	foreground_fade_tween.tween_method(
		set_foreground_blend,
		current,
		target,
		foreground_fade_time
	)


func set_foreground_blend(value: float) -> void:
	if foreground_shader_material == null:
		return

	foreground_shader_material.set_shader_parameter(
		"BLEND",
		value
	)


# ================================================================
# RESIZE
# ================================================================

func resize() -> void:
	background_viewport.size = \
		DisplayServer.window_get_size()

	foreground_viewport.size = \
		DisplayServer.window_get_size()
