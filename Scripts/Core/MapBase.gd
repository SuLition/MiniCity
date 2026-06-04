class_name MapBase
extends Node2D

@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var building_root: Node2D = $BuildingRoot
@onready var player: CharacterBody2D = $Actors/Player
@onready var pcam: PhantomCamera2D = $Actors/Player/PhantomCamera2D
