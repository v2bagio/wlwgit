# MultiplayerMenu.gd - Menu para opções de multiplayer
extends Control

signal back_to_main_menu

@onready var local_battle_button = $VBoxContainer/LocalBattleButton
@onready var host_game_button = $VBoxContainer/HostGameButton
@onready var join_game_button = $VBoxContainer/JoinGameButton
@onready var search_online_button = $VBoxContainer/SearchOnlineButton
@onready var back_button = $VBoxContainer/BackButton

@onready var join_dialog = $JoinDialog
@onready var ip_input = $JoinDialog/VBoxContainer/IPInput
@onready var port_input = $JoinDialog/VBoxContainer/PortInput
@onready var connect_button = $JoinDialog/VBoxContainer/ConnectButton
@onready var cancel_button = $JoinDialog/VBoxContainer/CancelButton

@onready var status_label = $StatusLabel
@onready var searching_dialog = $SearchingDialog
@onready var cancel_search_button = $SearchingDialog/VBoxContainer/CancelSearchButton

var multiplayer_manager: Node

func _ready():
	# Obter referência ao MultiplayerManager
	multiplayer_manager = get_node("/root/MultiplayerManager")
	if not multiplayer_manager:
		printerr("MultiplayerMenu: MultiplayerManager não encontrado!")
		return
	
	# Conectar botões
	local_battle_button.pressed.connect(_on_local_battle_pressed)
	host_game_button.pressed.connect(_on_host_game_pressed)
	join_game_button.pressed.connect(_on_join_game_pressed)
	search_online_button.pressed.connect(_on_search_online_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	connect_button.pressed.connect(_on_connect_pressed)
	cancel_button.pressed.connect(_on_cancel_join_pressed)
	cancel_search_button.pressed.connect(_on_cancel_search_pressed)
	
	# Conectar sinais do multiplayer
	multiplayer_manager.player_connected.connect(_on_player_connected)
	multiplayer_manager.match_found.connect(_on_match_found)
	
	# Configurar valores padrão
	ip_input.text = "127.0.0.1"
	port_input.text = "7000"
	
	update_status("Pronto para jogar")

func _on_local_battle_pressed():
	"""Inicia batalha local (modo original)"""
	print("MultiplayerMenu: Iniciando batalha local")
	get_tree().change_scene_to_file("res://BattleScene.tscn")

func _on_host_game_pressed():
	"""Hospeda um jogo para outro jogador se conectar"""
	print("MultiplayerMenu: Hospedando jogo")
	update_status("Iniciando servidor...")
	
	var success = multiplayer_manager.start_server()
	if success:
		update_status("Servidor iniciado. Aguardando jogador...")
		disable_menu_buttons(true)
	else:
		update_status("Erro ao iniciar servidor!")

func _on_join_game_pressed():
	"""Mostra dialog para conectar a um jogo"""
	print("MultiplayerMenu: Abrindo dialog de conexão")
	join_dialog.popup_centered()

func _on_search_online_pressed():
	"""Busca partida online (simulação)"""
	print("MultiplayerMenu: Buscando partida online")
	update_status("Buscando partida online...")
	searching_dialog.popup_centered()
	disable_menu_buttons(true)
	
	multiplayer_manager.search_online_match()

func _on_back_pressed():
	"""Volta ao menu principal"""
	print("MultiplayerMenu: Voltando ao menu principal")
	emit_signal("back_to_main_menu")

func _on_connect_pressed():
	"""Conecta ao servidor especificado"""
	var ip = ip_input.text.strip_edges()
	var port = int(port_input.text.strip_edges())
	
	if ip.is_empty():
		update_status("IP inválido!")
		return
	
	if port <= 0 or port > 65535:
		update_status("Porta inválida!")
		return
	
	print("MultiplayerMenu: Conectando a ", ip, ":", port)
	join_dialog.hide()
	update_status("Conectando...")
	disable_menu_buttons(true)
	
	var success = multiplayer_manager.connect_to_server(ip, port)
	if not success:
		update_status("Erro ao conectar!")
		disable_menu_buttons(false)

func _on_cancel_join_pressed():
	"""Cancela dialog de conexão"""
	join_dialog.hide()

func _on_cancel_search_pressed():
	"""Cancela busca de partida"""
	print("MultiplayerMenu: Cancelando busca de partida")
	searching_dialog.hide()
	multiplayer_manager.cancel_match_search()
	update_status("Busca cancelada")
	disable_menu_buttons(false)

func _on_player_connected(player_id: int):
	"""Callback quando um jogador conecta"""
	print("MultiplayerMenu: Jogador conectado: ", player_id)
	update_status("Jogador conectado! Iniciando partida...")
	
	# Aguardar um momento e iniciar a batalha
	await get_tree().create_timer(1.0).timeout
	start_networked_battle()

func _on_match_found(opponent_id: int):
	"""Callback quando uma partida é encontrada"""
	print("MultiplayerMenu: Partida encontrada com oponente: ", opponent_id)
	searching_dialog.hide()
	update_status("Partida encontrada! Iniciando...")
	
	# Aguardar um momento e iniciar a batalha
	await get_tree().create_timer(1.0).timeout
	start_networked_battle()

func start_networked_battle():
	"""Inicia a batalha em rede"""
	print("MultiplayerMenu: Iniciando batalha em rede")
	
	# Verificar se há cartas suficientes na coleção
	var collection = PlayerCollection.get_collection()
	if collection.size() < 5:
		update_status("Coleção insuficiente! Mínimo 5 cartas.")
		disable_menu_buttons(false)
		return
	
	# Carregar a cena de batalha em rede
	get_tree().change_scene_to_file("res://NetworkedBattleScene.tscn")

func update_status(message: String):
	"""Atualiza o texto de status"""
	status_label.text = "Status: " + message
	print("MultiplayerMenu: Status - ", message)

func disable_menu_buttons(disabled: bool):
	"""Habilita/desabilita botões do menu"""
	local_battle_button.disabled = disabled
	host_game_button.disabled = disabled
	join_game_button.disabled = disabled
	search_online_button.disabled = disabled

func _on_connection_failed():
	"""Callback quando falha ao conectar"""
	update_status("Falha na conexão!")
	disable_menu_buttons(false)

func _on_server_disconnected():
	"""Callback quando servidor desconecta"""
	update_status("Servidor desconectado!")
	disable_menu_buttons(false)

