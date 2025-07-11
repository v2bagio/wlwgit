# DraftBattleScene.gd - Formato Draft (seleção de cartas de pool comum)
extends Control

signal battle_finished(winner_id: int)

const CardScene = preload("res://Card.tscn")
const CharacteristicBanSystem = preload("res://CharacteristicBanSystem.tscn")

# Nós da interface
@onready var draft_interface = $DraftInterface
@onready var draft_pool_display = $DraftInterface/PoolDisplay
@onready var player_decks_display = $DraftInterface/PlayerDecksDisplay
@onready var draft_info = $DraftInterface/DraftInfo
@onready var battle_area = $BattleArea
@onready var back_button = $BackButton

# Configurações do Draft
const DRAFT_POOL_SIZE = 16
const PICKS_PER_PLAYER = 6
const BANS_PER_PLAYER = 1

# Variáveis de estado
var draft_pool: Array = []
var player1_draft_deck: Array = []
var player2_draft_deck: Array = []
var current_drafter: int = 1
var draft_round: int = 1
var picks_made: int = 0
var draft_phase: String = "drafting"  # "drafting", "banning", "battle"

func _ready():
	setup_draft_battle()
	back_button.pressed.connect(_on_back_button_pressed)

func setup_draft_battle():
	"""Configura a batalha draft"""
	generate_draft_pool()
	start_draft_phase()

func generate_draft_pool():
	"""Gera o pool comum de cartas para o draft"""
	draft_pool.clear()
	
	# Gerar cartas com variedade de biomas e raridades
	var biomes = ["Pantanal", "Amazônia", "Mata Atlântica", "Cerrado", "Caatinga", "Pampa"]
	
	for i in range(DRAFT_POOL_SIZE):
		var animal_id = CardPoolManager.get_random_animal_id()
		
		# Ocasionalmente usar cartas de bioma específico para variedade
		if i % 4 == 0 and not biomes.is_empty():
			var preferred_biome = biomes.pick_random()
			animal_id = CardPoolManager.get_boosted_animal_id(preferred_biome)
		
		var card_data = create_card_data(animal_id)
		if not card_data.is_empty():
			draft_pool.append(card_data)

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

func start_draft_phase():
	"""Inicia a fase de draft"""
	draft_phase = "drafting"
	update_draft_display()
	show_draft_interface()

func show_draft_interface():
	"""Mostra a interface de draft"""
	draft_interface.visible = true
	battle_area.visible = false
	
	update_draft_info()
	display_available_cards()

func update_draft_info():
	"""Atualiza as informações do draft"""
	var info_text = "FASE DE DRAFT\n\n"
	info_text += "Rodada: %d\n" % draft_round
	info_text += "Vez do: Jogador %d\n" % current_drafter
	info_text += "Picks restantes: %d\n\n" % (PICKS_PER_PLAYER * 2 - picks_made)
	info_text += "Cartas no pool: %d" % draft_pool.size()
	
	draft_info.text = info_text

func display_available_cards():
	"""Exibe as cartas disponíveis para draft"""
	# Limpar display anterior
	for child in draft_pool_display.get_children():
		child.queue_free()
	
	var grid = GridContainer.new()
	grid.columns = 4
	draft_pool_display.add_child(grid)
	
	for i in range(draft_pool.size()):
		var card_data = draft_pool[i]
		var card_button = create_draft_card_button(card_data, i)
		grid.add_child(card_button)

