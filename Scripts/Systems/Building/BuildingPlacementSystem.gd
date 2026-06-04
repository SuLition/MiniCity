class_name BuildingPlacementSystem
extends Node

@export var map_container: MapContainer
@export var catalog: BuildingCatalog
@export var occupancy_system: BuildingOccupancySystem
@export var preview_valid_color: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var preview_invalid_color: Color = Color(1.0, 0.25, 0.25, 0.55)

var build_mode_enabled := false
var current_origin_cell := Vector2i.ZERO
var current_can_place := false
var terrain_layer: TileMapLayer
var building_root: Node2D
var preview_sprite: Sprite2D
var preview_definition: BuildingDefinition


func _ready() -> void:
	if not validate_exports():
		set_process(false)
		set_process_unhandled_input(false)
		return

	map_container.map_changed.connect(_on_map_changed)
	_on_map_changed.call_deferred(map_container.get_current_map())


func _process(_delta: float) -> void:
	if build_mode_enabled:
		update_placement_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		handle_build_key_input(event as InputEventKey)
		return

	if not build_mode_enabled:
		return

	if event is InputEventMouseButton:
		handle_build_mouse_input(event as InputEventMouseButton)


func validate_exports() -> bool:
	if map_container == null:
		push_error("BuildingPlacementSystem: map_container is not set.")
		return false
	if catalog == null:
		push_error("BuildingPlacementSystem: catalog is not set.")
		return false
	if occupancy_system == null:
		push_error("BuildingPlacementSystem: occupancy_system is not set.")
		return false
	return true


func _on_map_changed(new_map: MapBase) -> void:
	if new_map == null:
		return
	terrain_layer = new_map.terrain_layer
	building_root = new_map.building_root
	if is_instance_valid(preview_sprite):
		preview_sprite.queue_free()
	setup_preview()


func setup_preview() -> void:
	preview_sprite = Sprite2D.new()
	preview_sprite.name = "PlacementPreview"
	preview_sprite.visible = false
	preview_sprite.z_index = 10
	preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	building_root.add_child(preview_sprite)


func handle_build_key_input(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE and build_mode_enabled:
		set_build_mode_enabled(false)
		get_viewport().set_input_as_handled()


func handle_build_mouse_input(event: InputEventMouseButton) -> void:
	if not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if current_can_place:
			place_selected_building(current_origin_cell)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		set_build_mode_enabled(false)
		get_viewport().set_input_as_handled()


func set_build_mode_enabled(enabled: bool) -> void:
	build_mode_enabled = enabled
	preview_sprite.visible = enabled
	if enabled:
		update_placement_preview()


func update_placement_preview() -> void:
	var definition := get_selected_definition()
	if definition == null:
		current_can_place = false
		preview_sprite.visible = false
		return

	sync_preview_visual(definition)

	var ground_cell := get_ground_cell_under_mouse()
	current_origin_cell = get_building_origin_from_ground_cell(ground_cell, definition)
	current_can_place = can_place_building(definition, current_origin_cell)

	preview_sprite.visible = build_mode_enabled
	preview_sprite.global_position = get_building_world_position(current_origin_cell, definition)
	preview_sprite.modulate = preview_valid_color if current_can_place else preview_invalid_color


func get_selected_definition() -> BuildingDefinition:
	var definition := catalog.get_selected_definition()
	if definition == null or not definition.is_valid():
		return null
	return definition


func sync_preview_visual(definition: BuildingDefinition) -> void:
	if preview_definition == definition:
		return
	preview_definition = definition
	preview_sprite.texture = definition.texture
	preview_sprite.scale = definition.get_texture_scale()
	preview_sprite.offset = definition.visual_offset


func get_ground_cell_under_mouse() -> Vector2i:
	# terrain_layer provides get_global_mouse_position() as it is a Node2D
	var mouse_world_pos := terrain_layer.get_global_mouse_position()
	return terrain_layer.local_to_map(terrain_layer.to_local(mouse_world_pos))


func get_building_origin_from_ground_cell(ground_cell: Vector2i, definition: BuildingDefinition) -> Vector2i:
	var half_width := int(floor(float(definition.footprint.x) * 0.5))
	return Vector2i(ground_cell.x - half_width, ground_cell.y - definition.footprint.y)


func can_place_building(definition: BuildingDefinition, origin_cell: Vector2i) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if not occupancy_system.can_occupy(origin_cell, definition.footprint):
		return false
	if not ResourceManager.can_afford(definition.build_cost):
		return false

	for y in range(definition.footprint.y):
		for x in range(definition.footprint.x):
			if is_terrain_cell(origin_cell + Vector2i(x, y)):
				return false

	for x in range(definition.footprint.x):
		if not is_terrain_cell(origin_cell + Vector2i(x, definition.footprint.y)):
			return false

	return true


func place_selected_building(origin_cell: Vector2i) -> void:
	var definition := get_selected_definition()
	if definition == null or not can_place_building(definition, origin_cell):
		return

	var building := BuildingInstance.new()
	building.setup(definition, origin_cell, get_building_world_position(origin_cell, definition))
	building.z_index = 1
	building_root.add_child(building)

	if not occupancy_system.occupy(building, origin_cell, definition.footprint):
		building.queue_free()
		return

	if not ResourceManager.spend(definition.build_cost):
		occupancy_system.release(building)
		building.queue_free()
		return

	update_placement_preview()


func get_building_world_position(origin_cell: Vector2i, definition: BuildingDefinition) -> Vector2:
	var tile_size := get_tile_size_vector()
	var top_left_tile_center := terrain_layer.map_to_local(origin_cell)
	var top_left_corner := top_left_tile_center - tile_size * 0.5
	var footprint_center := top_left_corner + get_footprint_pixel_size(definition.footprint) * 0.5
	return terrain_layer.to_global(footprint_center)


func get_footprint_pixel_size(footprint: Vector2i) -> Vector2:
	var tile_size := get_tile_size_vector()
	return Vector2(float(footprint.x) * tile_size.x, float(footprint.y) * tile_size.y)


func get_tile_size_vector() -> Vector2:
	var tile_size: Vector2i = terrain_layer.tile_set.tile_size
	return Vector2(tile_size.x, tile_size.y)


func is_terrain_cell(cell: Vector2i) -> bool:
	return terrain_layer.get_cell_source_id(cell) != -1
