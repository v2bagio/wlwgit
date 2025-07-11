# CustomBattleScene.gd - Formato personalizado com regras configuráveis
extends Control

signal battle_finished(winner_id: int)

const CardScene = preload("res://Card.tscn")
const CharacteristicBanSystem = preload("res://CharacteristicBanSystem.tscn")

# Nós da interface
@onready var rules_setup = $RulesSetup
@onready var battle_area = $BattleArea
@onready var back_button = $BackButton

# Configurações personalizáveis
var custom_rules: Dictionary = {
	"max_rounds": 3,
	"deck_size": 5,
	"bans_per_player": 2,
	"system_ban_enabled": true,
	"time_limit_per_turn": 30,
	"allow_duplicates": false,
	"special_rules": [],
	"win_condition": "best_of_rounds",  # "best_of_rounds", "elimination", "points"
	"characteristic_weights": {},
	"banned_animals": [],
	"forced_biomes": []
}

# Regras especiais disponíveis
const SPECIAL_RULES = {
	"double_or_nothing": "Dobrar ou Nada - Valores extremos valem o dobro",
	"reverse_day": "Dia Reverso - Menores valores ganham",
	"biome_bonus": "Bônus de Bioma - Cartas do mesmo bioma ganham +10%",
	"rarity_matters": "Raridade Importa - Cartas raras têm vantagem",
	"elimination_mode": "Modo Eliminação - Cartas perdedoras são removidas",
	"random_characteristic": "Característica Aleatória - Sistema escolhe a característica",
	"all_or_nothing": "Tudo ou Nada - Apenas valores máximos e mínimos contam",
	"team_battle": "Batalha em Equipe - Múltiplas cartas por rodada"
}

func _ready():
	setup_custom_battle()
	back_button.pressed.connect(_on_back_button_pressed)

func setup_custom_battle():
	"""Configura a batalha personalizada"""
	show_rules_setup()

func show_rules_setup():
	"""Mostra a interface de configuração de regras"""
	rules_setup.visible = true
	battle_area.visible = false
	
	create_rules_interface()

func create_rules_interface():
	"""Cria a interface de configuração de regras"""
	# Limpar interface anterior
	for child in rules_setup.get_children():
		child.queue_free()
	
	var scroll = ScrollContainer.new()
	rules_setup.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "CONFIGURAÇÃO DE BATALHA PERSONALIZADA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Seção: Regras Básicas
	add_basic_rules_section(vbox)
	
	# Seção: Regras Especiais
	add_special_rules_section(vbox)
	
	# Seção: Restrições
	add_restrictions_section(vbox)
	
	# Botões de ação
	add_action_buttons(vbox)

func add_basic_rules_section(parent: VBoxContainer):
	"""Adiciona seção de regras básicas"""
	var section = create_section("Regras Básicas")
	parent.add_child(section)
	
	# Número de rodadas
	var rounds_container = HBoxContainer.new()
	section.add_child(rounds_container)
	
	var rounds_label = Label.new()
	rounds_label.text = "Número de Rodadas:"
	rounds_container.add_child(rounds_label)
	
	var rounds_spinbox = SpinBox.new()
	rounds_spinbox.min_value = 1
	rounds_spinbox.max_value = 10
	rounds_spinbox.value = custom_rules.max_rounds
	rounds_spinbox.value_changed.connect(func(value): custom_rules.max_rounds = int(value))
	rounds_container.add_child(rounds_spinbox)
	
	# Tamanho do deck
	var deck_container = HBoxContainer.new()
	section.add_child(deck_container)
	
	var deck_label = Label.new()
	deck_label.text = "Tamanho do Deck:"
	deck_container.add_child(deck_label)
	
	var deck_spinbox = SpinBox.new()
	deck_spinbox.min_value = 3
	deck_spinbox.max_value = 15
	deck_spinbox.value = custom_rules.deck_size
	deck_spinbox.value_changed.connect(func(value): custom_rules.deck_size = int(value))
	deck_container.add_child(deck_spinbox)
	
	# Banimentos por jogador
	var bans_container = HBoxContainer.new()
	section.add_child(bans_container)
	
	var bans_label = Label.new()
	bans_label.text = "Banimentos por Jogador:"
	bans_container.add_child(bans_label)
	
	var bans_spinbox = SpinBox.new()
	bans_spinbox.min_value = 0
	bans_spinbox.max_value = 4
	bans_spinbox.value = custom_rules.bans_per_player
	bans_spinbox.value_changed.connect(func(value): custom_rules.bans_per_player = int(value))
	bans_container.add_child(bans_spinbox)
	
	# Banimento do sistema
	var system_ban_check = CheckBox.new()
	system_ban_check.text = "Banimento Aleatório do Sistema"
	system_ban_check.button_pressed = custom_rules.system_ban_enabled
	system_ban_check.toggled.connect(func(pressed): custom_rules.system_ban_enabled = pressed)
	section.add_child(system_ban_check)
	
	# Limite de tempo
	var time_container = HBoxContainer.new()
	section.add_child(time_container)
	
	var time_label = Label.new()
	time_label.text = "Limite de Tempo por Turno (segundos):"
	time_container.add_child(time_label)
	
	var time_spinbox = SpinBox.new()
	time_spinbox.min_value = 10
	time_spinbox.max_value = 120
	time_spinbox.value = custom_rules.time_limit_per_turn
	time_spinbox.value_changed.connect(func(value): custom_rules.time_limit_per_turn = int(value))
	time_container.add_child(time_spinbox)

