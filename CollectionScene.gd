# CollectionScene.gd
extends Node2D

signal card_inspected(card_data: Dictionary)

const CardScene = preload("res://Card.tscn")
const HOVER_ZOOM_FACTOR = 1.05

@onready var back_button = $BackButton
@onready var card_grid = $ScrollContainer/CardGrid
@onready var name_filter = $FilterBar/NameFilter
@onready var biome_filter = $FilterBar/BiomeFilter
@onready var rarity_style_filter = $FilterBar/RarityStyleFilter
@onready var sort_order = $FilterBar/SortOrder
@onready var clear_button = $ClearButton
@onready var scroll_container = $ScrollContainer
@onready var collection_scene = self

var CardViewerScene = preload("res://CardViewer3D.tscn")
var mainmenu = preload("res://Menu.tscn")
var all_cards = []
var currently_hovered_card: Card = null
var hovered_card: Card = null

func _ready():
	Global.flip_habilitado = false
	Global.hover_habilitado = true
	back_button.pressed.connect(_on_back_button_pressed)
	name_filter.text_changed.connect(_on_filters_changed)
	biome_filter.item_selected.connect(_on_filters_changed)
	rarity_style_filter.item_selected.connect(_on_filters_changed)
	sort_order.item_selected.connect(_on_filters_changed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	card_inspected.connect(self._on_card_inspected)
	
	all_cards = PlayerCollection.get_collection()
	card_grid.gui_input.connect(_input)
	
	_populate_filter_buttons()
	_update_display()
	set_process_input(true)
	
func _populate_filter_buttons():
	biome_filter.add_item("Todos os Biomas", 0)
	var biomas_unicos = []
	for card_data in all_cards:
		if card_data.has("bioma") and not card_data["bioma"] in biomas_unicos:
			biomas_unicos.append(card_data["bioma"])
	for bioma in biomas_unicos:
		biome_filter.add_item(bioma)
	
	rarity_style_filter.add_item("Todas as Raridades", 0)
	rarity_style_filter.add_item("Comum", 1)
	rarity_style_filter.add_item("Incomum", 2)
	rarity_style_filter.add_item("Rara", 3)
	rarity_style_filter.add_item("Lendária", 4)
	rarity_style_filter.add_separator("Anomalias")
	rarity_style_filter.add_item("Anomalia Incomum", 5)
	rarity_style_filter.add_item("Anomalia Rara", 6)
	rarity_style_filter.add_item("Anomalia Lendária", 7)
	rarity_style_filter.add_separator("Estilos")
	rarity_style_filter.add_item("Apenas Full Art", 8)
	rarity_style_filter.add_item("Apenas Hollow", 9)
	
	sort_order.add_item("Padrão", 0)
	sort_order.add_item("Peso (Maior para Menor)", 1)
	sort_order.add_item("Peso (Menor para Maior)", 2)
	sort_order.add_item("Altura (Maior para Menor)", 3)
	sort_order.add_item("Altura (Menor para Maior)", 4)
	sort_order.add_item("Comprimento (Maior para Menor)", 5)
	sort_order.add_item("Comprimento (Menor para Maior)", 6)
	sort_order.add_item("Velocidade (Maior para Menor)", 7)
	sort_order.add_item("Velocidade (Menor para Maior)", 8)

func _on_filters_changed(_value = 0):
	_update_display()

func _update_display():
	for child in card_grid.get_children():
		child.queue_free()
	
	var filtered_cards = _get_filtered_and_sorted_cards()
	
	for card_data in filtered_cards:
		var new_card = CardScene.instantiate() as Card
		card_grid.add_child(new_card)
		new_card.display_card_data(card_data)
		new_card.enable_flip(false)  # Desabilita flip na coleção
		new_card.is_face_up = true   # Mostra sempre a frente
		new_card.update_visibility() # Atualiza visualização

func _get_filtered_and_sorted_cards() -> Array:
	var filtered_cards = []
	var nome_filtro = name_filter.text.to_lower()
	var bioma_filtro = biome_filter.get_item_text(biome_filter.selected)
	var rarity_style_filtro_id = rarity_style_filter.get_item_id(rarity_style_filter.selected)

	for card_data in all_cards:
		var passa_nome = nome_filtro.is_empty() or (card_data.has("nome_display") and card_data["nome_display"].to_lower().contains(nome_filtro))
		var passa_bioma = biome_filter.selected == 0 or (card_data.has("bioma") and card_data["bioma"] == bioma_filtro)
		
		var passa_raridade_estilo = false
		if rarity_style_filtro_id <= 7:
			var rarity_text = rarity_style_filter.get_item_text(rarity_style_filter.selected)
			passa_raridade_estilo = rarity_style_filtro_id == 0 or (card_data.has("raridade") and card_data["raridade"] == rarity_text)
		elif rarity_style_filtro_id == 8:
			passa_raridade_estilo = card_data.get("is_full_art", false)
		elif rarity_style_filtro_id == 9:
			passa_raridade_estilo = card_data.get("is_hollow", false)
		
		if passa_nome and passa_bioma and passa_raridade_estilo:
			filtered_cards.append(card_data)
			
	var sort_idx = sort_order.selected
	if sort_idx > 0:
		var sort_key = ""
		match sort_idx:
			1, 2: sort_key = "peso"
			3, 4: sort_key = "altura"
			5, 6: sort_key = "comprimento"
			7, 8: sort_key = "velocidade"
		
		var is_descending = sort_idx % 2 != 0
		filtered_cards.sort_custom(func(a, b):
			if is_descending:
				return a.get(sort_key, 0) > b.get(sort_key, 0)
			else:
				return a.get(sort_key, 0) < b.get(sort_key, 0)
		)
		
	return filtered_cards

func _on_card_inspected(card_data: Dictionary):
	if find_child("CardViewer3D", true, false):
		print("Visualizador já está aberto.")
		return
	
	# Oculta a carta que foi clicada
	if is_instance_valid(hovered_card):
		hovered_card.visible = false
	
	var viewer = CardViewerScene.instantiate()
	viewer.viewer_opened.connect(_on_viewer_opened)
	add_child(viewer)
	viewer.name = "CardViewer3D"
	viewer.card_data = card_data
	viewer.tree_exiting.connect(_on_viewer_closed)
	
	viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
func _on_viewer_opened():
	# Hide and disable the entire grid
	$ScrollContainer/CardGrid.visible = false
	$ScrollContainer/CardGrid.process_mode = Node.PROCESS_MODE_DISABLED
	process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	# Processar eventos de mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_card_click()

func _process(_delta):
	# Não processar hover se a cena estiver invisível/desativada
	if not visible or process_mode == Node.PROCESS_MODE_DISABLED:
		return
	
	# Restante do seu código de hover...
	var mouse_pos = get_global_mouse_position()
	var new_hovered_card: Card = null
	
	for node in card_grid.get_children():
		if node is Card and node.visible:
			var rect = node.get_global_rect()
			if rect.has_point(mouse_pos):
				new_hovered_card = node
				break
	
	if new_hovered_card != hovered_card:
		if is_instance_valid(hovered_card):
			hovered_card._hover_effect(false, HOVER_ZOOM_FACTOR)
		
		if is_instance_valid(new_hovered_card):
			new_hovered_card._hover_effect(true, HOVER_ZOOM_FACTOR)
		
		hovered_card = new_hovered_card
		
func _handle_card_click():
	if is_instance_valid(hovered_card):
		print("Carta clicada: ", hovered_card.animal_id)
		var card_data = hovered_card.get_card_data()
		_open_card_viewer(card_data)

func _open_card_viewer(card_data: Dictionary):
	print("Abrindo visualizador para: ", card_data.get("nome_display", "Desconhecido"))
	
	var existing_viewer = find_child("CardViewer3D", true, false)
	if existing_viewer:
		existing_viewer.queue_free()
	
	# Oculta o INFERNO da carta que fica na frente de tudo -- Não remover --
	if is_instance_valid(hovered_card):
		hovered_card.visible = false
	
	var viewer = CardViewerScene.instantiate()
	viewer.name = "CardViewer3D"
	viewer.card_data = card_data
	viewer.tree_exiting.connect(_on_viewer_closed)
	add_child(viewer)
	
	print("Visualizador criado com sucesso!")

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_instance_valid(currently_hovered_card) and currently_hovered_card is Card:
			var card_data = currently_hovered_card.get_card_data()
			if card_data and not card_data.is_empty():
				# Emitir o sinal diretamente
				_on_card_inspected(card_data)
			else:
				printerr("Dados da carta inválidos para: ", currently_hovered_card)
	
func _on_viewer_closed():
	print("Visualizador fechado - CollectionScene restaurada")
	# Mostrar a CollectionScene novamente
	visible = true
	
	# Restaurar visibilidade da carta que foi ocultada
	if is_instance_valid(hovered_card):
		hovered_card.visible = true
	
	# Reativar processamento
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	
	# Atualizar a exibição se necessário
	_update_display()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")

func _on_clear_button_pressed():
	PlayerCollection.clear_collection()
	call_deferred("_reload_scene")

func _reload_scene():
	get_tree().change_scene_to_file("res://CollectionScene.tscn")
