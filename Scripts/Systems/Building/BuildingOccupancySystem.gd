class_name BuildingOccupancySystem
extends Node

var occupied_cells: Dictionary = {}

func can_occupy(origin_cell: Vector2i, footprint: Vector2i) -> bool:
	if footprint.x <= 0 or footprint.y <= 0:
		return false

	for cell in get_footprint_cells(origin_cell, footprint):
		if occupied_cells.has(cell):
			return false

	return true


func occupy(owner: Node, origin_cell: Vector2i, footprint: Vector2i) -> bool:
	if owner == null or not can_occupy(origin_cell, footprint):
		return false

	for cell in get_footprint_cells(origin_cell, footprint):
		occupied_cells[cell] = owner

	return true


func release(owner: Node) -> void:
	var cells_to_release: Array[Vector2i] = []

	for cell in occupied_cells:
		if occupied_cells[cell] == owner:
			cells_to_release.append(cell)

	for cell in cells_to_release:
		occupied_cells.erase(cell)


func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)


func get_footprint_cells(origin_cell: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for y in range(footprint.y):
		for x in range(footprint.x):
			cells.append(origin_cell + Vector2i(x, y))

	return cells
