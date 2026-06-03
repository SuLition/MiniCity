class_name BuildingCatalog
extends Node

@export var definitions: Array[Resource] = []
@export var selected_index: int = 0

func get_selected_definition() -> BuildingDefinition:
	var valid_definitions := get_valid_definitions()
	if valid_definitions.is_empty():
		return null

	var index := selected_index
	if index < 0:
		index = 0
	elif index >= valid_definitions.size():
		index = valid_definitions.size() - 1

	return valid_definitions[index]


func get_definition_by_id(building_id: StringName) -> BuildingDefinition:
	for definition in get_valid_definitions():
		if definition.building_id == building_id:
			return definition

	return null


func get_valid_definitions() -> Array[BuildingDefinition]:
	var valid_definitions: Array[BuildingDefinition] = []

	for resource in definitions:
		var definition := resource as BuildingDefinition
		if definition != null and definition.is_valid():
			valid_definitions.append(definition)

	return valid_definitions
