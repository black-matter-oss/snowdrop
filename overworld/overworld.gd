@tool
class_name Overworld
extends Node3D

@export var terrain_manager: TerrainManager3D
@export var player: Player3D

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not terrain_manager: warnings.append("No terrain manager assigned")
	return warnings
