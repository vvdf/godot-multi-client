extends Spatial

const DEFAULT_ADDR = "192.168.1.56" # target IP Address
const DEFAULT_PORT = 3000 # target port
var players = {}
var player_name =  "Client"
var owner_id = 0
onready var ui_player_count = $UI/PlayerCount
onready var debug_client_pos = $DebugUI/ClientPos
onready var debug_server_pos = $DebugUI/ServerPos

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
	if id == get_tree().get_network_unique_id():
		var player_scene = load("res://PlayerMain.tscn")
		var player = player_scene.instance()
		player.set_name(str(id))

		# Adding player scene instance to client's main scene tree
		add_child(player) 
		
		player.set_network_master(id)
		player.player_id = id
		owner_id = id
	else:
		var player_scene = load("res://Player.tscn")
		var player = player_scene.instance()
	
		player.set_name(str(id))
	
		# Adding player scene instance to client's main scene tree
		add_child(player) 

func update_server(new_pos, new_facing, id):
	rpc_unreliable_id(1, "update_pos_server", new_pos, new_facing, id)
	
# probably want to validate this so that it can only accept calls by the server
remote func update_pos_client(new_pos, new_facing, player_id):
	if players.has(player_id):
		var player_node = get_node(str(player_id))
		
		if player_id == owner_id:
			player_node.check_for_client_move(new_pos)
		else:
			player_node.set_translation(new_pos)
			player_node.rotation_degrees.y = new_facing

func debug_pos(client_pos, server_pos):
	debug_client_pos.set_text(String(client_pos))
	debug_server_pos.set_text(String(server_pos))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ui_player_count.set_text(String(players.size()))
