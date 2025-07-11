# BattleScene.gd - Cena principal de batalha SuperTrunfo
extends Control

signal battle_finished(winner_id: int)

const CardScene = preload("res://Card.tscn")
const CharBan = preload("res://CharacteristicBanSystem.tscn")

# Enums para estados do jogo
enum GameState {
	SETUP,
	BANNING_PHASE,
	CARD_SELECTION,
	BATTLE_ROUND,
	ROUND_RESULT,
	MATCH_RESULT
}

enum BattleFormat {
	CLASSIC,
	BLITZ,
	SURVIVAL,
	DRAFT
}

# Características disponíveis para banimento
const CHARACTERISTICS = ["altura", "comprimento", "velocidade", "peso"]
const CHARACTERISTIC_NAMES = {
	"altura": "Altura",
	"comprimento": "Comprimento", 
	"velocidade": "Velocidade",
	"peso": "Peso"
}

# Nós da interface
@onready var player1_area = $PlayerAreas/Player1Area
@onready var player2_area = $PlayerAreas/Player2Area
@onready var battle_info = $BattleInfo
@onready var round_counter = $BattleInfo/RoundCounter
@onready var score_display = $BattleInfo/ScoreDisplay
@onready var characteristic_selector = $CharacteristicSelector
@onready var banned_characteristics_display = $BannedCharacteristics
@onready var battle_result_popup = $BattleResultPopup
@onready var back_to_menu_button = $BackToMenuButton
@onready var mainmenu = preload("res://Menu.tscn")

# Variáveis de estado do jogo
var current_state: GameState = GameState.SETUP
var battle_format: BattleFormat = BattleFormat.CLASSIC
var current_round: int = 1
var max_rounds: int = 3
var player1_wins: int = 0
var player2_wins: int = 0
var current_player: int = 1
var active_characteristics: Array = CHARACTERISTICS.duplicate()
var banned_characteristics: Array = []

# Dados dos jogadores
var player1_deck: Array = []
var player2_deck: Array = []
var player1_current_card: Card = null
var player2_current_card: Card = null
var player1_used_cards: Array = []
var player2_used_cards: Array = []

# Banimento de características
var player1_bans: Array = []
var player2_bans: Array = []
var system_ban: String = ""

func _ready():
	setup_ui()
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	_on_back_to_menu_pressed()
	start_battle_setup()

func setup_ui():
	"""Configura a interface inicial da batalha"""
	round_counter.text = "Rodada: %d/%d" % [current_round, max_rounds]
	score_display.text = "Jogador 1: %d - Jogador 2: %d" % [player1_wins, player2_wins]
	
	# Configurar áreas dos jogadores
	_setup_player_area(player1_area, "Jogador 1")
	_setup_player_area(player2_area, "Jogador 2")

func _setup_player_area(area: Control, player_name: String):
	"""Configura a área de um jogador"""
	var name_label = area.get_node("PlayerName")
	name_label.text = player_name
	
	var card_slot = area.get_node("CardSlot")
	card_slot.custom_minimum_size = Vector2(190, 280)

func start_battle_setup():
	"""Inicia a configuração da batalha"""
	current_state = GameState.SETUP
	generate_player_decks()
	transition_to_banning_phase()

func generate_player_decks():
	"""Gera os decks dos jogadores com cartas aleatórias"""
	player1_deck.clear()
	player2_deck.clear()
	
	# Gerar 5 cartas para cada jogador
	for i in range(5):
		var animal_id1 = CardPoolManager.get_random_animal_id()
		var animal_id2 = CardPoolManager.get_random_animal_id()
		
		var card_data1 = create_card_data(animal_id1)
		var card_data2 = create_card_data(animal_id2)
		
		player1_deck.append(card_data1)
		player2_deck.append(card_data2)

func create_card_data(animal_id: String) -> Dictionary:
	"""Cria dados de carta baseados no animal"""
	var animal_data = AnimalDatabase.get_animal_data(animal_id)
	if animal_data.is_empty():
		return {}
	
	var card = CardScene.instantiate() as Card
	card.setup(animal_id, false, false, false)
	var card_data = card.get_card_data()
	card.queue_free()
	
	return card_data

