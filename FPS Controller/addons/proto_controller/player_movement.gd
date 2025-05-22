extends CharacterBody3D

# Configuration tools
@export var SENSITIVITY: int

const ACCEL = 400
const FRICTION = 0.85
const AIR_FRICTION = 0.95
const JUMP_VELOCITY = 6
const WALL_JUMP_VELOCITY = 5
const WALL_FRICTION = 0.5
const WALL_JUMP_ALTERING = 6	
const WALL_LATCH_TIME = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") + 3

# Player States
const FLOOR = 0
const WALL = 1
const AIR = 2

var current_state := AIR
var has_wall_jumped := false


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Get the input direction and handle the movement/deceleration
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, $Head/Sight.rotation.y)
	if direction:
		velocity.x = direction.x * ACCEL * delta
		velocity.z = direction.z * ACCEL * delta
		
	check_jump(direction)
	move_and_slide()
	update_state()
	velocity.x *= FRICTION
	velocity.z *= FRICTION
	if current_state == WALL:
		velocity.y *= WALL_FRICTION
		
# Constantly update
func update_state():
	if is_on_wall_only():
		current_state = WALL
	elif is_on_floor():
		current_state = FLOOR
		has_wall_jumped = false
	else:
		current_state = AIR

# Jumping Controls
func check_jump(dir):
	if Input.is_action_just_pressed("jump"):
		if current_state == FLOOR:
			velocity.y = JUMP_VELOCITY
		if current_state == WALL and not has_wall_jumped:
			var target_velocity = get_wall_normal() * WALL_JUMP_VELOCITY
			velocity.x = lerp(velocity.x, target_velocity.x, WALL_JUMP_ALTERING)
			velocity.z = lerp(velocity.z, target_velocity.z, WALL_JUMP_ALTERING)
			velocity += dir * WALL_JUMP_ALTERING
			velocity.y += JUMP_VELOCITY
			has_wall_jumped = true

# Camera
func _input(event):
	if event is InputEventMouseMotion:
		var sight = get_node("Head/Sight")
		$Head/Sight.rotation.y -= event.relative.x * (SENSITIVITY * 0.001)
		$Head/Sight.rotation.x += event.relative.y * (-1 * (SENSITIVITY * 0.001))
