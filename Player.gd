extends Spatial

var player_id = 0
var control = false
var pos = Vector3(3, 1, 3)
var MOVE_SPEED = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_translation(Vector3(pos.x, 1, pos.y))

func player_input():
	var movement = Vector3(0, 0, 0)
	var movement_attempted = false
	if Input.is_action_pressed("ui_left"):
		movement.x -= MOVE_SPEED
		movement_attempted = true
	if Input.is_action_pressed("ui_right"):
		movement.x += MOVE_SPEED
		movement_attempted = true
	if Input.is_action_pressed("ui_up"):
		movement.z -= MOVE_SPEED
		movement_attempted = true
	if Input.is_action_pressed("ui_down"):
		movement.z += MOVE_SPEED
		movement_attempted = true
	
	# only send movements when movements are attempted
	# so as not to flood the network with 0s
	if movement_attempted:
		get_parent().update(movement, player_id)
#	rpc_unreliable("update_pos_server", movement, player_id)
	
#remote func update_pos_client(new_pos, player_id):
#	print("UPDATING POSITION OF PLAYER ID# ", player_id)
#	var player_node = get_node(str(player_id))
#
#	player_node.set_translation(new_pos)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if control == true:
		player_input()
	else:
		pass
