extends Move
class_name Walk

const SPEED = 3.0
const TURN_SPEED = 1.5

func _ready():
	animation = "Humanoid/Walk"

func check_relevance(input: InputPackage):
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "walk":
		return "okay"
	return input.actions[0]

func update(input: InputPackage, delta: float):
	if input.combat_mode:
		process_combat_input(input, delta, SPEED)
	else:
		process_input_vector(input, delta, SPEED, TURN_SPEED)
