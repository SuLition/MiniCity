extends Node

@export var initial_resources: Dictionary = {
	&"wood": 30,
	&"stone": 20,
	&"food": 20,
	&"water": 20,
	&"cloth_leather": 5,
}


func _ready() -> void:
	WorldState.set_resources(initial_resources)


func can_afford(cost: Dictionary) -> bool:
	for resource_id in cost:
		if WorldState.get_resource_amount(resource_id) < int(cost[resource_id]):
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for resource_id in cost:
		WorldState.set_resource_amount(
			resource_id,
			WorldState.get_resource_amount(resource_id) - int(cost[resource_id])
		)
	return true


func add(resources_to_add: Dictionary) -> void:
	for resource_id in resources_to_add:
		WorldState.set_resource_amount(
			resource_id,
			WorldState.get_resource_amount(resource_id) + int(resources_to_add[resource_id])
		)
