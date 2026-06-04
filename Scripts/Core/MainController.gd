class_name MainController
extends Node2D

@onready var map_container: MapContainer = $MapContainer

var terrain_layer: TileMapLayer
var player: CharacterBody2D
var pcam: PhantomCamera2D

@export var camera_top_air_ratio: float = 0.75

func _ready() -> void:
	map_container.map_changed.connect(_on_map_changed)
	_on_map_changed(map_container.get_current_map())
	get_viewport().size_changed.connect(setup_camera_limits)


func _on_map_changed(new_map: MapBase) -> void:
	terrain_layer = new_map.terrain_layer
	player = new_map.player
	pcam = new_map.pcam
	setup_camera_limits()


func setup_camera_limits() -> void:
	if terrain_layer == null or pcam == null:
		return

	var used_rect: Rect2i = terrain_layer.get_used_rect()
	var tile_size: Vector2i = terrain_layer.tile_set.tile_size

	var map_left := used_rect.position.x * tile_size.x
	var map_top := used_rect.position.y * tile_size.y
	var map_right := used_rect.end.x * tile_size.x
	var map_bottom := used_rect.end.y * tile_size.y
	var visible_height := get_viewport_rect().size.y * pcam.zoom.y
	var camera_top_air := int(visible_height * camera_top_air_ratio)

	pcam.limit_left = map_left
	pcam.limit_top = map_top - camera_top_air
	pcam.limit_right = map_right
	pcam.limit_bottom = map_bottom
