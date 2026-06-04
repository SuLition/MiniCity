class_name ResourceManager
extends Node

@export var world_state_path: NodePath

var initial_resources: Dictionary = {
	&"wood": 30,
	&"stone": 20,
	&"food": 20,
	&"water": 20,
	&"cloth_leather": 5,
}

var world_state: WorldState


func _ready() -> void:
	world_state = get_node(world_state_path) as WorldState
	if world_state == null:
		push_error("ResourceManager requires a valid WorldState.")
		return

	world_state.set_resources(initial_resources)
