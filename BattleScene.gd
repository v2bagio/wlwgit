# BattleScene.gd - Cena principal de batalha SuperTrunfo
extends Control

signal battle_finished(winner_id: int)

const CardScene = preload("res://Card.tscn")
const CharacteristicBanSystemScene = preload("res://CharacteristicBanSystem.tscn")

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

# Características disponíveis para banimento (agora com maior/menor)
const CHARACTERISTICS = [
	"maior_altura", "menor_altura",
	"maior_comprimento", "menor_comprimento",
	"maior_velocidade", "menor_velocidade",
	"maior_peso", "menor_peso"
]

const CHARACTERISTIC_NAMES = {
	"maior_altura": "Maior Altura",
	"menor_altura": "Menor Altura",
	"maior_comprimento": "Maior Comprimento",
	"menor_comprimento": "Menor Comprimento",
	"maior_velocidade": "Maior Velocidade",
	"menor_velocidade": "Menor Velocidade",
	"maior_peso": "Maior Peso",
	"menor_peso": "Menor Peso"
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

# Referência ao sistema de banimento
var ban_system_instance = null

func _ready():
	setup_ui()
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
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
	print("BattleScene: Iniciando setup da batalha.")
	current_state = GameState.SETUP
	generate_player_decks()
	transition_to_banning_phase()

func generate_player_decks():
	"""Gera os decks dos jogadores com cartas aleatórias"""
	print("BattleScene: Gerando decks dos jogadores.")
	player1_deck.clear()
	player2_deck.clear()
	
	# Gerar 5 cartas para cada jogador
	for i in range(5):
		var animal_id1 = CardPoolManager.get_random_animal_id()
		var animal_id2 = CardPoolManager.get_random_animal_id()
		
		# Adicionado verificação para garantir que animal_id não seja vazio
		if animal_id1.is_empty() or animal_id2.is_empty():
			printerr("BattleScene: ID de animal vazio ao gerar deck. Verifique AnimalDatabase.gd e CardPoolManager.gd")
			continue

		var card_data1 = create_card_data(animal_id1)
		var card_data2 = create_card_data(animal_id2)
		
		# Adicionado verificação para garantir que card_data não seja vazio
		if not card_data1.is_empty():
			player1_deck.append(card_data1)
		else:
			printerr("BattleScene: card_data1 vazio para animal_id: ", animal_id1)
		
		if not card_data2.is_empty():
			player2_deck.append(card_data2)
		else:
			printerr("BattleScene: card_data2 vazio para animal_id: ", animal_id2)
	
	print("BattleScene: Decks gerados. Player1 deck size: ", player1_deck.size(), ", Player2 deck size: ", player2_deck.size())

func create_card_data(animal_id: String) -> Dictionary:
	"""Cria dados de carta baseados no animal"""
	var animal_data = AnimalDatabase.get_animal_data(animal_id)
	if animal_data.is_empty():
		printerr("BattleScene: Dados do animal não encontrados para ID: ", animal_id)
		return {}
	
	var card = CardScene.instantiate() as Card
	# Adiciona a carta à árvore de cena temporariamente para que _ready() seja chamado
	add_child(card)
	card.setup(animal_id, false, false, false)
	var card_data = card.get_card_data()
	card.queue_free() # Libera a carta da memória após obter os dados
	
	return card_data

func transition_to_banning_phase():
	"""Transição para a fase de banimento de características"""
	print("BattleScene: Transicionando para fase de banimento.")
	current_state = GameState.BANNING_PHASE
	
	ban_system_instance = CharacteristicBanSystemScene.instantiate()
	add_child(ban_system_instance)
	# Conecta o sinal antes de iniciar a fase de banimento
	ban_system_instance.banning_phase_completed.connect(_on_banning_completed)
	print("BattleScene: Sinal conectado, iniciando fase de banimento")
	ban_system_instance.start_banning_phase(2, 30.0) # 2 bans por jogador, 30 segundos

func _on_banning_completed(p1_bans: Array, p2_bans: Array, sys_ban: String):
	"""Callback quando o banimento é completado"""
	print("BattleScene: *** SINAL RECEBIDO *** banning_phase_completed")
	print("BattleScene: Player1 bans: ", p1_bans)
	print("BattleScene: Player2 bans: ", p2_bans)
	print("BattleScene: System ban: ", sys_ban)
	
	player1_bans = p1_bans
	player2_bans = p2_bans
	system_ban = sys_ban
	
	# Atualizar características ativas
	banned_characteristics = player1_bans + player2_bans + [system_ban]
	active_characteristics.clear()
	
	for characteristic in CHARACTERISTICS:
		if characteristic not in banned_characteristics:
			active_characteristics.append(characteristic)
	
	print("BattleScene: Características ativas: ", active_characteristics)
	
	update_banned_characteristics_display()
	
	# Aguardar um frame antes de transicionar para garantir que o sistema de banimento seja removido
	print("BattleScene: Aguardando frame antes de transicionar")
	await get_tree().process_frame
	print("BattleScene: Iniciando transição para seleção de cartas")
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
	print("BattleScene: *** TRANSICIONANDO PARA SELEÇÃO DE CARTAS ***")
	current_state = GameState.CARD_SELECTION
	current_player = 1
	show_card_selection_interface()

func show_card_selection_interface():
	"""Mostra a interface de seleção de cartas"""
	print("BattleScene: Mostrando interface de seleção de cartas para Jogador ", current_player)
	var selection_popup = create_card_selection_popup()
	add_child(selection_popup)
	selection_popup.popup_centered() # Garantir que o popup seja exibido
	print("BattleScene: Popup de seleção de cartas criado e exibido")

func create_card_selection_popup() -> Control:
	"""Cria o popup de seleção de cartas"""
	var popup = AcceptDialog.new()
	popup.title = "Seleção de Carta - Jogador %d" % current_player
	popup.size = Vector2(800, 600)
	popup.unresizable = false
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var instruction = Label.new()
	instruction.text = "Selecione uma carta para a rodada %d:" % current_round
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruction)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(780, 500)
	vbox.add_child(scroll_container)
	
	var cards_container = HBoxContainer.new()
	scroll_container.add_child(cards_container)
	
	var player_deck = player1_deck if current_player == 1 else player2_deck
	var used_cards = player1_used_cards if current_player == 1 else player2_used_cards
	
	# Adicionado verificação para garantir que o deck não esteja vazio
	if player_deck.is_empty():
		printerr("BattleScene: Deck do jogador ", current_player, " está vazio. Não é possível selecionar cartas.")
		popup.dialog_text = "Erro: Deck vazio. Não é possível prosseguir."
		popup.confirmed.connect(func(): popup.queue_free())
		return popup

	for i in range(player_deck.size()):
		var card_data = player_deck[i]
		if card_data in used_cards:
			continue
		
		var card_container = VBoxContainer.new()
		cards_container.add_child(card_container)
		
		# Criar carta usando apenas dados, sem instanciar Card.gd
		var card_display = create_simple_card_display(card_data)
		card_container.add_child(card_display)
		
		var button = Button.new()
		button.text = "Selecionar"
		button.custom_minimum_size = Vector2(150, 40)
		# Usar o índice para evitar problemas de captura de lambda
		var card_index = i
		button.pressed.connect(func():
			process_card_selection(player_deck[card_index])
			popup.queue_free()
		)
		card_container.add_child(button)
	
	return popup

