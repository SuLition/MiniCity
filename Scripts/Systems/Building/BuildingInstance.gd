class_name BuildingInstance
extends Node2D

const STATUS_BLUEPRINT: StringName = &"blueprint"

var definition: BuildingDefinition
var origin_cell := Vector2i.ZERO
var status: StringName = STATUS_BLUEPRINT
var work_completed: int = 0
var work_required: int = 0
var production_per_day: Dictionary = {}
var sprite: Sprite2D

func setup(building_definition: BuildingDefinition, building_origin_cell: Vector2i, world_position: Vector2) -> void:
	definition = building_definition
	origin_cell = building_origin_cell
	global_position = world_position
	status = STATUS_BLUEPRINT
	work_completed = 0
	work_required = definition.build_work_required
	production_per_day = definition.production_per_day.duplicate(true)
	name = "%s_%s_%s" % [String(definition.building_id), origin_cell.x, origin_cell.y]
	setup_visual()


func setup_visual() -> void:
	if definition == null:
		return

	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Visual"
		add_child(sprite)

	sprite.texture = definition.texture
	sprite.scale = definition.get_texture_scale()
	sprite.position = definition.visual_offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