func add_special_rules_section(parent: VBoxContainer):
	"""Adiciona seção de regras especiais"""
	var section = create_section("Regras Especiais")
	parent.add_child(section)
	
	for rule_id in SPECIAL_RULES:
		var rule_check = CheckBox.new()
		rule_check.text = SPECIAL_RULES[rule_id]
		rule_check.toggled.connect(func(pressed):
			if pressed:
				if rule_id not in custom_rules.special_rules:
					custom_rules.special_rules.append(rule_id)
			else:
				custom_rules.special_rules.erase(rule_id)
		)
		section.add_child(rule_check)

func add_restrictions_section(parent: VBoxContainer):
	"""Adiciona seção de restrições"""
	var section = create_section("Restrições")
	parent.add_child(section)
	
	# Permitir duplicatas
	var duplicates_check = CheckBox.new()
	duplicates_check.text = "Permitir Cartas Duplicadas"
	duplicates_check.button_pressed = custom_rules.allow_duplicates
	duplicates_check.toggled.connect(func(pressed): custom_rules.allow_duplicates = pressed)
	section.add_child(duplicates_check)
	
	# Condição de vitória
	var win_condition_container = HBoxContainer.new()
	section.add_child(win_condition_container)
	
	var win_label = Label.new()
	win_label.text = "Condição de Vitória:"
	win_condition_container.add_child(win_label)
	
	var win_option = OptionButton.new()
	win_option.add_item("Melhor de X Rodadas")
	win_option.add_item("Eliminação")
	win_option.add_item("Sistema de Pontos")
	win_option.item_selected.connect(func(index):
		match index:
			0: custom_rules.win_condition = "best_of_rounds"
			1: custom_rules.win_condition = "elimination"
			2: custom_rules.win_condition = "points"
	)
	win_condition_container.add_child(win_option)

func add_action_buttons(parent: VBoxContainer):
	"""Adiciona botões de ação"""
	var buttons_container = HBoxContainer.new()
	parent.add_child(buttons_container)
	
	# Botão de preset
	var preset_button = Button.new()
	preset_button.text = "Carregar Preset"
	preset_button.pressed.connect(show_preset_menu)
	buttons_container.add_child(preset_button)
	
	# Botão de salvar preset
	var save_preset_button = Button.new()
	save_preset_button.text = "Salvar Preset"
	save_preset_button.pressed.connect(save_custom_preset)
	buttons_container.add_child(save_preset_button)
	
	# Botão de iniciar
	var start_button = Button.new()
	start_button.text = "Iniciar Batalha"
	start_button.pressed.connect(start_custom_battle)
	buttons_container.add_child(start_button)

func create_section(title: String) -> VBoxContainer:
	"""Cria uma seção com título"""
	var section = VBoxContainer.new()
	
	var section_title = Label.new()
	section_title.text = title
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(section_title)
	
	var separator = HSeparator.new()
	section.add_child(separator)
	
	return section

func show_preset_menu():
	"""Mostra menu de presets"""
	var preset_popup = AcceptDialog.new()
	preset_popup.title = "Presets de Batalha"
	preset_popup.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	preset_popup.add_child(vbox)
	
	var presets = get_battle_presets()
	
	for preset_name in presets:
		var preset_button = Button.new()
		preset_button.text = preset_name
		preset_button.pressed.connect(func():
			load_preset(presets[preset_name])
			preset_popup.queue_free()
		)
		vbox.add_child(preset_button)
	
	add_child(preset_popup)

