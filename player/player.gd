class_name Player3D
extends CharacterBody3D

@export var controller: PlayerController3D
@export var camera: Camera3D

@export var camera_first_person: bool = true

func _process(delta: float) -> void:
	DebugDraw2D.begin_text_group("[player/player]")
	DebugDraw2D.set_text("global_position", global_position)
	DebugDraw2D.end_text_group()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += Vector3(0, -GlobalPhysics.GRAVITY * delta, 0)

	move_and_slide()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not controller: warnings.append("No controller assigned")
	if not camera: warnings.append("No camera assigned")
	return warnings
