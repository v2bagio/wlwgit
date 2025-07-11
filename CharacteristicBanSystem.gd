# CharacteristicBanSystem.gd - Sistema de banimento de características
extends Control

signal banning_phase_completed(player1_bans: Array, player2_bans: Array, system_ban: String)
signal player_ban_selected(player_id: int, banned_characteristics: Array)

const CHARACTERISTICS = ["altura", "comprimento", "velocidade", "peso"]
const CHARACTERISTIC_NAMES = {
	"altura": "Altura",
	"comprimento": "Comprimento",
	"velocidade": "Velocidade", 
	"peso": "Peso"
}

const CHARACTERISTIC_DESCRIPTIONS = {
	"altura": "Altura do animal em metros",
	"comprimento": "Comprimento do animal em metros",
	"velocidade": "Velocidade máxima em km/h",
	"peso": "Peso do animal em quilogramas"
}

const CHARACTERISTIC_ICONS = {
	"altura": "res://assets/icons/height_icon.png",
	"comprimento": "res://assets/icons/length_icon.png", 
	"velocidade": "res://assets/icons/speed_icon.png",
	"peso": "res://assets/icons/weight_icon.png"
}

# Nós da interface
@onready var ban_interface = $BanInterface
@onready var player_name_label = $BanInterface/PlayerNameLabel
@onready var instruction_label = $BanInterface/InstructionLabel
@onready var characteristics_grid = $BanInterface/CharacteristicsGrid
@onready var selected_bans_display = $BanInterface/SelectedBansDisplay
@onready var confirm_button = $BanInterface/ConfirmButton
@onready var timer_label = $BanInterface/TimerLabel
@onready var progress_bar = $BanInterface/ProgressBar

# Variáveis de estado
var current_player: int = 1
var max_bans_per_player: int = 2
var player1_bans: Array = []
var player2_bans: Array = []
var system_ban: String = ""
var selected_bans: Array = []
var ban_timer: float = 30.0
var time_remaining: float = 30.0
var is_timer_active: bool = false

# Configurações visuais
var characteristic_buttons: Array = []

func _ready():
	setup_interface()
	connect_signals()

func _process(delta):
	if is_timer_active:
		time_remaining -= delta
		update_timer_display()
		
		if time_remaining <= 0:
			auto_select_bans()

func setup_interface():
	"""Configura a interface inicial do sistema de banimento"""
	create_characteristic_buttons()
	update_interface_for_current_player()
	
	confirm_button.disabled = false
	confirm_button.pressed.connect(_on_confirm_button_pressed)

func create_characteristic_buttons():
	"""Cria os botões para cada característica"""
	characteristic_buttons.clear()
	
	# Limpar grid existente
	for child in characteristics_grid.get_children():
		child.queue_free()
	
	for characteristic in CHARACTERISTICS:
		var button_container = create_characteristic_button(characteristic)
		characteristics_grid.add_child(button_container)

func create_characteristic_button(characteristic: String) -> Control:
	"""Cria um botão para uma característica específica"""
	var container = VBoxContainer.new()
	
	# Botão principal
	var button = Button.new()
	button.custom_minimum_size = Vector2(150, 100)
	button.text = CHARACTERISTIC_NAMES[characteristic]
	button.toggle_mode = true
	
	# Ícone da característica
	var icon = TextureRect.new()
	icon.texture = load(CHARACTERISTIC_ICONS.get(characteristic, ""))
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.custom_minimum_size = Vector2(32, 32)
	
	# Descrição
	var description = Label.new()
	description.text = CHARACTERISTIC_DESCRIPTIONS[characteristic]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Conectar sinal
	button.toggled.connect(func(pressed: bool): _on_characteristic_button_toggled(characteristic, pressed))
	
	container.add_child(icon)
	container.add_child(button)
	container.add_child(description)
	
	characteristic_buttons.append({
		"characteristic": characteristic,
		"button": button,
		"container": container
	})
	
	return container

func connect_signals():
	"""Conecta os sinais necessários"""
	player_ban_selected.connect(_on_player_ban_selected)

