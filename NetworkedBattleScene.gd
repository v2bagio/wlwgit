# NetworkedBattleScene.gd - Versão Multiplayer da BattleScene
extends "res://BattleScene.gd"

# Referência ao sistema de multiplayer
var multiplayer_manager: Node

# Estados específicos do multiplayer
var waiting_for_opponent: bool = false
var opponent_ready: bool = false
var local_player_ready: bool = false

# Dados do oponente
var opponent_deck: Array = []
var opponent_current_card: Card = null
var opponent_used_cards: Array = []

func _ready():
	super._ready()
	
	# Obter referência ao MultiplayerManager
	multiplayer_manager = get_node("/root/MultiplayerManager")
	if not multiplayer_manager:
		printerr("NetworkedBattleScene: MultiplayerManager não encontrado!")
		return
	
	# Conectar sinais do multiplayer
	multiplayer_manager.match_data_received.connect(_on_match_data_received)
	multiplayer_manager.player_disconnected.connect(_on_player_disconnected)
	
	print("NetworkedBattleScene: Inicializada para multiplayer")

func start_battle_setup():
	"""Inicia a configuração da batalha multiplayer"""
	print("NetworkedBattleScene: Iniciando setup da batalha multiplayer.")
	current_state = GameState.SETUP
	
	if multiplayer_manager.is_multiplayer_active():
		setup_multiplayer_decks()
	else:
		# Fallback para modo local
		super.start_battle_setup()

func setup_multiplayer_decks():
	"""Configura os decks para multiplayer"""
	print("NetworkedBattleScene: Configurando decks multiplayer.")
	
	# Deck do jogador local vem da sua coleção
	var local_collection = PlayerCollection.get_collection()
	if local_collection.size() >= 5:
		local_collection.shuffle()
		player1_deck = local_collection.slice(0, 5)
	else:
		printerr("NetworkedBattleScene: Coleção local insuficiente, usando fallback")
		_generate_random_decks_fallback()
		return
	
	# Deck do oponente vem via rede
	opponent_deck = multiplayer_manager.get_opponent_deck()
	if opponent_deck.size() >= 5:
		player2_deck = opponent_deck.slice(0, 5)
	else:
		print("NetworkedBattleScene: Aguardando deck do oponente...")
		waiting_for_opponent = true
		show_waiting_message("Aguardando oponente...")
		return
	
	print("NetworkedBattleScene: Decks configurados. Iniciando fase de banimento.")
	transition_to_banning_phase()

func show_waiting_message(message: String):
	"""Mostra mensagem de espera"""
	var waiting_popup = AcceptDialog.new()
	waiting_popup.dialog_text = message
	waiting_popup.title = "Aguardando..."
	add_child(waiting_popup)
	waiting_popup.popup_centered()
	
	# Auto-fechar após 5 segundos se ainda estiver esperando
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(waiting_popup):
		waiting_popup.queue_free()

func process_card_selection(card_data: Dictionary):
	"""Processa a seleção de carta em modo multiplayer"""
	print("NetworkedBattleScene: Processando seleção de carta multiplayer para Jogador ", current_player)
	
	if current_player == multiplayer_manager.get_local_player_id():
		# Jogador local selecionou carta
		if current_player == 1:
			player1_current_card = create_card_from_data(card_data)
			player1_used_cards.append(card_data)
			display_player_card(player1_current_card, player1_area)
		else:
			player2_current_card = create_card_from_data(card_data)
			player2_used_cards.append(card_data)
			display_player_card(player2_current_card, player2_area)
		
		# Enviar seleção para o oponente
		multiplayer_manager.send_card_selection.rpc(card_data)
		
		# Aguardar seleção do oponente
		waiting_for_opponent = true
		show_waiting_message("Aguardando seleção do oponente...")
	
	# Verificar se ambos os jogadores selecionaram
	if player1_current_card and player2_current_card:
		waiting_for_opponent = false
		transition_to_battle_round()