func create_simple_card_display(card_data: Dictionary) -> Control:
	"""Cria uma exibição simples da carta usando apenas dados"""
	var card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(150, 200)
	
	# Nome do animal
	var name_label = Label.new()
	name_label.text = card_data.get("nome", "Animal Desconhecido")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	card_container.add_child(name_label)
	
	# Imagem (placeholder)
	var image_placeholder = ColorRect.new()
	image_placeholder.color = Color.GRAY
	image_placeholder.custom_minimum_size = Vector2(140, 100)
	card_container.add_child(image_placeholder)
	
	# Características
	var stats_container = VBoxContainer.new()
	card_container.add_child(stats_container)
	
	var altura_label = Label.new()
	altura_label.text = "Altura: %.2f m" % card_data.get("altura", 0.0)
	stats_container.add_child(altura_label)
	
	var comprimento_label = Label.new()
	comprimento_label.text = "Comprimento: %.2f m" % card_data.get("comprimento", 0.0)
	stats_container.add_child(comprimento_label)
	
	var velocidade_label = Label.new()
	velocidade_label.text = "Velocidade: %.2f km/h" % card_data.get("velocidade", 0.0)
	stats_container.add_child(velocidade_label)
	
	var peso_label = Label.new()
	peso_label.text = "Peso: %.2f kg" % card_data.get("peso", 0.0)
	stats_container.add_child(peso_label)
	
	# Adicionar borda
	var border = StyleBoxFlat.new()
	border.border_width_left = 2
	border.border_width_right = 2
	border.border_width_top = 2
	border.border_width_bottom = 2
	border.border_color = Color.BLACK
	border.bg_color = Color.WHITE
	
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", border)
	panel.add_child(card_container)
	
	return panel

