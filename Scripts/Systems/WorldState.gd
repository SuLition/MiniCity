extends Node

signal resources_changed(resources: Dictionary)
signal time_changed(day: int, hour: float, phase: StringName)
signal phase_changed(new_phase: StringName, old_phase: StringName)
signal night_started(day: int)
signal dawn_started(day: int)
signal day_started(day: int)

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
	var old_phase := phase
	day = max(1, new_day)
	hour = fposmod(new_hour, 24.0)
	phase = new_phase
	time_changed.emit(day, hour, phase)

	if old_phase != new_phase:
		phase_changed.emit(new_phase, old_phase)
		match new_phase:
			PHASE_NIGHT:
				night_started.emit(day)
			PHASE_DAWN:
				dawn_started.emit(day)
			PHASE_DAY:
				day_started.emit(day)


func advance_day() -> void:
	day += 1
	time_changed.emit(day, hour, phase)
