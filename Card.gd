# Card.gd (Versão final corrigida e mais robusta)
class_name Card
extends Control

signal card_clicked(card_data)

signal fully_drawn

var unique_id: String
var animal_id: String
var iucn_status: String
var bioma: String
var altura: float
var comprimento: float
var velocidade: float
var peso: float
var raridade: String
var imagem_path: String
var background_path: String
var artist: String
var description: String
var is_full_art = false
var is_hollow = false
var is_face_up = false
var hollow_offset: float = 0.0
var stored_card_data: Dictionary = {}
var flip_habilitado = false
var is_locked = false

@onready var card_background = $CardBackground
@onready var full_art_border = $FullArtBorder
@onready var hollow_effect = $HollowEffect
@onready var full_art_background = $FullArtBackground
@onready var card_border = $CardBorder
@onready var rarity_gem = $RarityGem
@onready var card_face = $CardFace
@onready var card_back = $CardBack
@onready var nome_label = $CardFace/NomeLabel
@onready var foto_frame = $CardFace/FotoFrame
@onready var foto_animal = $CardFace/FotoFrame/FotoAnimal
@onready var status_dot = $CardFace/FotoFrame/FotoAnimal/StatusDot
@onready var poderes_box = $CardFace/PoderesBox

const CORES_IUCN = {"LC": Color.GREEN, "NT": Color.YELLOW, "EN": Color.ORANGE_RED}
const CORES_BIOMA = {"Floresta": Color.DARK_GREEN, "Pantanoso": Color.SADDLE_BROWN, "Mata Atlântica": Color.FOREST_GREEN, "Cerrado": Color.DARK_ORANGE, "Caatinga": Color.GOLDENROD, "Pampa": Color.PALE_GREEN, "Amazônia": Color.DARK_GREEN}
const CORES_RARIDADE = {
	"Comum": Color.GRAY,
	"Incomum": Color.LIME_GREEN,
	"Rara": Color.DODGER_BLUE,
	"Lendária": Color.MEDIUM_PURPLE,
	"Anomalia Incomum": Color.PALE_VIOLET_RED,
	"Anomalia Rara": Color.ORANGE_RED,
	"Anomalia Lendária": Color.GOLD
}
const EXTREME_THRESHOLD = 0.15

func _ready():
	self.custom_minimum_size = Vector2(190, 280)
	self.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	self.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	self.mouse_filter = Control.MOUSE_FILTER_STOP  # Garante captura de clique
	
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	
	var verso_texture = _load_texture_safely("res://assets/ui/card_back.jpg")
	if verso_texture == null:
		verso_texture = _load_texture_safely("res://assets/ui/card_back.png")

	if verso_texture:
		card_back.texture = verso_texture
		card_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	full_art_background.hide()
	update_visibility()

func setup(p_animal_id: String, p_is_full_art: bool = false, p_is_hollow: bool = false, p_use_alt_art: bool = false):
	stored_card_data = AnimalDatabase.get_animal_data(p_animal_id)
	if stored_card_data.is_empty(): 
		printerr("Dados do animal não encontrados para ID: ", p_animal_id)
		return

	self.animal_id = p_animal_id
	self.is_full_art = p_is_full_art
	self.is_hollow = p_is_hollow
	self.unique_id = str(hash(Time.get_ticks_usec() + randi())) + animal_id
	self.description = stored_card_data.get("descricao", "Nenhuma descrição disponível.")

	var art_data = ArtManager.get_random_art(p_animal_id, p_use_alt_art)
	self.imagem_path = art_data.get("path", "")
	self.artist = art_data.get("artist", "Artista Desconhecido")

	var possible_biomes = stored_card_data.get("bioma", [])
	self.bioma = possible_biomes.pick_random() if not possible_biomes.is_empty() else "Desconhecido"
	self.background_path = AnimalDatabase.get_random_background(self.bioma)
	
	# Antes de chamar display_card_data, garanta que nome_label.text tenha um valor
	nome_label.text = stored_card_data.get("nome_display", "N/A") # Definir aqui
	
	display_card_data(get_card_data())
	
	var archetype_matches = 0
	var archetype_mismatches = 0
	var result = _gerar_e_preencher_poder("Altura:", stored_card_data.get("altura", {}), poderes_box.get_child(0), "altura")
	if result == 1: archetype_matches += 1
	elif result == -1: archetype_mismatches += 1
	result = _gerar_e_preencher_poder("Comprimento:", stored_card_data.get("comprimento", {}), poderes_box.get_child(1), "comprimento")
	if result == 1: archetype_matches += 1
	elif result == -1: archetype_mismatches += 1
	result = _gerar_e_preencher_poder("Velocidade:", stored_card_data.get("velocidade", {}), poderes_box.get_child(2), "velocidade")
	if result == 1: archetype_matches += 1
	elif result == -1: archetype_mismatches += 1
	result = _gerar_e_preencher_poder("Peso:", stored_card_data.get("peso", {}), poderes_box.get_child(3), "peso")
	if result == 1: archetype_matches += 1
	elif result == -1: archetype_mismatches += 1
		
	_determine_and_apply_rarity(archetype_matches, archetype_mismatches)

	# nome_label.text = stored_card_data.get("nome_display", "N/A") # Removido daqui
	foto_animal.texture = _load_texture_safely(self.imagem_path)
	card_background.texture = _load_texture_safely(self.background_path)
	_set_frame_color(self.bioma)
	_set_status_dot_color(stored_card_data.get("iucn_status", ""))
	
	apply_visual_treatments()

	emit_signal("fully_drawn")

