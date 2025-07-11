# SurvivalBattleScene.gd - Formato de sobrevivência (múltiplas cartas, eliminação)
extends Control

signal battle_finished(winner_id: int)

const CardScene = preload("res://Card.tscn")
const CharacteristicBanSystem = preload("res://CharacteristicBanSystem.tscn")

# Nós da interface
@onready var player1_area = $PlayerAreas/Player1Area
@onready var player2_area = $PlayerAreas/Player2Area
@onready var battle_info = $BattleInfo
@onready var round_counter = $BattleInfo/RoundCounter
@onready var cards_remaining = $BattleInfo/CardsRemaining
@onready var graveyard_display = $GraveyardDisplay
@onready var characteristic_selector = $CharacteristicSelector
@onready var back_button = $BackButton

# Configurações do Survival
const INITIAL_DECK_SIZE = 8
const BANS_PER_PLAYER = 3
const MAX_ROUNDS = 8

# Variáveis de estado
var player1_deck: Array = []
var player2_deck: Array = []
var player1_graveyard: Array = []
var player2_graveyard: Array = []
var player1_current_card: Card = null
var player2_current_card: Card = null
var active_characteristics: Array = ["altura", "comprimento", "velocidade", "peso"]
var current_round: int = 1
var current_player_turn: int = 1

func _ready():
	setup_survival_battle()
	back_button.pressed.connect(_on_back_button_pressed)

func setup_survival_battle():
	"""Configura a batalha de sobrevivência"""
	generate_survival_decks()
	start_survival_banning_phase()

func generate_survival_decks():
	"""Gera decks maiores para o formato de sobrevivência"""
	player1_deck.clear()
	player2_deck.clear()
	
	for i in range(INITIAL_DECK_SIZE):
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

func start_survival_banning_phase():
	"""Inicia a fase de banimento para sobrevivência"""
	var ban_system = CharacteristicBanSystem.instantiate()
	add_child(ban_system)
	
	ban_system.banning_phase_completed.connect(_on_banning_completed)
	ban_system.start_banning_phase(BANS_PER_PLAYER, 45.0)  # Mais tempo para 3 banimentos

func _on_banning_completed(player1_bans: Array, player2_bans: Array, system_ban: String):
	"""Callback quando o banimento é completado"""
	var all_bans = player1_bans + player2_bans + [system_ban]
	active_characteristics.clear()
	
	for characteristic in ["altura", "comprimento", "velocidade", "peso"]:
		if characteristic not in all_bans:
			active_characteristics.append(characteristic)
	
	start_survival_rounds()

func start_survival_rounds():
	"""Inicia as rodadas de sobrevivência"""
	update_display()
	start_round()

func start_round():
	"""Inicia uma nova rodada"""
	if is_game_over():
		end_survival_battle()
		return
	
	show_card_selection_for_current_player()

func show_card_selection_for_current_player():
	"""Mostra seleção de carta para o jogador atual"""
	var current_deck = player1_deck if current_player_turn == 1 else player2_deck
	var player_name = "Jogador %d" % current_player_turn
	
	if current_deck.is_empty():
		# Jogador sem cartas perde
		end_survival_battle()
		return
	
	var selection_popup = AcceptDialog.new()
	selection_popup.title = "Seleção de Carta - %s" % player_name
	selection_popup.size = Vector2(600, 400)
	
	var vbox = VBoxContainer.new()
	selection_popup.add_child(vbox)
	
	var instruction = Label.new()
	instruction.text = "Escolha uma carta para a rodada %d:" % current_round
	vbox.add_child(instruction)
	
	var cards_container = GridContainer.new()
	cards_container.columns = 4
	vbox.add_child(cards_container)
	
	for i in range(current_deck.size()):
		var card_data = current_deck[i]
		var card_button = create_card_preview_button(card_data, i)
		cards_container.add_child(card_button)
	
	add_child(selection_popup)

func create_card_preview_button(card_data: Dictionary, index: int) -> Control:
	"""Cria um botão de preview da carta"""
	var vbox = VBoxContainer.new()
	
	var preview = Label.new()
	preview.text = card_data.get("nome_display", "Carta %d" % (index + 1))
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(preview)
	
	var stats = Label.new()
	stats.text = "A:%.1f C:%.1f V:%.1f P:%.1f" % [
		card_data.get("altura", 0),
		card_data.get("comprimento", 0), 
		card_data.get("velocidade", 0),
		card_data.get("peso", 0)
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)
	
	var button = Button.new()
	button.text = "Selecionar"
	button.pressed.connect(func(): select_card_for_battle(card_data, index))
	vbox.add_child(button)
	
	return vbox

func select_card_for_battle(card_data: Dictionary, index: int):
	"""Seleciona uma carta para a batalha"""
	# Remover carta do deck
	if current_player_turn == 1:
		player1_deck.remove_at(index)
		player1_current_card = create_card_from_data(card_data)
		display_card(player1_current_card, player1_area)
	else:
		player2_deck.remove_at(index)
		player2_current_card = create_card_from_data(card_data)
		display_card(player2_current_card, player2_area)
	
	# Fechar popup
	for child in get_children():
		if child is AcceptDialog:
			child.queue_free()
	
	# Próximo jogador ou iniciar batalha
	if current_player_turn == 1:
		current_player_turn = 2
		show_card_selection_for_current_player()
	else:
		current_player_turn = 1
		start_round_battle()

