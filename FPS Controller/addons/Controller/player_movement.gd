extends CharacterBody3D

# Configuration tools
@export var SENSITIVITY: int

var ACCEL = default_speed
const FRICTION = 0.85
const AIR_FRICTION = 1.5
const JUMP_VELOCITY = 8

const WALL_JUMP_VELOCITY = 13
const WALL_FRICTION = 0.6
const WALL_JUMP_ALTERING = 2
const WALL_LATCH_DURATION = 2
var WALL_LATCH_TIME = 0
var wall_jump_lock_timer = 0.0
const WALL_JUMP_LOCK_DURATION = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") + 13

# Player States
const FLOOR = 0
const WALL = 1
const AIR = 2
var current_state := AIR
var has_wall_jumped := false
const STANDING = 0
const RUNNING = 1
const CROUCHING = 2
const SLIDING = 3

# Player Stats
const default_speed = 500
var jump_count_max = 2
var jump_count_current = 0
var speed_sprint = 150
var speed_wallrun = 300

# Signals
signal jump_updated(current,max)
signal accel_updated(current)
signal state_updated(state)

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
	if direction.length() > 0:
		if current_state == AIR:
			velocity.x = lerp(velocity.x, direction.x * ACCEL * delta, 0.07)
			velocity.z = lerp(velocity.z, direction.z * ACCEL * delta, 0.07)
		elif current_state == FLOOR:
			velocity.x = lerp(velocity.x, direction.x * ACCEL * delta, 0.1)
			velocity.z = lerp(velocity.z, direction.z * ACCEL * delta, 0.1)
	else:
		velocity.x = lerp(velocity.x, direction.x * ACCEL, 0.2)
		velocity.z = lerp(velocity.z, direction.z * ACCEL, 0.2)

	check_running()
	check_jump(direction)
	move_and_slide()
	update_state()

	# Player move speed during states
	if current_state == WALL:
		velocity.x = lerp(velocity.x, direction.x * ACCEL * delta, 0.1)
		velocity.z = lerp(velocity.z, direction.z * ACCEL * delta, 0.1)
		velocity.y *= WALL_FRICTION + 0.3


# Constantly update
func update_state():
	emit_signal("accel_updated", ACCEL)
	emit_signal("state_updated", current_state)
	
	if is_on_floor():
		current_state = FLOOR
		has_wall_jumped = false
		jump_count_current = 0
		emit_signal("jump_updated", jump_count_current, jump_count_max)
		if ACCEL > default_speed and not Input.is_action_pressed("sprint"):
			ACCEL -= 40
		elif ACCEL < (default_speed) and not ACCEL >  (default_speed + 20):
			ACCEL = default_speed
		return

	if is_on_wall_only():
		current_state = WALL
		jump_count_current = 1
		if ACCEL < (default_speed + speed_wallrun):
			ACCEL += 50
			emit_signal("jump_updated", jump_count_current, jump_count_max)
		if ACCEL > (default_speed + speed_wallrun):
			ACCEL -= 30
		elif  ACCEL > (default_speed + speed_wallrun) and not ACCEL < (default_speed + speed_wallrun):
			ACCEL = default_speed + speed_wallrun
	else:
		current_state = AIR

func check_running():
	if Input.is_action_pressed("sprint") and current_state == FLOOR:
		if not ACCEL >= (default_speed + speed_sprint):
			ACCEL += 10
		if ACCEL > (default_speed + speed_sprint):
			ACCEL -= 30
			if ACCEL > (default_speed + speed_sprint) and ACCEL < (default_speed + speed_sprint):
				ACCEL = speed_sprint

# Jumping Controls
func check_jump(dir):
	
	#Basic Jump
	if Input.is_action_just_pressed("jump"):
		if current_state == FLOOR:
			velocity.y = JUMP_VELOCITY
			jump_count_current += 1
			
			emit_signal("jump_updated", jump_count_current, jump_count_max)

		# Wall Jumping
		if current_state == WALL:
			jump_count_current += 1
			emit_signal("jump_updated", jump_count_current, jump_count_max)
			ACCEL +=  100
			var cam_fwd = -$Head/Sight.transform.basis.z.normalized()
			var target_velocity = get_wall_normal() * WALL_JUMP_VELOCITY
			velocity.x = lerp(cam_fwd.x, target_velocity.x, WALL_JUMP_ALTERING)
			velocity.z = lerp(cam_fwd.z, target_velocity.z, WALL_JUMP_ALTERING)
			velocity.y += (WALL_JUMP_VELOCITY)
			has_wall_jumped = true

		# Double Jump
		elif current_state == AIR and Input.is_action_just_pressed("jump") and jump_count_current < jump_count_max and has_wall_jumped == false:
			velocity.y = JUMP_VELOCITY
			jump_count_current += 1
			emit_signal("jump_updated", jump_count_current, jump_count_max)

# Camera
func _input(event):
	if event is InputEventMouseMotion:
		var sight = get_node("Head/Sight")
		$Head/Sight.rotation.y -= event.relative.x * (SENSITIVITY * 0.001)
		$Head/Sight.rotation.x += event.relative.y * (-1 * (SENSITIVITY * 0.001))