func transition_to_banning_phase():
	"""Transição para a fase de banimento de características"""
	current_state = GameState.BANNING_PHASE
	show_banning_interface()

func show_banning_interface():
	"""Mostra a interface de banimento de características"""
	var banning_popup = create_banning_popup()
	get_tree().change_scene_to_file("res://CharacteristicBanSystem.tscn")
	add_child(banning_popup)

func create_banning_popup() -> Control:
	"""Cria o popup de banimento de características"""
	var popup = AcceptDialog.new()
	popup.title = "Fase de Banimento - Jogador %d" % current_player
	popup.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var instruction = Label.new()
	instruction.text = "Selecione 2 características para banir:"
	vbox.add_child(instruction)
	
	var characteristics_container = VBoxContainer.new()
	vbox.add_child(characteristics_container)
	
	var selected_bans = []
	
	for characteristic in CHARACTERISTICS:
		var checkbox = CheckBox.new()
		checkbox.text = CHARACTERISTIC_NAMES[characteristic]
		checkbox.toggled.connect(func(pressed: bool):
			if pressed and selected_bans.size() < 2:
				selected_bans.append(characteristic)
			elif not pressed:
				selected_bans.erase(characteristic)
			
			# Desabilitar outras checkboxes se já temos 2 selecionadas
			for child in characteristics_container.get_children():
				if child is CheckBox and not child.button_pressed:
					child.disabled = selected_bans.size() >= 2
		)
		characteristics_container.add_child(checkbox)
	
	var confirm_button = Button.new()
	confirm_button.text = "Confirmar Banimentos"
	confirm_button.pressed.connect(func():
		if selected_bans.size() == 2:
			process_player_bans(selected_bans)
			popup.queue_free()
	)
	vbox.add_child(confirm_button)
	
	return popup

func process_player_bans(bans: Array):
	"""Processa os banimentos de um jogador"""
	if current_player == 1:
		player1_bans = bans.duplicate()
		current_player = 2
		show_banning_interface()
	else:
		player2_bans = bans.duplicate()
		process_system_ban()
		finalize_banning_phase()

func process_system_ban():
	"""Processa o banimento aleatório do sistema"""
	var available_for_system_ban = []
	
	for characteristic in CHARACTERISTICS:
		if characteristic not in player1_bans and characteristic not in player2_bans:
			available_for_system_ban.append(characteristic)
	
	if not available_for_system_ban.is_empty():
		system_ban = available_for_system_ban.pick_random()
	
	# Atualizar características ativas
	banned_characteristics = player1_bans + player2_bans + [system_ban]
	active_characteristics.clear()
	
	for characteristic in CHARACTERISTICS:
		if characteristic not in banned_characteristics:
			active_characteristics.append(characteristic)

func finalize_banning_phase():
	"""Finaliza a fase de banimento e mostra o resultado"""
	update_banned_characteristics_display()
	transition_to_card_selection()

func update_banned_characteristics_display():
	"""Atualiza a exibição das características banidas"""
	var display_text = "Características Banidas:\n"
	display_text += "Jogador 1: %s\n" % ", ".join(player1_bans.map(func(c): return CHARACTERISTIC_NAMES[c]))
	display_text += "Jogador 2: %s\n" % ", ".join(player2_bans.map(func(c): return CHARACTERISTIC_NAMES[c]))
	display_text += "Sistema: %s\n" % CHARACTERISTIC_NAMES.get(system_ban, "Nenhuma")
	display_text += "\nCaracterísticas Ativas: %s" % ", ".join(active_characteristics.map(func(c): return CHARACTERISTIC_NAMES[c]))
	
	banned_characteristics_display.text = display_text

func transition_to_card_selection():
	"""Transição para a seleção de cartas"""
	current_state = GameState.CARD_SELECTION
	current_player = 1
	show_card_selection_interface()

func show_card_selection_interface():
	"""Mostra a interface de seleção de cartas"""
	var selection_popup = create_card_selection_popup()
	add_child(selection_popup)