func create_card_from_data(card_data: Dictionary) -> Card:
	"""Cria uma instância de carta a partir dos dados"""
	var card = CardScene.instantiate() as Card
	card.display_card_data(card_data)
	card.is_face_up = true
	card.update_visibility()
	return card

func display_card(card: Card, player_area: Control):
	"""Exibe a carta na área do jogador"""
	var card_slot = player_area.get_node("CardSlot")
	
	# Limpar carta anterior
	for child in card_slot.get_children():
		child.queue_free()
	
	card_slot.add_child(card)

func start_round_battle():
	"""Inicia a batalha da rodada"""
	show_characteristic_selection()

func show_characteristic_selection():
	"""Mostra seleção de característica"""
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
		button.pressed.connect(func(): execute_round_battle(characteristic))
		characteristic_selector.add_child(button)

func get_characteristic_name(characteristic: String) -> String:
	"""Retorna o nome amigável da característica"""
	var names = {
		"altura": "Altura",
		"comprimento": "Comprimento",
		"velocidade": "Velocidade",
		"peso": "Peso"
	}
	return names.get(characteristic, characteristic)

func execute_round_battle(characteristic: String):
	"""Executa a batalha da rodada"""
	characteristic_selector.visible = false
	
	var player1_value = get_card_characteristic_value(player1_current_card, characteristic)
	var player2_value = get_card_characteristic_value(player2_current_card, characteristic)
	
	var winner = determine_winner(player1_value, player2_value)
	process_round_result(characteristic, player1_value, player2_value, winner)

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

func process_round_result(characteristic: String, value1: float, value2: float, winner: int):
	"""Processa o resultado da rodada"""
	show_round_result(characteristic, value1, value2, winner)
	
	# Mover carta perdedora para o cemitério
	match winner:
		1:
			player2_graveyard.append(player2_current_card.get_card_data())
			player2_current_card.queue_free()
		2:
			player1_graveyard.append(player1_current_card.get_card_data())
			player1_current_card.queue_free()
		0:
			# Em caso de empate, ambas as cartas vão para o cemitério
			player1_graveyard.append(player1_current_card.get_card_data())
			player2_graveyard.append(player2_current_card.get_card_data())
			player1_current_card.queue_free()
			player2_current_card.queue_free()
	
	current_round += 1
	update_display()

func show_round_result(characteristic: String, value1: float, value2: float, winner: int):
	"""Mostra o resultado da rodada"""
	var result_text = "Rodada %d\n\n" % (current_round - 1)
	result_text += "Característica: %s\n" % get_characteristic_name(characteristic)
	result_text += "Jogador 1: %.2f\n" % value1
	result_text += "Jogador 2: %.2f\n\n" % value2
	
	if winner == 0:
		result_text += "Empate! Ambas as cartas eliminadas."
	else:
		result_text += "Vencedor: Jogador %d!" % winner
	
	var result_popup = AcceptDialog.new()
	result_popup.dialog_text = result_text
	result_popup.title = "Resultado da Rodada"
	add_child(result_popup)
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
		start_round()
	)

func update_display():
	"""Atualiza a exibição das informações"""
	round_counter.text = "Rodada: %d" % current_round
	cards_remaining.text = "Cartas - J1: %d | J2: %d" % [player1_deck.size(), player2_deck.size()]
	
	# Atualizar cemitério
	var graveyard_text = "Cemitério:\n"
	graveyard_text += "Jogador 1: %d cartas\n" % player1_graveyard.size()
	graveyard_text += "Jogador 2: %d cartas" % player2_graveyard.size()
	graveyard_display.text = graveyard_text

func is_game_over() -> bool:
	"""Verifica se o jogo acabou"""
	return player1_deck.is_empty() or player2_deck.is_empty() or current_round > MAX_ROUNDS

func end_survival_battle():
	"""Finaliza a batalha de sobrevivência"""
	var winner = 0
	var result_text = "FIM DA BATALHA DE SOBREVIVÊNCIA!\n\n"
	
	if player1_deck.size() > player2_deck.size():
		winner = 1
		result_text += "VENCEDOR: JOGADOR 1!\n"
	elif player2_deck.size() > player1_deck.size():
		winner = 2
		result_text += "VENCEDOR: JOGADOR 2!\n"
	else:
		result_text += "EMPATE!\n"
	
	result_text += "Cartas restantes:\n"
	result_text += "Jogador 1: %d\n" % player1_deck.size()
	result_text += "Jogador 2: %d\n" % player2_deck.size()
	result_text += "Rodadas jogadas: %d" % (current_round - 1)
	
	var final_popup = AcceptDialog.new()
	final_popup.dialog_text = result_text
	final_popup.title = "Resultado Final"
	add_child(final_popup)
	
	final_popup.confirmed.connect(func():
		final_popup.queue_free()
		emit_signal("battle_finished", winner)
		_on_back_button_pressed()
	)

func _on_back_button_pressed():
	"""Volta para o menu principal"""
	get_tree().change_scene_to_file("res://Menu.tscn")

