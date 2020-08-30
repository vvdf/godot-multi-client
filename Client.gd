extends Spatial

const DEFAULT_ADDR = "192.168.1.56" # target IP Address
const DEFAULT_PORT = 3000 # target port
var players = {}
var player_name =  "Client"

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	join_server()
	
	
func join_server():
	print("Attempting to join server")
	player_name = "Client"
	var host = NetworkedMultiplayerENet.new()
	
	var err = host.create_client(DEFAULT_ADDR, DEFAULT_PORT)
	if err != OK:
		print(err)
		
	get_tree().set_network_peer(host)
	print("Server joined")
	
func _player_connected(id):
	print("Player connected to ", DEFAULT_ADDR, " : ", DEFAULT_PORT)
	
func _connected_ok():
	print("Connection OK")
	rpc_id(1, "register_player_server", get_tree().get_network_unique_id(), player_name)
	
func _connected_fail():
	print("Connection FAILURE")

remote func register_player_client(id, name):
	print("Register Player ID# ", id, " ", name)
	players[id] = name
	spawn_player(id)
	print("Player Registered Successfully!")

func spawn_player(id):
	print("Attempt Spawn Player for ID# ", id)
	var player_scene = load("res://Player.tscn")
	var player = player_scene.instance()
	
	player.set_name(str(id))
	
	# Adding player scene instance to client's main scene tree
	add_child(player) 
	
	if id == get_tree().get_network_unique_id():
		player.set_network_master(id)
		player.player_id = id
		player.control = true

func update(movement, id):
	rpc_unreliable_id(1, "update_pos_server", movement, id)
	
remote func update_pos_client(new_pos, player_id):
	if players.has(player_id):
		var player_node = get_node(str(player_id))
		player_node.set_translation(new_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	rpc("print_something")
