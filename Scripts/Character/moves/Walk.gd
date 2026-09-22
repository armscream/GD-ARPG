extends Move
class_name Walk

const SPEED = 3.0

func check_relevance(input) -> String:
	if input.actions.has("jump") and player.is_on_floor:
		return "jump"
	if input.input_direction == Vector2.ZERO:
		return "idle"
	return "okay"

func update(input : InputPackage, delta : float):
	player.velocity = velocity_by_input(input, delta)
	player.move_and_slide()

func velocity_by_input(input : InputPackage, delta : float) -> Vector3:
	var new_velocity = player.velocity
	
	var direction = (player.transform.basis * Vector3(input.input_direction.x, 0, input.input_direction.y)).normalized()
	new_velocity.x = direction.x * SPEED
	new_velocity.z = direction.z * SPEED
	
	if input.is_jumping and player.is_on_floor():
		new_velocity.y += JUMP_VELOCITY
		
	if not player.is_on_floor():
		new_velocity.y -= gravity * delta
	return new_velocity
	
