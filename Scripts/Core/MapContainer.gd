class_name MapContainer
extends Node2D

signal map_changed(new_map: MapBase)

func load_map(scene: PackedScene) -> void:
	for child in get_children():
		child.queue_free()
	var map := scene.instantiate() as MapBase
	add_child(map)
	await map.ready
	map_changed.emit(map)

func get_current_map() -> MapBase:
	if get_child_count() > 0:
		return get_child(0) as MapBase
	return null
