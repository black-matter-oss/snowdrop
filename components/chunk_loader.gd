@tool
class_name ChunkLoader
extends NodeComponent

@export var terrain_manager: TerrainManager3D
@export var load_radius: Vector3 = Vector3(0, 0, 0)

var current_chunk: TerrainChunk3D
var loaded_chunks: Array[TerrainChunk3D] = []

var current_chunk_coordinates: Vector3i
var last_chunk_coordinates: Vector3i = Vector3i.MAX

func _physics_process(delta: float) -> void:
	current_chunk_coordinates = Vector3i(
		floori(parent.global_position.x / terrain_manager.chunk_size.x),
		floori(parent.global_position.y / terrain_manager.chunk_size.y),
		floori(parent.global_position.z / terrain_manager.chunk_size.z),
	)

	DebugDraw2D.begin_text_group(get_path())
	DebugDraw2D.set_text("current_chunk_coordinates", current_chunk_coordinates)
	
	# key is distance from center to parent
	var chunks_to_load: Dictionary[float, Vector3i] = {}

	if current_chunk_coordinates != last_chunk_coordinates:
		GlobalDebug.time_measure_start(get_path(), "load picking logic", false)

		# TODO can you do ranges on a Vector3 export?
		if load_radius.x <= 0: load_radius.x = 0.001
		if load_radius.y <= 0: load_radius.y = 0.001
		if load_radius.z <= 0: load_radius.z = 0.001

		if load_radius > Vector3(0.001, 0.001, 0.001):
			for chunk_y in range(-load_radius.y, load_radius.y + 1):
				for chunk_x in range(-load_radius.x, load_radius.x + 1):
					for chunk_z in range(-load_radius.z, load_radius.z + 1):
						# check if inside ellipsoid
						if pow(chunk_x / load_radius.x, 2) + pow(chunk_y / load_radius.y, 2) + pow(chunk_z / load_radius.z, 2) <= 1:
							var chunk_coordinates := Vector3i(
								current_chunk_coordinates.x + chunk_x,
								current_chunk_coordinates.y + chunk_y,
								current_chunk_coordinates.z + chunk_z
							)

							#DebugDraw2D.set_text(str(chunk_coordinates), "loading")
							_print_debug("loading %s" % str(chunk_coordinates))

							var distance_to_center := sqrt(
								pow(((chunk_coordinates.x + 0.5) * terrain_manager.chunk_size.x) - parent.global_position.x, 2)
								 + pow(((chunk_coordinates.y + 0.5) * terrain_manager.chunk_size.y) - parent.global_position.y, 2)
								 + pow(((chunk_coordinates.z + 0.5) * terrain_manager.chunk_size.z) - parent.global_position.z, 2)
							)

							chunks_to_load[distance_to_center] = chunk_coordinates
			
			# sort chunks by distance
			chunks_to_load.sort()
		else:
			chunks_to_load[0] = current_chunk_coordinates
		
		GlobalDebug.time_measure_end(get_path(), "load picking logic")
	
	if chunks_to_load.size() > 0:
		for i in loaded_chunks.size():
			var chunk := loaded_chunks[i]
			if not chunk: continue

			if chunk.coordinates not in chunks_to_load.values():
				# unload unneeded chunk
				#DebugDraw2D.set_text(str(chunk.coordinates), "unloading")
				_print_debug("unloading %s" % str(chunk.coordinates))
				terrain_manager.unload_chunk(chunk.coordinates)

	var chunks_to_generate: Array[TerrainChunk3D] = []

	for k in chunks_to_load:
		var chunk_coordinates := chunks_to_load[k]
		var chunk := terrain_manager.store.get_chunk(chunk_coordinates)

		if not chunk:
			_print_debug("generating chunk at %s" % chunk_coordinates)

			chunk = terrain_manager.create_chunk(chunk_coordinates)
			chunks_to_generate.append(chunk)
			#terrain_manager.generate_chunk(chunk_coordinates)
		
		if chunk_coordinates == current_chunk_coordinates:
			current_chunk = chunk
		
		loaded_chunks.append(chunk)
	
	if not chunks_to_generate.is_empty():
		terrain_manager.generator.generate_chunks(chunks_to_generate)
	
	last_chunk_coordinates = current_chunk_coordinates
	DebugDraw2D.end_text_group()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not terrain_manager: warnings.append("No terrain manager assigned")
	return warnings
