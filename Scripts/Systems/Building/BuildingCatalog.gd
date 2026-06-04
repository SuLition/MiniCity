class_name BuildingCatalog
extends Node

signal selected_definition_changed(definition: BuildingDefinition)

@export var definitions: Array[BuildingDefinition] = []
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


func select_definition_by_id(building_id: StringName) -> bool:
	var valid_definitions := get_valid_definitions()

	for index in range(valid_definitions.size()):
		if valid_definitions[index].building_id == building_id:
			selected_index = index
			selected_definition_changed.emit(valid_definitions[index])
			return true

	return false


func get_valid_definitions() -> Array[BuildingDefinition]:
	var valid_definitions: Array[BuildingDefinition] = []
	for definition in definitions:
		if definition != null and definition.is_valid():
			valid_definitions.append(definition)
	return valid_definitions
