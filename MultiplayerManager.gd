# MultiplayerManager.gd - Sistema de Multiplayer para o jogo de cartas
extends Node

signal player_connected(player_id: int)
signal player_disconnected(player_id: int)
signal match_found(opponent_id: int)
signal match_data_received(data: Dictionary)

const DEFAULT_PORT = 7000
const MAX_CLIENTS = 2

var multiplayer_peer: MultiplayerPeer
var is_server: bool = false
var is_client: bool = false
var local_player_id: int = 0
var opponent_id: int = 0
var server_url: String = ""
var is_searching_match: bool = false

# Dados do jogador local
var local_player_data: Dictionary = {}
var opponent_player_data: Dictionary = {}

func _ready():
	# Conectar sinais do multiplayer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Função para iniciar como servidor (para testes locais)
func start_server(port: int = DEFAULT_PORT) -> bool:
	print("MultiplayerManager: Iniciando servidor na porta ", port)
	
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_server(port, MAX_CLIENTS)
	
	if error != OK:
		printerr("MultiplayerManager: Erro ao criar servidor: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	is_server = true
	local_player_id = 1
	
	print("MultiplayerManager: Servidor iniciado com sucesso. Player ID: ", local_player_id)
	return true

# Função para conectar como cliente
func connect_to_server(ip: String, port: int = DEFAULT_PORT) -> bool:
	print("MultiplayerManager: Conectando ao servidor ", ip, ":", port)
	
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_client(ip, port)
	
	if error != OK:
		printerr("MultiplayerManager: Erro ao conectar ao servidor: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	is_client = true
	server_url = ip + ":" + str(port)
	
	print("MultiplayerManager: Tentando conectar ao servidor...")
	return true

# Função para buscar partida online (simulação)
func search_online_match():
	print("MultiplayerManager: Buscando partida online...")
	is_searching_match = true
	
	# Para implementação futura com servidor dedicado
	# Por enquanto, simula encontrar uma partida após alguns segundos
	await get_tree().create_timer(2.0).timeout
	
	if is_searching_match:
		# Simula encontrar um oponente
		opponent_id = 2 if local_player_id == 1 else 1
		is_searching_match = false
		emit_signal("match_found", opponent_id)
		print("MultiplayerManager: Partida encontrada! Oponente ID: ", opponent_id)

# Função para cancelar busca de partida
func cancel_match_search():
	print("MultiplayerManager: Cancelando busca de partida...")
	is_searching_match = false

# Função para enviar dados da coleção do jogador
@rpc("any_peer", "call_local", "reliable")
func send_player_collection(collection_data: Array):
	var sender_id = multiplayer.get_remote_sender_id()
	print("MultiplayerManager: Recebendo coleção do jogador ", sender_id)
	
	if sender_id != local_player_id:
		opponent_player_data["collection"] = collection_data
		print("MultiplayerManager: Coleção do oponente recebida. ", collection_data.size(), " cartas.")

# Função para enviar deck selecionado para a batalha
@rpc("any_peer", "call_local", "reliable")
func send_battle_deck(deck_data: Array):
	var sender_id = multiplayer.get_remote_sender_id()
	print("MultiplayerManager: Recebendo deck de batalha do jogador ", sender_id)
	
	if sender_id != local_player_id:
		opponent_player_data["battle_deck"] = deck_data
		emit_signal("match_data_received", {"type": "battle_deck", "data": deck_data})

# Função para enviar carta selecionada na rodada
@rpc("any_peer", "call_local", "reliable")
func send_card_selection(card_data: Dictionary):
	var sender_id = multiplayer.get_remote_sender_id()
	print("MultiplayerManager: Recebendo seleção de carta do jogador ", sender_id)
	
	if sender_id != local_player_id:
		emit_signal("match_data_received", {"type": "card_selection", "data": card_data})

# Função para enviar característica selecionada
@rpc("any_peer", "call_local", "reliable")
func send_characteristic_selection(characteristic: String):
	var sender_id = multiplayer.get_remote_sender_id()
	print("MultiplayerManager: Recebendo seleção de característica do jogador ", sender_id)
	
	if sender_id != local_player_id:
		emit_signal("match_data_received", {"type": "characteristic_selection", "data": characteristic})

# Função para enviar banimentos de características
@rpc("any_peer", "call_local", "reliable")
func send_characteristic_bans(bans: Array):
	var sender_id = multiplayer.get_remote_sender_id()
	print("MultiplayerManager: Recebendo banimentos do jogador ", sender_id)
	
	if sender_id != local_player_id:
		emit_signal("match_data_received", {"type": "characteristic_bans", "data": bans})

# Função para sincronizar estado da partida
@rpc("any_peer", "call_local", "reliable")
func sync_match_state(state_data: Dictionary):
	var sender_id = multiplayer.get_remote_sender_id()
	print("MultiplayerManager: Sincronizando estado da partida do jogador ", sender_id)
	
	if sender_id != local_player_id:
		emit_signal("match_data_received", {"type": "match_state", "data": state_data})

# Função para desconectar
func disconnect_from_match():
	print("MultiplayerManager: Desconectando da partida...")
	
	if multiplayer_peer:
		multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	is_server = false
	is_client = false
	local_player_id = 0
	opponent_id = 0
	is_searching_match = false
	local_player_data.clear()
	opponent_player_data.clear()

# Callbacks de eventos de rede
func _on_peer_connected(id: int):
	print("MultiplayerManager: Jogador conectado: ", id)
	emit_signal("player_connected", id)
	
	if is_server and id != 1:
		opponent_id = id
		# Enviar dados da coleção local para o novo jogador
		send_player_collection.rpc_id(id, PlayerCollection.get_collection())

func _on_peer_disconnected(id: int):
	print("MultiplayerManager: Jogador desconectado: ", id)
	emit_signal("player_disconnected", id)
	
	if id == opponent_id:
		opponent_id = 0
		opponent_player_data.clear()

func _on_connected_to_server():
	print("MultiplayerManager: Conectado ao servidor com sucesso!")
	local_player_id = multiplayer.get_unique_id()
	print("MultiplayerManager: Player ID atribuído: ", local_player_id)
	
	# Enviar coleção para o servidor
	send_player_collection.rpc(PlayerCollection.get_collection())

func _on_connection_failed():
	printerr("MultiplayerManager: Falha ao conectar ao servidor!")
	is_client = false

func _on_server_disconnected():
	print("MultiplayerManager: Servidor desconectado!")
	disconnect_from_match()

# Funções auxiliares para integração com BattleScene
func get_opponent_collection() -> Array:
	return opponent_player_data.get("collection", [])

func get_opponent_deck() -> Array:
	return opponent_player_data.get("battle_deck", [])

func is_multiplayer_active() -> bool:
	return is_server or is_client

func get_local_player_id() -> int:
	return local_player_id

func get_opponent_player_id() -> int:
	return opponent_id

# Função para inicializar dados do jogador local
func initialize_local_player():
	local_player_data["collection"] = PlayerCollection.get_collection()
	local_player_data["player_id"] = local_player_id
	print("MultiplayerManager: Dados do jogador local inicializados.")