func start_banning_phase(bans_per_player: int = 2, time_limit: float = 30.0):
	"""Inicia a fase de banimento"""
	max_bans_per_player = bans_per_player
	ban_timer = time_limit
	time_remaining = time_limit
	
	current_player = 1
	player1_bans.clear()
	player2_bans.clear()
	system_ban = ""
	
	reset_interface()
	show_banning_interface()

func show_banning_interface():
	"""Mostra a interface de banimento"""
	ban_interface.visible = true
	update_interface_for_current_player()
	start_timer()

func update_interface_for_current_player():
	"""Atualiza a interface para o jogador atual"""
	player_name_label.text = "Jogador %d" % current_player
	instruction_label.text = "Selecione %d características para banir:" % max_bans_per_player
	
	selected_bans.clear()
	update_selected_bans_display()
	update_button_states()
	
	confirm_button.disabled = true

func reset_interface():
	"""Reseta a interface para o estado inicial"""
	selected_bans.clear()
	
	for button_data in characteristic_buttons:
		button_data.button.button_pressed = false
		button_data.button.disabled = false
	
	update_selected_bans_display()

func start_timer():
	"""Inicia o timer para o jogador atual"""
	time_remaining = ban_timer
	is_timer_active = true
	update_timer_display()

func stop_timer():
	"""Para o timer"""
	is_timer_active = false

func update_timer_display():
	"""Atualiza a exibição do timer"""
	timer_label.text = "Tempo restante: %d segundos" % int(time_remaining)
	progress_bar.value = (time_remaining / ban_timer) * 100

func _on_characteristic_button_toggled(characteristic: String, pressed: bool):
	"""Callback para quando um botão de característica é pressionado"""
	if pressed:
		if selected_bans.size() < max_bans_per_player:
			selected_bans.append(characteristic)
		else:
			# Desmarcar o botão se já temos o máximo
			var button_data = get_button_data(characteristic)
			if button_data:
				button_data.button.button_pressed = false
			return
	else:
		selected_bans.erase(characteristic)
	
	update_selected_bans_display()
	update_button_states()
	
	confirm_button.disabled = selected_bans.size() != max_bans_per_player

func get_button_data(characteristic: String) -> Dictionary:
	"""Obtém os dados do botão para uma característica"""
	for button_data in characteristic_buttons:
		if button_data.characteristic == characteristic:
			return button_data
	return {}

func update_selected_bans_display():
	"""Atualiza a exibição das características selecionadas"""
	if selected_bans.is_empty():
		selected_bans_display.text = "Nenhuma característica selecionada"
	else:
		var display_names = selected_bans.map(func(c): return CHARACTERISTIC_NAMES[c])
		selected_bans_display.text = "Selecionadas: " + ", ".join(display_names)

func update_button_states():
	"""Atualiza o estado dos botões baseado nas seleções"""
	var max_reached = selected_bans.size() >= max_bans_per_player
	
	for button_data in characteristic_buttons:
		var characteristic = button_data.characteristic
		var button = button_data.button
		
		if not button.button_pressed and max_reached:
			button.disabled = true
		else:
			button.disabled = false

func _on_confirm_button_pressed():
	"""Callback para quando o botão de confirmação é pressionado"""
	if selected_bans.size() == max_bans_per_player:
		process_player_bans()

func process_player_bans():
	"""Processa os banimentos do jogador atual"""
	stop_timer()
	
	if current_player == 1:
		player1_bans = selected_bans.duplicate()
		emit_signal("player_ban_selected", 1, player1_bans)
		transition_to_player2()
	else:
		player2_bans = selected_bans.duplicate()
		emit_signal("player_ban_selected", 2, player2_bans)
		process_system_ban()

func transition_to_player2():
	"""Transição para o jogador 2"""
	current_player = 2
	reset_interface()
	update_interface_for_current_player()
	start_timer()

func process_system_ban():
	"""Processa o banimento aleatório do sistema"""
	var available_for_system_ban = []
	
	for characteristic in CHARACTERISTICS:
		if characteristic not in player1_bans and characteristic not in player2_bans:
			available_for_system_ban.append(characteristic)
	
	if not available_for_system_ban.is_empty():
		system_ban = available_for_system_ban.pick_random()
	
	finalize_banning_phase()