func get_battle_presets() -> Dictionary:
	"""Retorna presets de batalha predefinidos"""
	return {
		"Clássico": {
			"max_rounds": 3,
			"deck_size": 5,
			"bans_per_player": 2,
			"system_ban_enabled": true,
			"special_rules": []
		},
		"Blitz": {
			"max_rounds": 1,
			"deck_size": 3,
			"bans_per_player": 1,
			"time_limit_per_turn": 15,
			"special_rules": []
		},
		"Caos Total": {
			"max_rounds": 5,
			"deck_size": 8,
			"bans_per_player": 0,
			"special_rules": ["double_or_nothing", "random_characteristic", "biome_bonus"]
		},
		"Estratégico": {
			"max_rounds": 5,
			"deck_size": 10,
			"bans_per_player": 4,
			"time_limit_per_turn": 60,
			"special_rules": ["rarity_matters"]
		}
	}

func load_preset(preset_rules: Dictionary):
	"""Carrega um preset de regras"""
	custom_rules = preset_rules.duplicate(true)
	create_rules_interface()  # Recriar interface com novos valores

func save_custom_preset():
	"""Salva um preset personalizado"""
	var save_dialog = AcceptDialog.new()
	save_dialog.title = "Salvar Preset"
	
	var vbox = VBoxContainer.new()
	save_dialog.add_child(vbox)
	
	var name_input = LineEdit.new()
	name_input.placeholder_text = "Nome do preset..."
	vbox.add_child(name_input)
	
	var save_button = Button.new()
	save_button.text = "Salvar"
	save_button.pressed.connect(func():
		if not name_input.text.is_empty():
			save_preset_to_file(name_input.text, custom_rules)
			save_dialog.queue_free()
	)
	vbox.add_child(save_button)
	
	add_child(save_dialog)

func save_preset_to_file(preset_name: String, rules: Dictionary):
	"""Salva preset em arquivo"""
	var file = FileAccess.open("user://custom_presets.json", FileAccess.WRITE)
	if file:
		var existing_presets = {}
		if FileAccess.file_exists("user://custom_presets.json"):
			var read_file = FileAccess.open("user://custom_presets.json", FileAccess.READ)
			var json_text = read_file.get_as_text()
			existing_presets = JSON.parse_string(json_text) or {}
		
		existing_presets[preset_name] = rules
		file.store_string(JSON.stringify(existing_presets))
		file.close()

func start_custom_battle():
	"""Inicia a batalha com regras personalizadas"""
	rules_setup.visible = false
	battle_area.visible = true
	
	# Criar batalha baseada nas regras personalizadas
	var battle_scene = create_custom_battle_scene()
	battle_area.add_child(battle_scene)

func create_custom_battle_scene() -> Control:
	"""Cria a cena de batalha personalizada"""
	var battle = load("res://BattleScene.tscn").instantiate()
	
	# Aplicar regras personalizadas
	battle.max_rounds = custom_rules.max_rounds
	battle.custom_rules = custom_rules
	
	# Conectar sinal de fim de batalha
	battle.battle_finished.connect(_on_custom_battle_finished)
	
	return battle

func apply_special_rules(battle_scene: Control):
	"""Aplica regras especiais à batalha"""
	for rule in custom_rules.special_rules:
		match rule:
			"double_or_nothing":
				battle_scene.enable_double_or_nothing()
			"reverse_day":
				battle_scene.enable_reverse_mode()
			"biome_bonus":
				battle_scene.enable_biome_bonus()
			"rarity_matters":
				battle_scene.enable_rarity_bonus()
			"elimination_mode":
				battle_scene.enable_elimination_mode()
			"random_characteristic":
				battle_scene.enable_random_characteristic()
			"all_or_nothing":
				battle_scene.enable_extreme_values_only()
			"team_battle":
				battle_scene.enable_team_mode()

func _on_custom_battle_finished(winner: int):
	"""Callback quando a batalha personalizada termina"""
	emit_signal("battle_finished", winner)
	
	var result_popup = AcceptDialog.new()
	result_popup.title = "Batalha Personalizada Concluída"
	result_popup.dialog_text = "Vencedor: Jogador %d!\n\nRegras utilizadas:\n%s" % [winner, format_rules_summary()]
	add_child(result_popup)
	
	result_popup.confirmed.connect(func():
		result_popup.queue_free()
		_on_back_button_pressed()
	)

func format_rules_summary() -> String:
	"""Formata um resumo das regras utilizadas"""
	var summary = ""
	summary += "- %d rodadas\n" % custom_rules.max_rounds
	summary += "- Deck de %d cartas\n" % custom_rules.deck_size
	summary += "- %d banimentos por jogador\n" % custom_rules.bans_per_player
	
	if not custom_rules.special_rules.is_empty():
		summary += "- Regras especiais: %s" % ", ".join(custom_rules.special_rules)
	
	return summary

func _on_back_button_pressed():
	"""Volta para o menu principal"""
	get_tree().change_scene_to_file("res://Menu.tscn")
