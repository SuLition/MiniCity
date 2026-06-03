class_name BuildingDefinition
extends Resource

@export var building_id: StringName = &""
@export var display_name: String = ""
@export var texture: Texture2D
@export var footprint: Vector2i = Vector2i.ONE
@export var visual_size: Vector2 = Vector2(64.0, 64.0)
@export var visual_offset: Vector2 = Vector2.ZERO

func is_valid() -> bool:
	return (
		building_id != &""
		and texture != null
		and footprint.x > 0
		and footprint.y > 0
		and visual_size.x > 0.0
		and visual_size.y > 0.0
	)


func get_texture_scale() -> Vector2:
	if texture == null:
		return Vector2.ONE

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE

	return Vector2(
		visual_size.x / texture_size.x,
		visual_size.y / texture_size.y
	)
