extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.5
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

# headbob variables
const BOB_FREQ = 2.0  # Increase the frequency for a more noticeable effect
const BOB_AMP_Y = 0.09  # Increase the Y amplitude for more vertical movement
const BOB_AMP_X = 0.05  # Increase the X amplitude for subtle horizontal movement
var t_bob = 0.0

# fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
var original_camera_position

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_camera_position = camera.transform.origin

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * SENSITIVITY
		head.rotation.x -= event.relative.y * SENSITIVITY
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-70), deg_to_rad(40))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction != Vector3.ZERO:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)		

	# Increment t_bob for head bobbing effect
	if is_on_floor() and velocity.length() > 0:
		t_bob += delta * velocity.length() * BOB_FREQ
	else:
		t_bob = 0.0  # Reset bobbing when not moving

	# Apply head bobbing effect
	var headbob_offset = _headbob(t_bob)
	camera.transform.origin = original_camera_position + headbob_offset
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	# Adjust FOV only when sprinting
	var target_FOV
	if Input.is_action_pressed("sprint"):
		target_FOV = BASE_FOV + FOV_CHANGE * (velocity_clamped)
	else:
		target_FOV = BASE_FOV

	camera.fov = lerp(camera.fov, target_FOV, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time) * BOB_AMP_Y
	pos.x = cos(time * 0.5) * BOB_AMP_X
	return pos
