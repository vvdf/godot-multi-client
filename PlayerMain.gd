extends KinematicBody

var update_movement_max_disparity = 1
var player_id = 0
var facing = 0
var mouse_sensitivity = 0.3
var min_pitch = -90
var max_pitch = 90

var speed = 25

onready var camera_pivot = $CameraPivot
onready var camera = $CameraPivot/CameraBoom/Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_translation(Vector3(0, 0, 0))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func player_command():
	var movement = Vector3(0, 0, 0)
	var movement_attempted = false
	
	# Server Relative Inputs
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
		movement_attempted = true
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
		movement_attempted = true
	if Input.is_action_pressed("ui_up"):
		movement.z -= 1
		movement_attempted = true
	if Input.is_action_pressed("ui_down"):
		movement.z += 1
		movement_attempted = true
	
	move_and_slide(movement.normalized() * speed)

	# only send attempted updated position when movements are attempted
	# so as not to flood the network with 0s
	if movement_attempted:
		get_parent().update_server(get_translation(), player_id)
		
# Function for client to run to determine if we need to update current position
# to catch up/be accurate with server
func check_for_client_move(new_pos):
	var curr_pos = get_translation()
	get_parent().debug_pos(curr_pos, new_pos)
	if (abs(curr_pos.x - new_pos.x) > update_movement_max_disparity
		|| abs(curr_pos.z - new_pos.z) > update_movement_max_disparity
		|| abs(curr_pos.y - new_pos.y) > update_movement_max_disparity):
		print("Forcibly updating position - CURR: ", curr_pos, " != NEW: ", new_pos)
#		set_translation(new_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	player_command()

func _input(event):
	# Client Relative Inputs
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)
