class_name BuildingInstance
extends Node2D

var definition: BuildingDefinition
var origin_cell := Vector2i.ZERO
var sprite: Sprite2D

func setup(building_definition: BuildingDefinition, building_origin_cell: Vector2i, world_position: Vector2) -> void:
	definition = building_definition
	origin_cell = building_origin_cell
	global_position = world_position
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
