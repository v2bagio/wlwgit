# BlitzBattleScene.gd - Formato de batalha rápida (rodada única)
extends Control

signal battle_finished(winner_id: int)

const CardScene = preload("res://Card.tscn")
const CharacteristicBanSystem = preload("res://CharacteristicBanSystem.tscn")

# Nós da interface
@onready var player1_area = $PlayerAreas/Player1Area
@onready var player2_area = $PlayerAreas/Player2Area
@onready var battle_info = $BattleInfo
@onready var timer_display = $BattleInfo/TimerDisplay
@onready var characteristic_selector = $CharacteristicSelector
@onready var result_display = $ResultDisplay
@onready var back_button = $BackButton

# Configurações do Blitz
const TURN_TIME_LIMIT = 15.0
const DECK_SIZE = 3
const BANS_PER_PLAYER = 1

# Variáveis de estado
var player1_deck: Array = []
var player2_deck: Array = []
var player1_card: Card = null
var player2_card: Card = null
var active_characteristics: Array = ["altura", "comprimento", "velocidade", "peso"]
var current_turn_time: float = TURN_TIME_LIMIT
var is_timer_active: bool = false
var game_phase: String = "setup"

func _ready():
	setup_blitz_battle()
	back_button.pressed.connect(_on_back_button_pressed)

func _process(delta):
	if is_timer_active:
		current_turn_time -= delta
		update_timer_display()
		
		if current_turn_time <= 0:
			handle_timeout()

func setup_blitz_battle():
	"""Configura a batalha blitz"""
	game_phase = "setup"
	generate_small_decks()
	start_quick_banning_phase()

func generate_small_decks():
	"""Gera decks menores para o formato blitz"""
	player1_deck.clear()
	player2_deck.clear()
	
	for i in range(DECK_SIZE):
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

func start_quick_banning_phase():
	"""Inicia a fase de banimento rápida (1 ban por jogador)"""
	game_phase = "banning"
	var ban_system = CharacteristicBanSystem.instantiate()
	add_child(ban_system)
	
	ban_system.banning_phase_completed.connect(_on_banning_completed)
	ban_system.start_banning_phase(BANS_PER_PLAYER, 10.0)  # 10 segundos para banir

func _on_banning_completed(player1_bans: Array, player2_bans: Array, system_ban: String):
	"""Callback quando o banimento é completado"""
	# Atualizar características ativas
	var all_bans = player1_bans + player2_bans + [system_ban]
	active_characteristics.clear()
	
	for characteristic in ["altura", "comprimento", "velocidade", "peso"]:
		if characteristic not in all_bans:
			active_characteristics.append(characteristic)
	
	start_card_selection()

func start_card_selection():
	"""Inicia a seleção rápida de cartas"""
	game_phase = "card_selection"
	show_quick_card_selection()

func show_quick_card_selection():
	"""Mostra seleção rápida de cartas para ambos os jogadores"""
	var selection_popup = AcceptDialog.new()
	selection_popup.title = "Seleção Rápida - Ambos os Jogadores"
	selection_popup.size = Vector2(800, 400)
	
	var hbox = HBoxContainer.new()
	selection_popup.add_child(hbox)
	
	# Área do Jogador 1
	var p1_area = create_player_selection_area("Jogador 1", player1_deck)
	hbox.add_child(p1_area)
	
	# Separador
	var separator = VSeparator.new()
	hbox.add_child(separator)
	
	# Área do Jogador 2
	var p2_area = create_player_selection_area("Jogador 2", player2_deck)
	hbox.add_child(p2_area)
	
	add_child(selection_popup)
	
	# Timer para seleção
	start_selection_timer()

func create_player_selection_area(player_name: String, deck: Array) -> Control:
	"""Cria área de seleção para um jogador"""
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = player_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var cards_container = HBoxContainer.new()
	vbox.add_child(cards_container)
	
	for i in range(deck.size()):
		var card_data = deck[i]
		var button = Button.new()
		button.text = "Carta %d" % (i + 1)
		button.custom_minimum_size = Vector2(80, 120)
		
		button.pressed.connect(func():
			if player_name == "Jogador 1":
				player1_card = create_card_from_data(card_data)
			else:
				player2_card = create_card_from_data(card_data)
			
			check_both_cards_selected()
		)
		
		cards_container.add_child(button)
	
	return vbox

func create_card_from_data(card_data: Dictionary) -> Card:
	"""Cria uma instância de carta a partir dos dados"""
	var card = CardScene.instantiate() as Card
	card.display_card_data(card_data)
	card.is_face_up = true
	card.update_visibility()
	return card

