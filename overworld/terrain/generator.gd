@tool
class_name OverworldTerrainGenerator
extends TerrainGenerator3D

@export var resolution: Vector2i = Vector2i(1, 1)
@export var amplification: float = 16.0
@export var noise: FastNoiseLite

func generate_chunk(chunk: TerrainChunk3D) -> void:
	if not noise: return
	noise.seed = base_seed
	
	var plane := PlaneMesh.new()
	plane.size = Vector2(chunk.size.x, chunk.size.z)
	plane.subdivide_width = chunk.size.x * resolution.x
	plane.subdivide_depth = chunk.size.z * resolution.y

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())

	var data := MeshDataTool.new()
	data.create_from_surface(mesh, 0)

	for i in range(data.get_vertex_count()):
		var v := data.get_vertex(i)
		v.y = clampf((1 + noise.get_noise_2d(chunk.world_position.x + v.x, chunk.world_position.z + v.z)) * amplification, 0.0, chunk.size.y)

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

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not noise: warnings.append("No noise assigned")
	return warnings
