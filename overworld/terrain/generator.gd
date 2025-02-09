@tool
class_name OverworldTerrainGenerator
extends TerrainGenerator3D

const biome_shader: Shader = preload("uid://dxdegkfvvwerb")

@export var resolution: Vector2i = Vector2i(1, 1)
@export var amplification: float = 16.0

func _create_shader_map(chunk: TerrainChunk3D, shader: Shader) -> Viewport:
	var viewport := SubViewport.new()
	add_child(viewport)
	viewport.size = Vector2i(chunk.size.x + 1, chunk.size.z + 1)
	viewport.disable_3d = true
	viewport.gui_disable_input = true

	var rect := ColorRect.new()
	viewport.add_child(rect)
	rect.size = viewport.size
	rect.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("scale", 0.2)
	material.set_shader_parameter("size", Vector2(chunk.size.x + 1, chunk.size.z + 1))
	material.set_shader_parameter("moveV", Vector2(chunk.coordinates.x, chunk.coordinates.z))

	rect.material = material

	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return viewport

func _generate_chunk(chunk: TerrainChunk3D, img: Image) -> void:
	if not _get_configuration_warnings().is_empty(): return
	
	var plane := PlaneMesh.new()
	# +2 to ensure smooth falloff without holes at edges
	plane.size = Vector2(chunk.size.x + 2, chunk.size.z + 2)
	plane.subdivide_width = chunk.size.x * resolution.x + 1
	plane.subdivide_depth = chunk.size.z * resolution.y + 1

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())

	var data := MeshDataTool.new()
	data.create_from_surface(mesh, 0)

	#img.save_png("res://.test/%s+%s.png" % [ str(chunk.coordinates.x), str(chunk.coordinates.z) ])

	for i in range(data.get_vertex_count()):
		var v := data.get_vertex(i)
		
		var x := chunk.size.x / 2 + floori(v.x)
		var z := chunk.size.z / 2 + floori(v.z)

		# TODO there could be ways to improve this
		if x == -1 or x == chunk.size.x + 1 or z == -1 or z == chunk.size.z + 1:
			continue

		var c := img.get_pixel(x, z)
		v.y = c.r * amplification

		data.set_vertex(i, v)

	mesh.clear_surfaces()
	data.commit_to_surface(mesh)

	var surface := SurfaceTool.new()
	surface.create_from(mesh, 0)
	surface.generate_normals()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = surface.commit()

	chunk.mesh_instance = mesh_instance

	if generate_collisions:
		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()

		chunk.collision_shape = collision_shape

func generate_chunks(chunks: Array[TerrainChunk3D]) -> void:
	GlobalDebug.time_measure_start(get_path(), "generate_chunks (shader maps)")
	DebugDraw2D.set_text("chunks to generate", chunks.size())

	var maps: Array[Viewport] = []

	for chunk in chunks:
		maps.append(_create_shader_map(chunk, biome_shader))
	
	await RenderingServer.frame_post_draw # this updates all viewports at once

	# remove all viewports
	for child in get_children():
		if child is Viewport:
			remove_child(child)
			child.queue_free()
	
	GlobalDebug.time_measure_end(get_path(), "generate_chunks (shader maps)", false)
	GlobalDebug.time_measure_start(get_path(), "generate_chunks (chunks total)", false)
	
	for i in chunks.size():
		GlobalDebug.time_measure_start(get_path(), "generate_chunks (chunks single)", false)
		_generate_chunk(chunks[i], maps[i].get_texture().get_image())
		GlobalDebug.time_measure_end(get_path(), "generate_chunks (chunks single)", false)
	
	GlobalDebug.time_measure_end(get_path(), "generate_chunks (chunks total)")

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	return warnings