func start_selection_timer():
	"""Inicia o timer para seleção de cartas"""
	current_turn_time = TURN_TIME_LIMIT
	is_timer_active = true

func check_both_cards_selected():
	"""Verifica se ambos os jogadores selecionaram suas cartas"""
	if player1_card != null and player2_card != null:
		is_timer_active = false
		display_selected_cards()
		start_battle_phase()

func display_selected_cards():
	"""Exibe as cartas selecionadas"""
	# Limpar áreas dos jogadores
	for child in player1_area.get_children():
		if child.name == "CardSlot":
			for card_child in child.get_children():
				card_child.queue_free()
			child.add_child(player1_card)
	
	for child in player2_area.get_children():
		if child.name == "CardSlot":
			for card_child in child.get_children():
				card_child.queue_free()
			child.add_child(player2_card)

func start_battle_phase():
	"""Inicia a fase de batalha"""
	game_phase = "battle"
	show_characteristic_selection()

func show_characteristic_selection():
	"""Mostra seleção de característica com timer"""
	characteristic_selector.visible = true
	
	# Limpar botões existentes
	for child in characteristic_selector.get_children():
		if child is Button:
			child.queue_free()
	
	var title = Label.new()
	title.text = "Jogador 1 - Escolha a característica:"
	characteristic_selector.add_child(title)
	
	for characteristic in active_characteristics:
		var button = Button.new()
		button.text = get_characteristic_name(characteristic)
		button.pressed.connect(func(): execute_blitz_battle(characteristic))
		characteristic_selector.add_child(button)
	
	# Reiniciar timer
	current_turn_time = TURN_TIME_LIMIT
	is_timer_active = true

func get_characteristic_name(characteristic: String) -> String:
	"""Retorna o nome amigável da característica"""
	var names = {
		"altura": "Altura",
		"comprimento": "Comprimento",
		"velocidade": "Velocidade",
		"peso": "Peso"
	}
	return names.get(characteristic, characteristic)

func execute_blitz_battle(characteristic: String):
	"""Executa a batalha blitz"""
	is_timer_active = false
	characteristic_selector.visible = false
	
	var player1_value = get_card_characteristic_value(player1_card, characteristic)
	var player2_value = get_card_characteristic_value(player2_card, characteristic)
	
	var winner = determine_winner(player1_value, player2_value)
	show_blitz_result(characteristic, player1_value, player2_value, winner)

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

func determine_winner(value1: float, value2: float) -> int:
	"""Determina o vencedor baseado nos valores"""
	if value1 > value2:
		return 1
	elif value2 > value1:
		return 2
	else:
		return 0  # Empate

func show_blitz_result(characteristic: String, value1: float, value2: float, winner: int):
	"""Mostra o resultado da batalha blitz"""
	game_phase = "result"
	
	var result_text = "RESULTADO BLITZ\n\n"
	result_text += "Característica: %s\n" % get_characteristic_name(characteristic)
	result_text += "Jogador 1: %.2f\n" % value1
	result_text += "Jogador 2: %.2f\n\n" % value2
	
	if winner == 0:
		result_text += "EMPATE!"
	else:
		result_text += "VENCEDOR: JOGADOR %d!" % winner
	
	result_display.text = result_text
	result_display.visible = true
	
	emit_signal("battle_finished", winner)
	
	# Auto-retorno ao menu após 5 segundos
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(_on_back_button_pressed)
	timer.start()

func handle_timeout():
	"""Lida com timeout do timer"""
	is_timer_active = false
	
	match game_phase:
		"card_selection":
			auto_select_cards()
		"battle":
			auto_select_characteristic()

func auto_select_cards():
	"""Seleciona cartas automaticamente quando o tempo acaba"""
	if player1_card == null:
		player1_card = create_card_from_data(player1_deck[0])
	
	if player2_card == null:
		player2_card = create_card_from_data(player2_deck[0])
	
	display_selected_cards()
	start_battle_phase()

func auto_select_characteristic():
	"""Seleciona característica automaticamente"""
	if not active_characteristics.is_empty():
		var random_characteristic = active_characteristics.pick_random()
		execute_blitz_battle(random_characteristic)

func update_timer_display():
	"""Atualiza a exibição do timer"""
	timer_display.text = "Tempo: %d" % int(current_turn_time)
	
	# Mudar cor quando tempo está acabando
	if current_turn_time <= 5.0:
		timer_display.modulate = Color.RED
	else:
		timer_display.modulate = Color.WHITE

func _on_back_button_pressed():
	"""Volta para o menu principal"""
	get_tree().change_scene_to_file("res://Menu.tscn")
