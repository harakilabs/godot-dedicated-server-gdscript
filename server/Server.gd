extends Node

# Sinais para gerenciamento de jogadores
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7000
const MAX_CONNECTIONS = 20

var players = {}
var player_info = {"name": "Servidor"}
var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error != OK:
		print("Erro ao iniciar o servidor: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer

	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	emit_signal("player_connected", peer_id, player_info)

func _on_player_connected(id):
	rpc_id(id, "_register_player", player_info)

@rpc("reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	emit_signal("player_connected", new_player_id, new_player_info)

func _on_player_disconnected(id):
	players.erase(id)
	emit_signal("player_disconnected", id)

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	emit_signal("server_disconnected")

@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)

@rpc("call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$"/root/Game".start_game()
			players_loaded = 0
