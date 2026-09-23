extends Move
class_name Run

const SPEED = 5.0
const TURN_SPEED = 2.5

func _ready():
	animation = "Humanoid/Run"

func check_relevance(input: InputPackage):
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "run":
		return "okay"
	return input.actions[0]

func update(input: InputPackage, delta: float):
	process_input_vector(input, delta, SPEED, TURN_SPEED)