func display_card_data(card_data: Dictionary):
	self.unique_id = card_data.get("unique_id", "")
	self.animal_id = card_data.get("animal_id", "")
	self.raridade = card_data.get("raridade", "Comum")
	self.imagem_path = card_data.get("imagem_path", "")
	self.background_path = card_data.get("background_path", "")
	self.is_full_art = card_data.get("is_full_art", false)
	self.is_hollow = card_data.get("is_hollow", false)
	self.bioma = card_data.get("bioma", "Desconhecido")
	self.iucn_status = card_data.get("iucn_status", "")
	self.artist = card_data.get("artist", "Artista Desconhecido")
	self.description = card_data.get("description", "Nenhuma descrição disponível.")
	
	self.altura = card_data.get("altura", 0.0)
	self.comprimento = card_data.get("comprimento", 0.0)
	self.velocidade = card_data.get("velocidade", 0.0)
	self.peso = card_data.get("peso", 0.0)

	nome_label.text = card_data.get("nome_display", "N/A")
	foto_animal.texture = _load_texture_safely(self.imagem_path)
	card_background.texture = _load_texture_safely(self.background_path)

	(poderes_box.get_child(0) as Label).text = "Altura: %.2f m" % card_data.get("altura", 0.0)
	(poderes_box.get_child(1) as Label).text = "Comprimento: %.2f m" % card_data.get("comprimento", 0.0)
	(poderes_box.get_child(2) as Label).text = "Velocidade: %.2f km/h" % card_data.get("velocidade", 0.0)
	(poderes_box.get_child(3) as Label).text = "Peso: %.2f kg" % card_data.get("peso", 0.0)

	_set_status_dot_color(self.iucn_status)
	_set_frame_color(self.bioma)
	_apply_rarity_gem_color(self.raridade)
	apply_visual_treatments()

	_set_status_dot_color(card_data.get("iucn_status", ""))
	_set_frame_color(bioma)
	_apply_rarity_gem_color(raridade)
	apply_visual_treatments()
	
func get_card_data() -> Dictionary:
	var data_card = {
		"unique_id": unique_id,
		"animal_id": animal_id,
		"nome_display": nome_label.text,
		"imagem_path": imagem_path,
		"iucn_status": iucn_status,
		"bioma": bioma,
		"raridade": raridade,
		"altura": altura,
		"comprimento": comprimento,
		"velocidade": velocidade,
		"peso": peso,
		"is_full_art": is_full_art,
		"is_hollow": is_hollow,
		"background_path": background_path,
		"artist": artist,
		"description": description
	}
	if data_card.get("animal_id", "").is_empty():
		printerr("Dados da carta incompletos para: ", self.name)
	
	return data_card

func _load_texture_safely(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var resource = ResourceLoader.load(path)
		if resource is Texture2D:
			return resource
		else:
			printerr("Recurso no caminho \'", path, "\' não é uma Texture2D.")
			return null
	if FileAccess.file_exists(path):
		var image = Image.load_from_file(path)
		if image:
			return ImageTexture.create_from_image(image)
		else:
			printerr("Arquivo em \'", path, "\' existe, mas não pôde ser carregado como Imagem.")
			return null
	printerr("Falha ao carregar textura. Caminho não encontrado: \'", path, "\' ")
	return null

func enable_flip(enabled: bool):
	flip_habilitado = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if enabled: _animar_flip()
	else:
		return
	
@warning_ignore("unused_parameter")
func _animar_flip(animated: bool = false):
	if is_face_up: return
	is_face_up = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	pivot_offset = size / 2
	tween.tween_property(self, "scale", Vector2(0, 0.9), 0.2)
	tween.tween_callback(update_visibility)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2)

func update_visibility():
	card_back.visible = not is_face_up
	card_face.visible = is_face_up
	rarity_gem.visible = is_face_up

