@tool
class_name TerrainManager3D
extends Node

@export var generator: TerrainGenerator3D
@export var store: TerrainStore3D

@export var chunk_size: Vector3i = Vector3i(64, 64, 64)

func _process(delta: float) -> void:
	if OS.is_debug_build():
		DebugDraw2D.begin_text_group(get_path())
		DebugDraw2D.set_text("loaded chunks", store.get_loaded_chunks().size())
		DebugDraw2D.end_text_group()

func create_chunk(coordinates: Vector3i) -> TerrainChunk3D:
	var chunk := TerrainChunk3D.new(coordinates, chunk_size, null)
	store.add_chunk(chunk)

	return chunk

func unload_chunk(coordinates: Vector3i) -> void:
	# TODO check if other entities are using that chunk etc
	if coordinates not in store._chunks: return
	store.remove_chunk(coordinates)
	#store.call_deferred("remove_chunk", coordinates)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	if not generator: warnings.append("No generator assigned")
	if not store: warnings.append("No chunk store assigned")
	return warnings
