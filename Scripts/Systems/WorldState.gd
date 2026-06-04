class_name WorldState
extends Node

signal resources_changed(resources: Dictionary)
signal time_changed(day: int, hour: float, phase: StringName)

const PHASE_DAWN: StringName = &"dawn"
const PHASE_DAY: StringName = &"day"
const PHASE_NIGHT: StringName = &"night"

var resources: Dictionary = {}
var day: int = 1
var hour: float = 12.0
var phase: StringName = PHASE_DAY


func set_resources(new_resources: Dictionary) -> void:
	resources = new_resources.duplicate(true)
	resources_changed.emit(get_resources_snapshot())


func set_resource_amount(resource_id: StringName, amount: int) -> void:
	resources[resource_id] = amount
	resources_changed.emit(get_resources_snapshot())


func get_resource_amount(resource_id: StringName) -> int:
	return int(resources.get(resource_id, 0))


func get_resources_snapshot() -> Dictionary:
	return resources.duplicate(true)


func set_time(new_day: int, new_hour: float, new_phase: StringName) -> void:
	day = max(1, new_day)
	hour = fposmod(new_hour, 24.0)
	phase = new_phase
	time_changed.emit(day, hour, phase)


func advance_day() -> void:
	day += 1
	time_changed.emit(day, hour, phase)
