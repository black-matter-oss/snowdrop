@tool
class_name NodeComponent
extends Node

@onready var parent: Node3D = self.get_parent()

func _print_debug(msg: String) -> void:
	if not OS.is_debug_build(): return
	print(("[%s/%s] " % [parent.name, name]) + msg)
