# MainPage.gd

extends Control

func _ready():
	$VBoxContainer/ConnectServerButton.pressed.connect(_on_connect_server_button_pressed)

func _on_connect_server_button_pressed():
	var ip = $VBoxContainer/IPAddressInput.text
	var port = 7000  # Defina a porta desejada ou permita que o usuário insira
	join_game(ip, port)

func join_game(address, port):
	if address == "":
		address = "127.0.0.1"
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		print("Falha ao conectar ao servidor: %s" % error)
		return
	multiplayer.multiplayer_peer = peer

	# Conectando sinais de rede
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	print("Tentando conectar ao servidor...")

var players = {}
var player_info = {"name": "Cliente"}

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	emit_signal("player_connected", peer_id, player_info)
	print("Conexão com o servidor estabelecida")

func _on_connected_fail():
	multiplayer.multiplayer_peer = null
	print("Falha na conexão com o servidor")

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	print("Desconectado do servidor")

func _on_player_connected(id):
	rpc_id(id, "_register_player", player_info)

@rpc("reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	print("Jogador conectado: %s" % new_player_info)

func _on_player_disconnected(id):
	players.erase(id)
	print("Jogador desconectado: %s" % id)