func process_card_selection(card_data: Dictionary):
	"""Processa a seleção de carta de um jogador"""
	print("BattleScene: Processando seleção de carta para Jogador ", current_player, ". Carta selecionada: ", card_data.get("nome", "N/A"))
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
	add_child(card)  # Adicionar à árvore primeiro
	card.display_card_data(card_data)
	card.is_face_up = true
	card.update_visibility()
	remove_child(card)  # Remover da árvore após configurar
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
	print("BattleScene: Transicionando para rodada de batalha.")
	current_state = GameState.BATTLE_ROUND
	show_characteristic_selection()

func show_characteristic_selection():
	"""Mostra a seleção de característica para a batalha"""
	print("BattleScene: Mostrando seleção de característica.")
	var selection_popup = create_characteristic_selection_popup()
	add_child(selection_popup)
	selection_popup.popup_centered()

func create_characteristic_selection_popup() -> Control:
	"""Cria o popup de seleção de característica"""
	var popup = AcceptDialog.new()
	popup.title = "Selecione a Característica - Jogador 1"
	popup.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var instruction = Label.new()
	instruction.text = "Escolha a característica para comparar:"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruction)
	
	for characteristic in active_characteristics:
		var button = Button.new()
		button.text = CHARACTERISTIC_NAMES[characteristic]
		button.custom_minimum_size = Vector2(350, 40)
		button.pressed.connect(func():
			execute_battle_round(characteristic)
			popup.queue_free()
		)
		vbox.add_child(button)
	
	return popup

func execute_battle_round(characteristic: String):
	"""Executa a rodada de batalha com a característica selecionada"""
	print("BattleScene: Executando rodada de batalha com característica: ", characteristic)
	current_state = GameState.BATTLE_ROUND
	
	var player1_value = get_card_characteristic_value(player1_current_card, characteristic)
	var player2_value = get_card_characteristic_value(player2_current_card, characteristic)
	
	var winner = determine_round_winner(player1_value, player2_value, characteristic)
	
	show_round_result(characteristic, player1_value, player2_value, winner)

func get_card_characteristic_value(card: Card, characteristic: String) -> float:
	"""Obtém o valor de uma característica da carta"""
	# Extrair a característica base (altura, comprimento, velocidade, peso)
	var base_characteristic = ""
	if characteristic.begins_with("maior_") or characteristic.begins_with("menor_"):
		base_characteristic = characteristic.substr(6) # Remove "maior_" ou "menor_"
	
	match base_characteristic:
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
	var wants_higher = characteristic.begins_with("maior_")
	
	if wants_higher:
		return 1 if value1 > value2 else (2 if value2 > value1 else 0)
	else:
		return 1 if value1 < value2 else (2 if value2 < value1 else 0)

func show_round_result(characteristic: String, value1: float, value2: float, winner: int):
	"""Mostra o resultado da rodada"""
	print("BattleScene: Mostrando resultado da rodada.")
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
	result_popup.popup_centered()
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
		process_round_end()
	)

func process_round_end():
	"""Processa o fim da rodada"""
	print("BattleScene: Processando fim da rodada.")
	current_round += 1
	update_score_display()
	
	# Corrigido: usar divisão de float para evitar warning
	var half_rounds = float(max_rounds) / 2.0
	if current_round > max_rounds or float(player1_wins) > half_rounds or float(player2_wins) > half_rounds:
		show_match_result()
	else:
		reset_for_next_round()

func update_score_display():
	"""Atualiza a exibição do placar"""
	round_counter.text = "Rodada: %d/%d" % [current_round, max_rounds]
	score_display.text = "Jogador 1: %d - Jogador 2: %d" % [player1_wins, player2_wins]

func reset_for_next_round():
	"""Reseta para a próxima rodada"""
	print("BattleScene: Resetando para próxima rodada.")
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
	print("BattleScene: Mostrando resultado final da partida.")
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
	result_popup.popup_centered()
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
		_on_back_to_menu_pressed()
	)

func _on_back_to_menu_pressed():
	"""Volta para o menu principal"""
	print("BattleScene: Voltando para o menu principal.")
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
