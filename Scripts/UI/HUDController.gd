class_name HUDController
extends CanvasLayer

@export var catalog: BuildingCatalog
@export var placement_system: BuildingPlacementSystem

@onready var day_label: Label = %DayLabel
@onready var time_label: Label = %TimeLabel
@onready var phase_label: Label = %PhaseLabel
@onready var wood_label: Label = %WoodLabel
@onready var stone_label: Label = %StoneLabel
@onready var food_label: Label = %FoodLabel
@onready var water_label: Label = %WaterLabel
@onready var cloth_leather_label: Label = %ClothLeatherLabel
@onready var build_menu_panel: Control = %BuildMenuPanel
@onready var farm_button: Button = %FarmButton
@onready var selected_building_label: Label = %SelectedBuildingLabel


func _ready() -> void:
	if catalog == null:
		push_error("HUDController: catalog is not set.")
	if placement_system == null:
		push_error("HUDController: placement_system is not set.")

	WorldState.resources_changed.connect(update_resources)
	WorldState.time_changed.connect(update_time)
	update_resources(WorldState.get_resources_snapshot())
	update_time(WorldState.day, WorldState.hour, WorldState.phase)

	build_menu_panel.visible = false
	farm_button.pressed.connect(select_farm)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_B:
			set_build_menu_visible(not build_menu_panel.visible)
			get_viewport().set_input_as_handled()


func update_resources(resources: Dictionary) -> void:
	wood_label.text = "木材 %d" % int(resources.get(&"wood", 0))
	stone_label.text = "石头 %d" % int(resources.get(&"stone", 0))
	food_label.text = "食物 %d" % int(resources.get(&"food", 0))
	water_label.text = "水 %d" % int(resources.get(&"water", 0))
	cloth_leather_label.text = "布料/皮革 %d" % int(resources.get(&"cloth_leather", 0))


func update_time(day: int, hour: float, phase: StringName) -> void:
	day_label.text = "第 %d 天" % day
	time_label.text = "%02d:%02d" % [int(hour), int(fposmod(hour, 1.0) * 60.0)]
	phase_label.text = get_phase_text(phase)


func get_phase_text(phase: StringName) -> String:
	match phase:
		WorldState.PHASE_DAWN:
			return "清晨"
		WorldState.PHASE_DAY:
			return "白天"
		WorldState.PHASE_NIGHT:
			return "夜晚"
		_:
			return "未知"


func set_build_menu_visible(v: bool) -> void:
	build_menu_panel.visible = v
	if not v and placement_system != null:
		placement_system.set_build_mode_enabled(false)


func select_farm() -> void:
	if catalog == null or placement_system == null:
		return
	if catalog.select_definition_by_id(&"farm"):
		selected_building_label.text = "已选 Farm"
		placement_system.set_build_mode_enabled(true)
