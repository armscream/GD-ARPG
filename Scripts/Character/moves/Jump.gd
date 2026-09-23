extends Move
class_name Jump

func _ready():
	animation = "Humanoid/Jump"

func check_relevance(input) -> String:
	if player.is_on_floor():
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	return "okay"


func update(_input, delta):
	player.velocity.y -= gravity * delta
	
func on_enter_state():
	player.velocity.y += JUMP_VELOCITY
