# CardViewer3D.gd - Versão Corrigida e mais Robusta
extends Control

signal viewer_opened

@onready var sub_viewport = $ViewportContainer/SubViewport
@onready var card_mesh = $ViewportContainer/SubViewport/CardMesh
@onready var card_mesh2 = $ViewportContainer/SubViewport/CardMesh2
@onready var camera = $ViewportContainer/SubViewport/Camera3D
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var artist_label = $MarginContainer/VBoxContainer/ArtistLabel
@onready var close_button = $CloseButton
@onready var card_front_renderer = $CardFrontRenderer

const CardScene = preload("res://Card.tscn")
const ZOOM_SENSITIVITY = 0.2
const MIN_CAMERA_DISTANCE = 1.0
const MAX_CAMERA_DISTANCE = 5.0

var rotating_automatically = true
var camera_distance = 2.8
var initial_camera_position: Vector3
var rotation_speed = 1.0
var user_rotation = Vector2.ZERO
var card_data: Dictionary = {}
var front_texture: Texture2D

func _ready():
	#var material_front = StandardMaterial3D.new()
	#var material_back = StandardMaterial3D.new()
	#var texture_front = load("res://assets/normal/capivara1.jpg") as Texture2D
	#var texture_back = load("res://assets/ui/card_back.png") as Texture2D
	#material_front.albedo_texture = texture_front
	#material_back.albedo_texture = texture_back
	#$ViewportContainer/SubViewport/CardMesh2.set_surface_override_material(1, material_front)
	#$ViewportContainer/SubViewport/CardMesh2.set_surface_override_material(0, material_back)
	# Freeze the game and hide all cards
	get_tree().paused = true
	for card in get_tree().get_nodes_in_group("cards"):
		card.visible = false
		card.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Rest of your initialization...
	Global.viewer_opened = true
	top_level = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_lighting()
	$TextureRect/BackGroundDim.gui_input.connect(_on_bg_gui_input)
	$ViewportContainer.gui_input.connect(_on_viewport_gui_input)
	$ViewportContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(_on_close_pressed)
	emit_signal("viewer_opened")
	_create_card_mesh_with_correct_aspect_ratio()
	if not card_data.is_empty():
		call_deferred("initialize_viewer")
	set_process_input(true)
	initial_camera_position = camera.position
	_update_camera_position()
	_on_viewer_opened()
	
func _process(delta):
	if not is_instance_valid(card_mesh): return
	
	if rotating_automatically:
		card_mesh.rotation.y += rotation_speed * delta * 0.5
		card_mesh2.rotation.y += rotation_speed * delta * 0.5
	else:
		var target_rot = Vector3(deg_to_rad(-user_rotation.y), deg_to_rad(user_rotation.x), 0)
		card_mesh.rotation = card_mesh.rotation.lerp(target_rot, delta * 10.0)
		card_mesh2.rotation = card_mesh2.rotation.lerp(target_rot, delta * 10.0)

	
func initialize_viewer():
	print("Inicializando visualizador com dados: ", card_data)
	
	if card_data.is_empty():
		printerr("Nenhum dado de carta disponível para o CardViewer3D!")
		return
	
	setup_card(card_data)

func setup_card(bcard_data: Dictionary):
	print("Configurando carta: ", bcard_data.get("nome_display", "Desconhecido"))
	var material_front = StandardMaterial3D.new()
	var material_back = StandardMaterial3D.new()
	var texture_front = load(bcard_data.get("imagem_path", "Path Inválido para a Imagem (frente)")) as Texture2D
	#var texture_front = load("res://assets/ui/armadeira.png") as Texture2D
	material_front.uv1_scale = Vector3(-1, 1, 1)
	print("TEXTURAAAAAAAAAAAAAAAAAA", bcard_data.get("imagem_path", "Path Inválido para a Imagem (frente)"))
	var texture_back = load("res://assets/ui/card_back.png") as Texture2D
	material_front.albedo_texture = texture_front
	material_back.albedo_texture = texture_back
	$ViewportContainer/SubViewport/CardMesh2.set_surface_override_material(1, material_front)
	$ViewportContainer/SubViewport/CardMesh2.set_surface_override_material(0, material_back)
	title_label.text = bcard_data.get("nome_display", "Nome Indisponível")
	description_label.text = bcard_data.get("description", "Descrição não disponível.")
	artist_label.text = "Arte por: " + bcard_data.get("artist", "Desconhecido")
	front_texture = await _render_card_to_texture(bcard_data)
	var back_texture = _load_card_back_texture()
	
	var front_material = _create_card_material(front_texture)
	var back_material = _create_card_material(back_texture)
	var edge_material = _create_edge_material()
	
	if card_mesh.mesh and card_mesh.mesh.get_surface_count() >= 6:
		card_mesh.set_surface_override_material(0, front_material)
		card_mesh.set_surface_override_material(1, back_material)
		for i in range(2, 6):
			card_mesh.set_surface_override_material(i, edge_material)

	card_mesh.rotation_degrees = Vector3(-15, 0, 0)
	card_mesh.position = Vector3(0, 0, 0)
	rotating_automatically = true
	card_mesh2.rotation_degrees = Vector3(-15, 0, 0)
	card_mesh2.position = Vector3(0, 0, 0)
	rotating_automatically = true

