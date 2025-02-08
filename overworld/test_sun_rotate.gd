extends DirectionalLight3D

func _physics_process(delta: float) -> void:
	rotate_x(delta / 2)
