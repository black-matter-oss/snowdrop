class_name PlayerController3D
extends Node

@onready var player: Player3D = self.get_parent()

@export var speed: float = 2.0
@export var camera_sensitivity: float = 0.01

@export var input_forward: StringName = "player_move_f"
@export var input_backward: StringName = "player_move_b"
@export var input_left: StringName = "player_move_l"
@export var input_right: StringName = "player_move_r"

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("player_camera_toggle"): # TODO
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# camera movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion := event as InputEventMouseMotion
		
		if player.camera_first_person:
			player.rotate_y(-mouse_motion.relative.x * camera_sensitivity)
			player.camera.rotate_x(-mouse_motion.relative.y * camera_sensitivity)

			player.camera.rotation_degrees.x = clampf(player.camera.rotation_degrees.x, -89.9, 89.9)
		else:
			push_error("NOT IMPLEMENTED") # TODO

	# player movement
	var direction := Vector3.ZERO
	var camera_basis := player.camera.global_basis

	# TODO movement is slower depending on how close camera pitch is to (-)90
	if Input.is_action_pressed(input_forward):
		direction += -camera_basis.z
	
	if Input.is_action_pressed(input_backward):
		direction += camera_basis.z

	if Input.is_action_pressed(input_left):
		direction += -camera_basis.x
	
	if Input.is_action_pressed(input_right):
		direction += camera_basis.x
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

# func _physics_process(delta: float) -> void:
# 	player.velocity += input_velocity
# 	input_velocity = Vector3.ZERO
