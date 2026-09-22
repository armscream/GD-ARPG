extends Node
class_name Move


# all move flags and variables here
var player : CharacterBody3D

# Shared physics constants/variables used by move states.
const JUMP_VELOCITY : float = 4.5
var gravity : float = 9.8

static var moves_priority : Dictionary = {
	"idle" : 1,
	"walk" : 2,
	"run" : 3,
	"jump" : 20, #be generous to not edit this too much when sprint, dash, couch etc are added.
}

static func moves_priority_sort(a : String, b : String):
	if moves_priority[a] > moves_priority[b]:
		return true
	else:
		return false


func check_relevance(input : InputPackage) -> String:
	print_debug("error, implement the check_relevance function in your state")
	return "error, implement the check_relevance function in your state"

func update(input : InputPackage, delta : float):
	pass

func on_enter_state():
	pass

func on_exit_state():
	pass
