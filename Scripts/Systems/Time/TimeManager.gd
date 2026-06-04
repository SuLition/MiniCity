extends Node

@export var seconds_per_day: float = 24.0
@export var start_hour: float = 12.0

var current_hour: float = 12.0
var current_phase: StringName = WorldState.PHASE_DAY


func _ready() -> void:
	current_hour = fposmod(start_hour, 24.0)
	current_phase = get_phase_for_hour(current_hour)
	WorldState.set_time(WorldState.day, current_hour, current_phase)


func _process(delta: float) -> void:
	if seconds_per_day <= 0.0:
		return

	var previous_phase := current_phase
	current_hour = fposmod(current_hour + (24.0 * delta / seconds_per_day), 24.0)
	current_phase = get_phase_for_hour(current_hour)

	if previous_phase == WorldState.PHASE_NIGHT and current_phase == WorldState.PHASE_DAWN:
		WorldState.set_time(WorldState.day + 1, current_hour, current_phase)
		return

	WorldState.set_time(WorldState.day, current_hour, current_phase)


func get_phase_for_hour(value: float) -> StringName:
	if value >= 5.0 and value < 6.0:
		return WorldState.PHASE_DAWN
	if value >= 6.0 and value < 18.0:
		return WorldState.PHASE_DAY
	return WorldState.PHASE_NIGHT
