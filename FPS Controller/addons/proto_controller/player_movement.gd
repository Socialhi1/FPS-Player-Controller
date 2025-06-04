extends CharacterBody3D

# Configuration tools
@export var SENSITIVITY: int
@export var HOVER : bool

var ACCEL = 400
const FRICTION = 0.85
const AIR_FRICTION = .7
const JUMP_VELOCITY = 8
const WALL_JUMP_VELOCITY = 5
const WALL_FRICTION = 0.5
const WALL_JUMP_ALTERING = 4
const WALL_LATCH_TIME = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") + 10

# Player States
const FLOOR = 0
const WALL = 1
const AIR = 2
var current_state := AIR
#var has_wall_jumped := false

# Player Stats
var jump_count_max = 2
var jump_count_current = 0

# Signals
signal jump_updated(current,max)
signal accel_updated(current)

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
			velocity.x = lerp(velocity.x, direction.x * ACCEL * delta, 0.1)
			velocity.z = lerp(velocity.z, direction.z * ACCEL * delta, 0.1)
		elif current_state == FLOOR:
			velocity.x = direction.x * ACCEL * delta
			velocity.z = direction.z * ACCEL * delta
	else:
		if current_state == AIR:
			velocity.x *= AIR_FRICTION
			velocity.z *= AIR_FRICTION
		else:
			velocity.x = lerp(velocity.x, direction.x * ACCEL, 0.2)
			velocity.z = lerp(velocity.z, direction.z * ACCEL, 0.2)


	check_jump(direction)
	move_and_slide()
	update_state()

	# Player move speed during states
	if current_state == WALL:
		velocity.x *= 0.9  # small damping to keep momentum smooth
		velocity.z *= 0.9
		velocity.y *= WALL_FRICTION + 0.3
	elif current_state == FLOOR:
		if Input.is_action_pressed("sprint"):
			if ACCEL < 550:
				ACCEL += 10
		if ACCEL > 400 and not Input.is_action_pressed("sprint"):
			ACCEL -= 10
		elif ACCEL < 400 and not ACCEL >  400:
			ACCEL = 400

# Constantly update
func update_state():
	emit_signal("accel_updated", ACCEL)
	if is_on_wall_only():
		current_state = WALL
		jump_count_current = 0
		if ACCEL < 700:
			ACCEL += 30
			emit_signal("jump_updated", jump_count_current, jump_count_max)
		if ACCEL > 700:
			ACCEL -= 10
		elif  ACCEL > 700 and not ACCEL < 680:
			ACCEL = 700
		
	elif is_on_floor():
		current_state = FLOOR
		#has_wall_jumped = false
		jump_count_current = 0
		emit_signal("jump_updated", jump_count_current, jump_count_max)
	else:
		current_state = AIR

# Jumping Controls
func check_jump(dir):
	if Input.is_action_just_pressed("jump"):
		if current_state == FLOOR:
			velocity.y = JUMP_VELOCITY
			jump_count_current += 1
			emit_signal("jump_updated", jump_count_current, jump_count_max)

		if current_state == WALL: #and not has_wall_jumped:
			ACCEL +=  75
			var cam_fwd = -$Head/Sight.transform.basis.z.normalized()
			var target_velocity = get_wall_normal() * WALL_JUMP_VELOCITY
			velocity.x = lerp(cam_fwd.x, target_velocity.x, WALL_JUMP_ALTERING)
			velocity.z = lerp(cam_fwd.z, target_velocity.z, WALL_JUMP_ALTERING)
			velocity.y += (JUMP_VELOCITY + 3)
			#has_wall_jumped = true

		if Input.is_action_just_pressed("jump") and jump_count_current < jump_count_max and current_state == AIR:
			velocity.y = JUMP_VELOCITY
			jump_count_current += 1
			emit_signal("jump_updated", jump_count_current, jump_count_max)

# Camera
func _input(event):
	if event is InputEventMouseMotion:
		var sight = get_node("Head/Sight")
		$Head/Sight.rotation.y -= event.relative.x * (SENSITIVITY * 0.001)
		$Head/Sight.rotation.x += event.relative.y * (-1 * (SENSITIVITY * 0.001))