func create_card_selection_popup() -> Control:
	"""Cria o popup de seleção de cartas"""
	var popup = AcceptDialog.new()
	popup.title = "Seleção de Carta - Jogador %d" % current_player
	popup.size = Vector2(800, 600)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var instruction = Label.new()
	instruction.text = "Selecione uma carta para a rodada %d:" % current_round
	vbox.add_child(instruction)
	
	var cards_container = HBoxContainer.new()
	vbox.add_child(cards_container)
	
	var player_deck = player1_deck if current_player == 1 else player2_deck
	var used_cards = player1_used_cards if current_player == 1 else player2_used_cards
	
	var selected_card_data = null
	
	for card_data in player_deck:
		if card_data in used_cards:
			continue
			
		var card = CardScene.instantiate() as Card
		cards_container.add_child(card)
		card.display_card_data(card_data)
		card.is_face_up = true
		card.update_visibility()
		
		var button = Button.new()
		button.text = "Selecionar"
		button.pressed.connect(func():
			selected_card_data = card_data
			process_card_selection(selected_card_data)
			popup.queue_free()
		)
		card.add_child(button)
	
	return popup

func process_card_selection(card_data: Dictionary):
	"""Processa a seleção de carta de um jogador"""
	if current_player == 1:
		player1_current_card = create_card_from_data(card_data)
		player1_used_cards.append(card_data)
		display_player_card(player1_current_card, player1_area)
		current_player = 2
		show_card_selection_interface()
	else:
		player2_current_card = create_card_from_data(card_data)
		player2_used_cards.append(card_data)
		display_player_card(player2_current_card, player2_area)
		transition_to_battle_round()

func create_card_from_data(card_data: Dictionary) -> Card:
	"""Cria uma instância de carta a partir dos dados"""
	var card = CardScene.instantiate() as Card
	card.display_card_data(card_data)
	card.is_face_up = true
	card.update_visibility()
	return card

func display_player_card(card: Card, player_area: Control):
	"""Exibe a carta de um jogador na sua área"""
	var card_slot = player_area.get_node("CardSlot")
	
	# Limpar carta anterior
	for child in card_slot.get_children():
		child.queue_free()
	
	card_slot.add_child(card)

func transition_to_battle_round():
	"""Transição para a rodada de batalha"""
	current_state = GameState.BATTLE_ROUND
	show_characteristic_selection()

func show_characteristic_selection():
	"""Mostra a seleção de característica para a batalha"""
	var selection_popup = create_characteristic_selection_popup()
	add_child(selection_popup)

func create_characteristic_selection_popup() -> Control:
	"""Cria o popup de seleção de característica"""
	var popup = AcceptDialog.new()
	popup.title = "Selecione a Característica - Jogador 1"
	popup.size = Vector2(300, 200)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var instruction = Label.new()
	instruction.text = "Escolha a característica para comparar:"
	vbox.add_child(instruction)
	
	for characteristic in active_characteristics:
		var button = Button.new()
		button.text = CHARACTERISTIC_NAMES[characteristic]
		button.pressed.connect(func():
			execute_battle_round(characteristic)
			popup.queue_free()
		)
		vbox.add_child(button)
	
	return popup

func execute_battle_round(characteristic: String):
	"""Executa a rodada de batalha com a característica selecionada"""
	current_state = GameState.BATTLE_ROUND
	
	var player1_value = get_card_characteristic_value(player1_current_card, characteristic)
	var player2_value = get_card_characteristic_value(player2_current_card, characteristic)
	
	var winner = determine_round_winner(player1_value, player2_value, characteristic)
	
	show_round_result(characteristic, player1_value, player2_value, winner)

func get_card_characteristic_value(card: Card, characteristic: String) -> float:
	"""Obtém o valor de uma característica da carta"""
	match characteristic:
		"altura":
			return card.altura
		"comprimento":
			return card.comprimento
		"velocidade":
			return card.velocidade
		"peso":
			return card.peso
		_:
			return 0.0

func determine_round_winner(value1: float, value2: float, characteristic: String) -> int:
	"""Determina o vencedor da rodada baseado na característica"""
	# Para este SuperTrunfo, tanto maior quanto menor podem ganhar
	# Vamos usar uma lógica onde o jogador 1 sempre escolhe se quer maior ou menor
	var wants_higher = show_higher_lower_choice()
	
	if wants_higher:
		return 1 if value1 > value2 else (2 if value2 > value1 else 0)
	else:
		return 1 if value1 < value2 else (2 if value2 < value1 else 0)

