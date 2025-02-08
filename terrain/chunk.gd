@tool
class_name TerrainChunk3D
extends StaticBody3D

const FlatNormalsShader: Shader = preload("uid://cllxjkrv1icva")

var coordinates: Vector3i
var size: Vector3i

var world_position: Vector3:
	get:
		return coordinates * size

var mesh_instance: MeshInstance3D:
	set(value):
		if is_inside_tree():
			if mesh_instance:
				remove_child(mesh_instance)
				mesh_instance.queue_free()
			
			if value:
				add_child(value)
		
		mesh_instance = value

		if mesh_instance:
			if not GlobalOptions.SMOOTH_TERRAIN:
				var flat_material := ShaderMaterial.new()
				flat_material.shader = FlatNormalsShader
				mesh_instance.mesh.surface_set_material(0, flat_material)

var collision_shape: CollisionShape3D:
	set(value):
		if is_inside_tree():
			if collision_shape:
				remove_child(collision_shape)
				collision_shape.queue_free()
			
			if value:
				add_child(value)
		
		collision_shape = value

func _init(coordinates: Vector3i, size: Vector3i, mesh_instance: MeshInstance3D) -> void:
	self.coordinates = coordinates
	self.size = size
	self.mesh_instance = mesh_instance

func _enter_tree() -> void:
	position = coordinates * size

	if mesh_instance: add_child(mesh_instance)
	if collision_shape: add_child(collision_shape)
