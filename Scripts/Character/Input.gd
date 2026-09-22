extends Node
class_name InputGatherer

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	
	new_input.actions.append("idle")

	new_input.input_direction = Input.get_vector("left", "right", "forward", "backward")
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("walk")
		if Input.is_action_pressed("run"):		# run is hidden here to avoid standing in place and sprinting
			new_input.actions.append("run")
			

	if Input.is_action_pressed("jump"):
		new_input.actions.append("jump")


	#if Input.is_action_just_pressed("heavy_attack"):
		#new_input.combat_actions.append("heavy_attack_pressed")
	
	#print(new_input.input_direction)
	return new_input