func execute_battle_round(characteristic: String):
	"""Executa a rodada de batalha em modo multiplayer"""
	print("NetworkedBattleScene: Executando rodada multiplayer com característica: ", characteristic)
	
	# Enviar característica selecionada para o oponente
	multiplayer_manager.send_characteristic_selection.rpc(characteristic)
	
	# Executar batalha normalmente
	super.execute_battle_round(characteristic)
	
	# Sincronizar estado da partida
	var match_state = {
		"round": current_round,
		"player1_wins": player1_wins,
		"player2_wins": player2_wins,
		"characteristic": characteristic
	}
	multiplayer_manager.sync_match_state.rpc(match_state)

func _on_match_data_received(data: Dictionary):
	"""Callback para dados recebidos via rede"""
	var data_type = data.get("type", "")
	var payload = data.get("data", {})
	
	print("NetworkedBattleScene: Dados recebidos - Tipo: ", data_type)
	
	match data_type:
		"battle_deck":
			opponent_deck = payload
			if waiting_for_opponent and opponent_deck.size() >= 5:
				player2_deck = opponent_deck.slice(0, 5)
				waiting_for_opponent = false
				transition_to_banning_phase()
		
		"card_selection":
			# Oponente selecionou carta
			if current_player != multiplayer_manager.get_local_player_id():
				if current_player == 1:
					player1_current_card = create_card_from_data(payload)
					player1_used_cards.append(payload)
					display_player_card(player1_current_card, player1_area)
				else:
					player2_current_card = create_card_from_data(payload)
					player2_used_cards.append(payload)
					display_player_card(player2_current_card, player2_area)
			
			# Verificar se ambos selecionaram
			if player1_current_card and player2_current_card:
				waiting_for_opponent = false
				transition_to_battle_round()
		
		"characteristic_selection":
			# Oponente selecionou característica
			if current_player != multiplayer_manager.get_local_player_id():
				execute_battle_round(payload)
		
		"characteristic_bans":
			# Processar banimentos do oponente
			var opponent_bans = payload
			print("NetworkedBattleScene: Banimentos do oponente recebidos: ", opponent_bans)
		
		"match_state":
			# Sincronizar estado da partida
			var state = payload
			current_round = state.get("round", current_round)
			player1_wins = state.get("player1_wins", player1_wins)
			player2_wins = state.get("player2_wins", player2_wins)
			update_score_display()

func _on_player_disconnected(player_id: int):
	"""Callback quando um jogador desconecta"""
	print("NetworkedBattleScene: Jogador ", player_id, " desconectou")
	
	if player_id == multiplayer_manager.get_opponent_player_id():
		# Oponente desconectou
		var disconnect_popup = AcceptDialog.new()
		disconnect_popup.dialog_text = "O oponente desconectou. Você venceu por W.O."
		disconnect_popup.title = "Oponente Desconectado"
		add_child(disconnect_popup)
		disconnect_popup.popup_centered()
		
		disconnect_popup.confirmed.connect(func():
			disconnect_popup.queue_free()
			_on_back_to_menu_pressed()
		)

func show_card_selection_interface():
	"""Mostra interface de seleção apenas para o jogador local"""
	if current_player == multiplayer_manager.get_local_player_id():
		super.show_card_selection_interface()
	else:
		# Aguardar seleção do oponente
		waiting_for_opponent = true
		show_waiting_message("Aguardando seleção do oponente...")

func show_characteristic_selection():
	"""Mostra seleção de característica apenas para o jogador 1"""
	if multiplayer_manager.get_local_player_id() == 1:
		super.show_characteristic_selection()
	else:
		# Jogador 2 aguarda seleção do jogador 1
		waiting_for_opponent = true
		show_waiting_message("Aguardando seleção de característica...")

# Função para inicializar batalha multiplayer
func initialize_multiplayer_battle():
	"""Inicializa a batalha em modo multiplayer"""
	print("NetworkedBattleScene: Inicializando batalha multiplayer")
	
	if not multiplayer_manager.is_multiplayer_active():
		printerr("NetworkedBattleScene: Multiplayer não está ativo!")
		return false
	
	# Enviar deck para o oponente
	var local_deck = PlayerCollection.get_collection()
	if local_deck.size() >= 5:
		local_deck.shuffle()
		var battle_deck = local_deck.slice(0, 5)
		multiplayer_manager.send_battle_deck.rpc(battle_deck)
	
	start_battle_setup()
	return true

