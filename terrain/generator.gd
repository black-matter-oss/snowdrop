@tool
class_name TerrainGenerator3D
extends Node

@onready var manager: TerrainManager3D = self.get_parent()

@export var generate_collisions: bool = false
@export var base_seed: int = randi()

func generate_chunk(chunk: TerrainChunk3D) -> void:
	push_error("NOT IMPLEMENTED")
