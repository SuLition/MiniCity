class_name HUDController
extends CanvasLayer

@export var world_state_path: NodePath

@onready var day_label: Label = %DayLabel
@onready var time_label: Label = %TimeLabel
@onready var phase_label: Label = %PhaseLabel
@onready var wood_label: Label = %WoodLabel
@onready var stone_label: Label = %StoneLabel
@onready var food_label: Label = %FoodLabel
@onready var water_label: Label = %WaterLabel
@onready var cloth_leather_label: Label = %ClothLeatherLabel

var world_state: WorldState


func _ready() -> void:
	world_state = get_node(world_state_path) as WorldState
	if world_state == null:
		push_error("HUDController requires a valid WorldState.")
		return

	world_state.resources_changed.connect(update_resources)
	world_state.time_changed.connect(update_time)
	update_resources(world_state.get_resources_snapshot())
	update_time(world_state.day, world_state.hour, world_state.phase)


func update_resources(resources: Dictionary) -> void:
	wood_label.text = "\u6728\u6750 %d" % int(resources.get(&"wood", 0))
	stone_label.text = "\u77f3\u5934 %d" % int(resources.get(&"stone", 0))
	food_label.text = "\u98df\u7269 %d" % int(resources.get(&"food", 0))
	water_label.text = "\u6c34 %d" % int(resources.get(&"water", 0))
	cloth_leather_label.text = "\u5e03\u6599/\u76ae\u9769 %d" % int(resources.get(&"cloth_leather", 0))


func update_time(day: int, hour: float, phase: StringName) -> void:
	day_label.text = "\u7b2c %d \u5929" % day
	time_label.text = "%02d:%02d" % [int(hour), int(fposmod(hour, 1.0) * 60.0)]
	phase_label.text = get_phase_text(phase)


func get_phase_text(phase: StringName) -> String:
	match phase:
		WorldState.PHASE_DAWN:
			return "\u6e05\u6668"
		WorldState.PHASE_DAY:
			return "\u767d\u5929"
		WorldState.PHASE_NIGHT:
			return "\u591c\u665a"
		_:
			return "\u672a\u77e5"
