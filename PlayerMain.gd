extends KinematicBody

var update_movement_max_disparity = 1
var player_id = 0
var player_angle = 0
var mouse_sensitivity = 0.3
var min_pitch = -90
var max_pitch = 90

var speed = 25

onready var camera_pivot = $CameraPivot
onready var camera = $CameraPivot/CameraBoom/Camera
onready var model = $PlayerModel

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_translation(Vector3(0, 0, 0))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func player_command():
	var direction = Vector3(0, 0, 0)
	var movement_attempted = false
	
	# Server Relative Inputs
	if Input.is_action_pressed("move_forward"):
		direction -= camera_pivot.get_transform().basis.z
		update_facing(camera_pivot.rotation_degrees.y)
		movement_attempted = true
	if Input.is_action_pressed("move_backward"):
		direction += camera_pivot.get_transform().basis.z
		update_facing(camera_pivot.rotation_degrees.y + 180)
		movement_attempted = true
	if Input.is_action_pressed("move_left"):
		direction -= camera_pivot.get_transform().basis.x
		update_facing(camera_pivot.rotation_degrees.y + 90)
		movement_attempted = true
	if Input.is_action_pressed("move_right"):
		direction += camera_pivot.get_transform().basis.x
		update_facing(camera_pivot.rotation_degrees.y - 90)
		movement_attempted = true
	if Input.is_action_pressed("ui_home"):
		print("Camera Facing: ", camera_pivot.rotation_degrees.y)
	
	direction.y = 0 # prevent flying from use of get_transform().basis catching y vector
	
	move_and_slide(direction.normalized() * speed)

	# only send attempted updated position when movements are attempted
	# so as not to flood the network with 0s
	if movement_attempted:
		get_parent().update_server(get_translation(), player_angle, player_id)
		
# Function for client to run to determine if we need to update current position
# to catch up/be accurate with server
func check_for_client_move(new_pos):
	var curr_pos = get_translation()
	get_parent().debug_pos(curr_pos, new_pos)
	if (abs(curr_pos.x - new_pos.x) > update_movement_max_disparity
		|| abs(curr_pos.z - new_pos.z) > update_movement_max_disparity
		|| abs(curr_pos.y - new_pos.y) > update_movement_max_disparity):
		set_translation(new_pos)
		
func update_facing(new_angle):
	model.rotation_degrees.y = new_angle
	player_angle = new_angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	player_command()

func _input(event):
	# Client Specific Inputs
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion:
		camera_pivot.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation_degrees.y = fmod(camera_pivot.rotation_degrees.y, 360) # prevent value climb
		camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)