func _render_card_to_texture(data: Dictionary) -> Texture2D:
	for child in card_front_renderer.get_children():
		child.queue_free()
	
	var card_2d = CardScene.instantiate()
	card_front_renderer.add_child(card_2d)
	card_2d.visible = true
	card_2d.update_visibility()
	await get_tree().process_frame
	
	card_2d.display_card_data(data)
	
	await card_2d.fully_drawn
	
	card_front_renderer.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	
	var texture = card_front_renderer.get_texture()
	if texture:
		print("Textura gerada com sucesso. Tamanho: ", texture.get_size())
	else:
		printerr("Falha ao gerar textura da carta! Usando fallback.")
		texture = _create_fallback_texture(data)
		
	return texture

func _create_fallback_texture(data: Dictionary) -> Texture2D:
	var image = Image.create(190, 280, false, Image.FORMAT_RGBA8)
	
	# Preencher com cor baseada no nome
	var hue = hash(data.get("nome_display", "")) % 100 / 100.0
	image.fill(Color.from_hsv(hue, 0.8, 0.9))
	
	# Adicionar texto
	var font = ThemeDB.fallback_font
	var font_size = 20
	var text = data.get("nome_display", "?") + "\n" + data.get("animal_id", "")
	image.draw_string(font, Vector2(10, 140), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Desenhar um X vermelho para indicar erro
	image.draw_line(Vector2(0, 0), Vector2(190, 280), Color.RED, 5)
	image.draw_line(Vector2(190, 0), Vector2(0, 280), Color.RED, 5)
	
	return ImageTexture.create_from_image(image)

func _on_viewer_opened():
	print("Visualizador 3D aberto!")
	# Garantir que está na posição correta
	$TextureRect/BackGroundDim.position = Vector2.ZERO
	# Configurar para capturar eventos
	$TextureRect/BackGroundDim.mouse_filter = Control.MOUSE_FILTER_STOP
	# Ativar o processamento de input
	set_process_input(true)
	# Emitir sinal para notificar a CollectionScene
	# Iniciar a rotação automática
	rotating_automatically = true

func _create_card_mesh_with_correct_aspect_ratio():
	var card_aspect_ratio = 190.0 / 280.0
	var card_height = 1.4
	var card_width = card_height * card_aspect_ratio
	var card_thickness = 0.02
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(card_width, card_height, card_thickness)
	card_mesh.mesh = box_mesh

func _create_card_material(texture: Texture2D) -> StandardMaterial3D:
	var camaterial = StandardMaterial3D.new()
	camaterial.albedo_color = Color.WHITE
	
	if texture:
		print("Criando material com textura: ", texture)
		camaterial.albedo_texture = texture
	else:
		printerr("Textura inválida, usando fallback")
		camaterial.albedo_color = Color.MAGENTA
	
	# Ajustes importantes para evitar aparência metálica:
	camaterial.metallic = 0.0  # Reduzir metálico para 0
	camaterial.roughness = 0.9  # Aumentar roughness
	camaterial.specular = 0.0   # Desativar especular
	camaterial.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	camaterial.cull_mode = StandardMaterial3D.CULL_BACK
	camaterial.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	
	return camaterial

func _configure_lighting():
	# Adicionar luz ambiente
	var ambient_light = WorldEnvironment.new()
	var env = Environment.new()
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 1.5
	ambient_light.environment = env
	sub_viewport.add_child(ambient_light)
	
	# Adicionar luz direcional
	var directional_light = DirectionalLight3D.new()
	directional_light.light_energy = 0.8
	directional_light.rotation_degrees = Vector3(-30, 30, 0)
	sub_viewport.add_child(directional_light)

func _create_edge_material() -> StandardMaterial3D:
	var edge_mat = StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.1, 0.1, 0.1)
	edge_mat.metallic = 0.2
	edge_mat.roughness = 0.7
	return edge_mat

func _load_card_back_texture() -> Texture2D:
	var path = "res://assets/ui/card_back.jpg"
	if ResourceLoader.exists(path):
		return load(path)
	var image = Image.create(190, 280, false, Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	return ImageTexture.create_from_image(image)

func _update_camera_position():
	if is_instance_valid(camera):
		camera.position = initial_camera_position.normalized() * camera_distance

func _handle_card_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		rotating_automatically = false
		user_rotation.x -= event.relative.x * 0.5
		user_rotation.y = clamp(user_rotation.y + event.relative.y * 0.5, -80, 80)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = clamp(camera_distance - ZOOM_SENSITIVITY, MIN_CAMERA_DISTANCE, MAX_CAMERA_DISTANCE)
			_update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = clamp(camera_distance + ZOOM_SENSITIVITY, MIN_CAMERA_DISTANCE, MAX_CAMERA_DISTANCE)
			_update_camera_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		rotating_automatically = true
		user_rotation = Vector2.ZERO
	get_viewport().set_input_as_handled()

func _on_close_pressed():
	# Unfreeze and restore cards
	get_tree().paused = false
	for card in get_tree().get_nodes_in_group("cards"):
		card.visible = true
		card.process_mode = Node.PROCESS_MODE_INHERIT
	
	Global.viewer_opened = false
	queue_free()

func _on_bg_gui_input(event):
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed:
		_on_close_pressed()
	
func _on_viewport_gui_input(event):
	_handle_card_input(event)
