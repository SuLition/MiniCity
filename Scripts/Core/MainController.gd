extends Node2D

@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D

@export var camera_top_air_ratio: float = 0.75

func _ready() -> void:
	setup_camera_limits()
	get_viewport().size_changed.connect(setup_camera_limits)


func setup_camera_limits() -> void:
	var used_rect: Rect2i = terrain_layer.get_used_rect()
	var tile_size: Vector2i = terrain_layer.tile_set.tile_size

	var map_left := used_rect.position.x * tile_size.x
	var map_top := used_rect.position.y * tile_size.y
	var map_right := used_rect.end.x * tile_size.x
	var map_bottom := used_rect.end.y * tile_size.y
	var visible_height := get_viewport_rect().size.y * camera.zoom.y
	var camera_top_air := int(visible_height * camera_top_air_ratio)

	camera.limit_left = map_left
	camera.limit_top = map_top - camera_top_air
	camera.limit_right = map_right
	camera.limit_bottom = map_bottom

	camera.position_smoothing_enabled = false
	camera.position_smoothing_speed = 8.0