func finalize_banning_phase():
	"""Finaliza a fase de banimento"""
	ban_interface.visible = false
	show_banning_results()

func show_banning_results():
	"""Mostra os resultados do banimento"""
	var results_popup = create_results_popup()
	add_child(results_popup)

func create_results_popup() -> AcceptDialog:
	"""Cria o popup com os resultados do banimento"""
	var popup = AcceptDialog.new()
	popup.title = "Resultados do Banimento"
	popup.size = Vector2(500, 400)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "Características Banidas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Banimentos do Jogador 1
	var p1_label = Label.new()
	p1_label.text = "Jogador 1: " + ", ".join(player1_bans.map(func(c): return CHARACTERISTIC_NAMES[c]))
	vbox.add_child(p1_label)
	
	# Banimentos do Jogador 2
	var p2_label = Label.new()
	p2_label.text = "Jogador 2: " + ", ".join(player2_bans.map(func(c): return CHARACTERISTIC_NAMES[c]))
	vbox.add_child(p2_label)
	
	# Banimento do Sistema
	var system_label = Label.new()
	system_label.text = "Sistema: " + CHARACTERISTIC_NAMES.get(system_ban, "Nenhuma")
	vbox.add_child(system_label)
	
	# Características Ativas
	var active_characteristics = get_active_characteristics()
	var active_label = Label.new()
	active_label.text = "Características Ativas: " + ", ".join(active_characteristics.map(func(c): return CHARACTERISTIC_NAMES[c]))
	vbox.add_child(active_label)
	
	popup.confirmed.connect(func():
		popup.queue_free()
		emit_signal("banning_phase_completed", player1_bans, player2_bans, system_ban)
	)
	
	return popup

func auto_select_bans():
	"""Seleciona banimentos automaticamente quando o tempo acaba"""
	stop_timer()
	
	var available_characteristics = []
	for characteristic in CHARACTERISTICS:
		if characteristic not in selected_bans:
			available_characteristics.append(characteristic)
	
	# Selecionar aleatoriamente as características restantes
	while selected_bans.size() < max_bans_per_player and not available_characteristics.is_empty():
		var random_characteristic = available_characteristics.pick_random()
		selected_bans.append(random_characteristic)
		available_characteristics.erase(random_characteristic)
		
		# Atualizar interface
		var button_data = get_button_data(random_characteristic)
		if button_data:
			button_data.button.button_pressed = true
	
	update_selected_bans_display()
	process_player_bans()

func get_active_characteristics() -> Array:
	"""Retorna as características que não foram banidas"""
	var active = []
	var all_bans = player1_bans + player2_bans + [system_ban]
	
	for characteristic in CHARACTERISTICS:
		if characteristic not in all_bans:
			active.append(characteristic)
	
	return active

func get_banned_characteristics() -> Array:
	"""Retorna todas as características banidas"""
	return player1_bans + player2_bans + [system_ban]

func _on_player_ban_selected(player_id: int, banned_characteristics: Array):
	"""Callback para quando um jogador seleciona seus banimentos"""
	print("Jogador %d baniu: %s" % [player_id, banned_characteristics])

# Funções utilitárias para integração com outros sistemas

func export_ban_data() -> Dictionary:
	"""Exporta os dados de banimento para uso em outras cenas"""
	return {
		"player1_bans": player1_bans,
		"player2_bans": player2_bans,
		"system_ban": system_ban,
		"active_characteristics": get_active_characteristics(),
		"banned_characteristics": get_banned_characteristics()
	}

func import_ban_data(data: Dictionary):
	"""Importa dados de banimento de outras cenas"""
	player1_bans = data.get("player1_bans", [])
	player2_bans = data.get("player2_bans", [])
	system_ban = data.get("system_ban", "")

func reset_banning_system():
	"""Reseta o sistema de banimento para um novo jogo"""
	player1_bans.clear()
	player2_bans.clear()
	system_ban = ""
	selected_bans.clear()
	current_player = 1
	stop_timer()
	reset_interface()