func apply_visual_treatments():
	if is_full_art:
		full_art_border.show()
		card_face.hide()
		card_border.hide()
		foto_frame.hide()
		foto_animal.hide()
		full_art_background.show()
		if foto_animal.texture:
			full_art_background.texture = foto_animal.texture
		full_art_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		full_art_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		full_art_border.hide()
		card_face.show()
	if is_hollow:
		hollow_effect.modulate.a = 1.0
		hollow_effect.visible = is_hollow
		var gradient = Gradient.new()
		gradient.offsets = [0.0, 0.4, 0.6, 1.0]
		gradient.colors = [Color(1,1,1,0), Color(1,1,1,0.25), Color(1,1,1,0.25), Color(1,1,1,0)]
		var gradient_texture = GradientTexture1D.new()
		gradient_texture.gradient = gradient
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://hollow_shader.gdshader")
		shader_material.set_shader_parameter("gradient", gradient_texture)
		hollow_effect.material = shader_material
		var tween = create_tween().set_loops()
		tween.tween_property(self, "hollow_offset", 1.0, 2.0).from(0.0)

func _determine_and_apply_rarity(match_count: int, mismatch_count: int):
	if match_count == 4: self.raridade = "Lendária"
	elif mismatch_count == 4: self.raridade = "Anomalia Lendária"
	elif mismatch_count == 3: self.raridade = "Anomalia Rara"
	elif match_count == 3: self.raridade = "Rara"
	elif mismatch_count == 2: self.raridade = "Anomalia Incomum"
	elif match_count == 2: self.raridade = "Incomum"
	else: self.raridade = "Comum"
	_apply_rarity_gem_color(self.raridade)

func _apply_rarity_gem_color(rarity_string: String):
	var cor = CORES_RARIDADE.get(rarity_string, Color.WHITE)
	var gem_style_instance = rarity_gem.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if gem_style_instance:
		gem_style_instance.bg_color = cor
		rarity_gem.add_theme_stylebox_override("panel", gem_style_instance)

func _set_frame_color(p_bioma: String):
	bioma = p_bioma
	var cor = CORES_BIOMA.get(p_bioma, Color.BLACK)
	var style = foto_frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = cor
	foto_frame.add_theme_stylebox_override("panel", style)

func _set_status_dot_color(p_status: String):
	iucn_status = p_status
	var cor = CORES_IUCN.get(p_status, Color.WHITE)
	var style_instance = status_dot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style_instance:
		style_instance.bg_color = cor
		status_dot.add_theme_stylebox_override("panel", style_instance)

func _gerar_e_preencher_poder(titulo: String, dados_poder: Dictionary, label_node: Label, stat_name: String) -> int:
	var valor_aleatorio = 0.0
	var extreme_type = 0
	if dados_poder:
		var min_val = dados_poder.get("min", 0.0)
		var max_val = dados_poder.get("max", 0.0)
		var archetype = dados_poder.get("archetype", "HIGH")
		
		valor_aleatorio = randf_range(min_val, max_val)
		var stat_range = max_val - min_val
		
		if stat_range > 0:
			var threshold_value = stat_range * EXTREME_THRESHOLD
			var high_extreme = valor_aleatorio >= max_val - threshold_value
			var low_extreme = valor_aleatorio <= min_val + threshold_value
			
			if high_extreme: extreme_type = 1 if archetype == "HIGH" else -1
			elif low_extreme: extreme_type = 1 if archetype == "LOW" else -1
		
		label_node.text = "%s %.2f %s" % [titulo, valor_aleatorio, dados_poder.get("unidade", "")]
	else:
		label_node.text = titulo + " N/A"
	
	set(stat_name, valor_aleatorio)
	return extreme_type

func _on_mouse_entered():
	if Global.hover_habilitado:
		_hover_effect(true, 1.05)

func _on_mouse_exited():
	if Global.hover_habilitado:
		_hover_effect(false, 1.05)

func _hover_effect(is_hovered: bool, zoom_factor: float):
	# Verifica se o visualizador está aberto (via singleton Global)
	if Global.viewer_opened:
		return
	var target_scale = Vector2.ONE
	if is_hovered:
		target_scale = Vector2(zoom_factor, zoom_factor)
		z_index = 10
	else:
		z_index = 0
	pivot_offset = size / 2
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", target_scale, 0.1).set_trans(Tween.TRANS_SINE)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if flip_habilitado:
			# Modo PackOpening - flip normal
			emit_signal("card_clicked", _animar_flip(), get_card_data())
		else:
			# Modo Collection - pede inspeção
			emit_signal("inspection_requested", get_card_data())