func show_higher_lower_choice() -> bool:
	"""Mostra a escolha entre maior ou menor valor"""
	# Por simplicidade, vamos assumir que sempre quer o maior valor
	# Em uma implementação completa, isso seria uma escolha do jogador
	return true

func show_round_result(characteristic: String, value1: float, value2: float, winner: int):
	"""Mostra o resultado da rodada"""
	current_state = GameState.ROUND_RESULT
	
	var result_text = "Resultado da Rodada %d\n\n" % current_round
	result_text += "Característica: %s\n" % CHARACTERISTIC_NAMES[characteristic]
	result_text += "Jogador 1: %.2f\n" % value1
	result_text += "Jogador 2: %.2f\n\n" % value2
	
	if winner == 0:
		result_text += "Empate!"
	else:
		result_text += "Vencedor: Jogador %d!" % winner
		if winner == 1:
			player1_wins += 1
		else:
			player2_wins += 1
	
	var result_popup = AcceptDialog.new()
	result_popup.dialog_text = result_text
	result_popup.title = "Resultado da Rodada"
	add_child(result_popup)
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
		process_round_end()
	)

func process_round_end():
	"""Processa o fim da rodada"""
	current_round += 1
	update_score_display()
	
	if current_round > max_rounds or player1_wins > max_rounds/2 or player2_wins > max_rounds/2:
		show_match_result()
	else:
		reset_for_next_round()

func update_score_display():
	"""Atualiza a exibição do placar"""
	round_counter.text = "Rodada: %d/%d" % [current_round, max_rounds]
	score_display.text = "Jogador 1: %d - Jogador 2: %d" % [player1_wins, player2_wins]

func reset_for_next_round():
	"""Reseta para a próxima rodada"""
	# Limpar cartas atuais
	if player1_current_card:
		player1_current_card.queue_free()
		player1_current_card = null
	
	if player2_current_card:
		player2_current_card.queue_free()
		player2_current_card = null
	
	current_player = 1
	transition_to_card_selection()

func show_match_result():
	"""Mostra o resultado final da partida"""
	current_state = GameState.MATCH_RESULT
	
	var winner_text = ""
	if player1_wins > player2_wins:
		winner_text = "Jogador 1 Venceu!"
		emit_signal("battle_finished", 1)
	elif player2_wins > player1_wins:
		winner_text = "Jogador 2 Venceu!"
		emit_signal("battle_finished", 2)
	else:
		winner_text = "Empate!"
		emit_signal("battle_finished", 0)
	
	var result_popup = AcceptDialog.new()
	result_popup.dialog_text = "Fim da Partida!\n\n%s\n\nPlacar Final:\nJogador 1: %d\nJogador 2: %d" % [winner_text, player1_wins, player2_wins]
	result_popup.title = "Resultado Final"
	add_child(result_popup)
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
	)

func _on_back_to_menu_pressed():
	"""Volta para o menu principal"""
	get_tree().change_scene_to_file("res://Menu.tscn")

# Função para inicializar com formato específico
func initialize_battle(format: BattleFormat = BattleFormat.CLASSIC):
	"""Inicializa a batalha com um formato específico"""
	battle_format = format
	
	match format:
		BattleFormat.CLASSIC:
			max_rounds = 3
		BattleFormat.BLITZ:
			max_rounds = 1
		BattleFormat.SURVIVAL:
			max_rounds = 5
		BattleFormat.DRAFT:
			max_rounds = 3
			# No formato draft, os jogadores escolhem cartas de um pool comum
			generate_draft_pool()
	
	start_battle_setup()

func generate_draft_pool():
	"""Gera um pool comum de cartas para o formato draft"""
	var draft_pool = []
	
	# Gerar 12 cartas para o draft (6 para cada jogador)
	for i in range(12):
		var animal_id = CardPoolManager.get_random_animal_id()
		var card_data = create_card_data(animal_id)
		draft_pool.append(card_data)
	
	# Implementar lógica de draft aqui
	# Por simplicidade, vamos dividir igualmente
	player1_deck = draft_pool.slice(0, 6)
	player2_deck = draft_pool.slice(6, 12)
