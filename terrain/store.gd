@tool
class_name TerrainStore3D
extends Node3D

@onready var manager: TerrainManager3D = self.get_parent()

var _chunks: Dictionary[Vector3i, TerrainChunk3D] = {}

func add_chunk(chunk: TerrainChunk3D) -> void:
	if chunk.coordinates in _chunks:
		remove_child(_chunks[chunk.coordinates])
	
	_chunks[chunk.coordinates] = chunk
	add_child(chunk)

func remove_chunk(coordinates: Vector3i) -> void:
	remove_child(_chunks[coordinates])
	_chunks[coordinates].queue_free()
	_chunks.erase(coordinates)

# func set_chunk(coordinates: Vector3i, chunk: TerrainChunk3D) -> void:
# 	if chunk.coordinates in _chunks:
# 		remove_child(_chunks[coordinates])
	
# 	chunk.coordinates = coordinates
# 	_chunks[coordinates] = chunk
# 	add_child(chunk)

func get_chunk(coordinates: Vector3i) -> TerrainChunk3D:
	if coordinates not in _chunks: return null
	return _chunks[coordinates]

func get_loaded_chunks() -> Dictionary:
	return _chunks
