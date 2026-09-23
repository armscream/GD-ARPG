extends Node
class_name InputGatherer

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()

		
	new_input.combat_mode = Input.is_action_pressed("combat_mode")

	new_input.input_direction = Input.get_vector("left", "right", "forward", "backward")
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("walk")
		if Input.is_action_pressed("run"): # run is hidden here to avoid standing in place and sprinting
			new_input.actions.append("run")

	if Input.is_action_pressed("jump"):
		if new_input.actions.has("sprint"):
			new_input.actions.append("sprint_jump")
		else:
			new_input.actions.append("walk_jump")

	if new_input.actions.is_empty():
		new_input.actions.append("idle")


	#if Input.is_action_just_pressed("heavy_attack"):
		#new_input.combat_actions.append("heavy_attack_pressed")

	#print(new_input.input_direction)
	return new_input
