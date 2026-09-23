extends Move
class_name Idle

func _ready():
	animation = "Humanoid/Idle"
	
func check_relevance(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	return input.actions[0]