func create_draft_card_button(card_data: Dictionary, index: int) -> Control:
	"""Cria um botão para seleção de carta no draft"""
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(120, 180)
	
	# Nome da carta
	var name_label = Label.new()
	name_label.text = card_data.get("nome_display", "Carta")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Bioma
	var biome_label = Label.new()
	biome_label.text = card_data.get("bioma", "")
	biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_label.modulate = Color.GRAY
	vbox.add_child(biome_label)
	
	# Estatísticas resumidas
	var stats_label = Label.new()
	stats_label.text = "A:%.1f C:%.1f\nV:%.1f P:%.1f" % [
		card_data.get("altura", 0),
		card_data.get("comprimento", 0),
		card_data.get("velocidade", 0),
		card_data.get("peso", 0)
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	# Raridade
	var rarity_label = Label.new()
	rarity_label.text = card_data.get("raridade", "Comum")
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.modulate = get_rarity_color(card_data.get("raridade", "Comum"))
	vbox.add_child(rarity_label)
	
	# Botão de seleção
	var select_button = Button.new()
	select_button.text = "Escolher"
	select_button.pressed.connect(func(): draft_card(index))
	vbox.add_child(select_button)
	
	# Borda colorida baseada na raridade
	var border = NinePatchRect.new()
	border.color = get_rarity_color(card_data.get("raridade", "Comum"))
	vbox.add_child(border)
	vbox.move_child(border, 0)
	
	return vbox

func get_rarity_color(rarity: String) -> Color:
	"""Retorna a cor baseada na raridade"""
	var colors = {
		"Comum": Color.GRAY,
		"Incomum": Color.GREEN,
		"Rara": Color.BLUE,
		"Lendária": Color.PURPLE,
		"Anomalia Incomum": Color.PINK,
		"Anomalia Rara": Color.ORANGE,
		"Anomalia Lendária": Color.GOLD
	}
	return colors.get(rarity, Color.WHITE)

func draft_card(index: int):
	"""Realiza o draft de uma carta"""
	var selected_card = draft_pool[index]
	draft_pool.remove_at(index)
	
	# Adicionar à coleção do jogador atual
	if current_drafter == 1:
		player1_draft_deck.append(selected_card)
	else:
		player2_draft_deck.append(selected_card)
	
	picks_made += 1
	
	# Alternar jogador
	current_drafter = 2 if current_drafter == 1 else 1
	
	# Verificar se o draft terminou
	if picks_made >= PICKS_PER_PLAYER * 2:
		finish_draft_phase()
	else:
		# Atualizar rodada a cada 2 picks
		if picks_made % 2 == 0:
			draft_round += 1
		
		update_draft_display()
		display_available_cards()

func update_draft_display():
	"""Atualiza a exibição dos decks dos jogadores"""
	var display_text = "DECKS DOS JOGADORES\n\n"
	
	display_text += "Jogador 1 (%d cartas):\n" % player1_draft_deck.size()
	for card in player1_draft_deck:
		display_text += "- %s\n" % card.get("nome_display", "Carta")
	
	display_text += "\nJogador 2 (%d cartas):\n" % player2_draft_deck.size()
	for card in player2_draft_deck:
		display_text += "- %s\n" % card.get("nome_display", "Carta")
	
	player_decks_display.text = display_text
	update_draft_info()

func finish_draft_phase():
	"""Finaliza a fase de draft"""
	draft_phase = "banning"
	show_draft_summary()

func show_draft_summary():
	"""Mostra o resumo do draft"""
	var summary_popup = AcceptDialog.new()
	summary_popup.title = "Draft Concluído"
	summary_popup.size = Vector2(600, 400)
	
	var vbox = VBoxContainer.new()
	summary_popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "DRAFT CONCLUÍDO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Análise dos decks
	var analysis = analyze_draft_decks()
	var analysis_label = RichTextLabel.new()
	analysis_label.bbcode_enabled = true
	analysis_label.text = analysis
	analysis_label.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(analysis_label)
	
	var continue_button = Button.new()
	continue_button.text = "Continuar para Banimento"
	continue_button.pressed.connect(func():
		summary_popup.queue_free()
		start_draft_banning_phase()
	)
	vbox.add_child(continue_button)
	
	add_child(summary_popup)

func analyze_draft_decks() -> String:
	"""Analisa os decks criados no draft"""
	var analysis = "[b]ANÁLISE DOS DECKS[/b]\n\n"
	
	# Análise do Jogador 1
	analysis += "[color=blue]Jogador 1:[/color]\n"
	analysis += analyze_player_deck(player1_draft_deck)
	
	analysis += "\n[color=red]Jogador 2:[/color]\n"
	analysis += analyze_player_deck(player2_draft_deck)
	
	return analysis

func analyze_player_deck(deck: Array) -> String:
	"""Analisa o deck de um jogador"""
	var analysis = ""
	
	# Contar biomas
	var biomes = {}
	var rarities = {}
	var total_stats = {"altura": 0, "comprimento": 0, "velocidade": 0, "peso": 0}
	
	for card in deck:
		var biome = card.get("bioma", "Desconhecido")
		biomes[biome] = biomes.get(biome, 0) + 1
		
		var rarity = card.get("raridade", "Comum")
		rarities[rarity] = rarities.get(rarity, 0) + 1
		
		total_stats.altura += card.get("altura", 0)
		total_stats.comprimento += card.get("comprimento", 0)
		total_stats.velocidade += card.get("velocidade", 0)
		total_stats.peso += card.get("peso", 0)
	
	# Biomas mais comuns
	analysis += "Biomas: "
	for biome in biomes:
		analysis += "%s(%d) " % [biome, biomes[biome]]
	
	analysis += "\nRaridades: "
	for rarity in rarities:
		analysis += "%s(%d) " % [rarity, rarities[rarity]]
	
	# Médias das estatísticas
	analysis += "\nMédias: "
	for stat in total_stats:
		var avg = total_stats[stat] / deck.size() if deck.size() > 0 else 0
		analysis += "%s:%.1f " % [stat.capitalize(), avg]
	
	return analysis

func start_draft_banning_phase():
	"""Inicia a fase de banimento após o draft"""
	draft_interface.visible = false
	
	var ban_system = CharacteristicBanSystem.instantiate()
	add_child(ban_system)
	
	ban_system.banning_phase_completed.connect(_on_draft_banning_completed)
	ban_system.start_banning_phase(BANS_PER_PLAYER, 20.0)

func _on_draft_banning_completed(player1_bans: Array, player2_bans: Array, system_ban: String):
	"""Callback quando o banimento do draft é completado"""
	var all_bans = player1_bans + player2_bans + [system_ban]
	var active_characteristics = []
	
	for characteristic in ["altura", "comprimento", "velocidade", "peso"]:
		if characteristic not in all_bans:
			active_characteristics.append(characteristic)
	
	start_draft_battle(active_characteristics)

func start_draft_battle(active_characteristics: Array):
	"""Inicia a batalha com os decks draftados"""
	draft_phase = "battle"
	battle_area.visible = true
	
	# Implementar batalha melhor de 3 com os decks draftados
	var battle_scene = load("res://BattleScene.tscn").instantiate()
	battle_area.add_child(battle_scene)
	
	# Configurar o battle scene com os decks draftados
	battle_scene.player1_deck = player1_draft_deck
	battle_scene.player2_deck = player2_draft_deck
	battle_scene.active_characteristics = active_characteristics
	
	battle_scene.battle_finished.connect(_on_draft_battle_finished)

func _on_draft_battle_finished(winner: int):
	"""Callback quando a batalha draft termina"""
	emit_signal("battle_finished", winner)
	
	var result_popup = AcceptDialog.new()
	result_popup.title = "Batalha Draft Concluída"
	result_popup.dialog_text = "Vencedor da Batalha Draft: Jogador %d!" % winner
	add_child(result_popup)
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
		_on_back_button_pressed()
	)

func _on_back_button_pressed():
	"""Volta para o menu principal"""
	get_tree().change_scene_to_file("res://Menu.tscn")

