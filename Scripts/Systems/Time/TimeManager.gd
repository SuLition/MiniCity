class_name TimeManager
extends Node

@export var world_state_path: NodePath
@export var seconds_per_day: float = 24.0
@export var start_hour: float = 12.0

var world_state: WorldState
var current_hour: float = 12.0
var current_phase: StringName = WorldState.PHASE_DAY


func _ready() -> void:
	world_state = get_node(world_state_path) as WorldState
	if world_state == null:
		push_error("TimeManager requires a valid WorldState.")
		set_process(false)
		return

	current_hour = fposmod(start_hour, 24.0)
	current_phase = get_phase_for_hour(current_hour)
	world_state.set_time(world_state.day, current_hour, current_phase)


func _process(delta: float) -> void:
	if seconds_per_day <= 0.0:
		return

	var previous_phase: StringName = current_phase
	current_hour = fposmod(current_hour + (24.0 * delta / seconds_per_day), 24.0)
	current_phase = get_phase_for_hour(current_hour)

	if previous_phase == WorldState.PHASE_NIGHT and current_phase == WorldState.PHASE_DAWN:
		world_state.set_time(world_state.day + 1, current_hour, current_phase)
		return

	world_state.set_time(world_state.day, current_hour, current_phase)


func get_phase_for_hour(value: float) -> StringName:
	if value >= 5.0 and value < 6.0:
		return WorldState.PHASE_DAWN
	if value >= 6.0 and value < 18.0:
		return WorldState.PHASE_DAY
	return WorldState.PHASE_NIGHT
