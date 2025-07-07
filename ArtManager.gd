# ArtManager.gd (Com sistema de descoberta automática de arte)
extends Node

var art_library = {}
signal scan_completed # Adicione esta linha no topo do script

func _ready():
	load_all_art()

	scan_completed.emit() # Adicione esta linha no final da função
	
func load_all_art():
	print("--- ArtManager: A iniciar descoberta automática de artes ---")
	art_library.clear()
	
	_discover_base_art()
	_discover_player_art()
	
	print("--- Descoberta de artes concluída. Biblioteca final: ---")
	print(art_library)

func _discover_base_art():
	print("-> A procurar por artes base em res://assets...")
	_scan_art_folder("res://assets/normal/", "Artista Base", false)
	_scan_art_folder("res://assets/alternate/", "Artista Base", true)

func _discover_player_art():
	print("-> A procurar por artes da comunidade em user://player_data...")
	var player_data_dir = "user://player_data/"
	var dir = DirAccess.open(player_data_dir)
	
	if not dir:
		DirAccess.make_dir_absolute(player_data_dir)
		return

	dir.list_dir_begin()
	var player_id = dir.get_next()
	while player_id != "":
		if dir.current_is_dir() and player_id != "." and player_id != "..":
			var artist_name = _get_player_artist_name(player_id)
			_scan_art_folder("%s%s/arts/normal/" % [player_data_dir, player_id], artist_name, false)
			_scan_art_folder("%s%s/arts/alternate/" % [player_data_dir, player_id], artist_name, true)
		player_id = dir.get_next()

# --- FUNÇÃO DE DESCOBERTA CORRIGIDA E ROBUSTA ---
func _scan_art_folder(folder_path: String, artist_name: String, is_alt: bool):
	var dir = DirAccess.open(folder_path)
	if not dir: return

	var animal_ids = AnimalDatabase.get_animal_list()
	
	# CORREÇÃO: Ordena os IDs por comprimento, do mais longo para o mais curto.
	# Isto garante que "onca_pintada" seja verificado antes de "onca".
	animal_ids.sort_custom(func(a, b): return a.length() > b.length())

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".jpg") or file_name.ends_with(".png")):
			for animal_id in animal_ids:
				if file_name.begins_with(animal_id):
					if not art_library.has(animal_id):
						art_library[animal_id] = []
					
					art_library[animal_id].append({
						"path": folder_path + file_name,
						"artist": artist_name,
						"is_alt": is_alt
					})
					# Encontrámos o "match" mais específico, podemos parar.
					break
		file_name = dir.get_next()

func _get_player_artist_name(player_id: String) -> String:
	var info_path = "user://player_data/%s/artist_info.json" % player_id
	if not FileAccess.file_exists(info_path):
		return "Artista Desconhecido (%s)" % player_id

	var file = FileAccess.open(info_path, FileAccess.READ)
	var parse_result = JSON.parse_string(file.get_as_text())
	
	if parse_result and parse_result.has("artist_name"):
		return parse_result.artist_name
	
	return "Artista da Comunidade"

# --- FUNÇÕES PÚBLICAS (não mudam) ---
func get_random_art(animal_id: String, is_alt: bool) -> Dictionary:
	if not art_library.has(animal_id):
		printerr("ArtManager: Nenhuma arte encontrada para o animal '%s'." % animal_id)
		return {"path": "", "artist": "Desconhecido"}

	var possible_arts = art_library[animal_id].filter(func(art): return art.is_alt == is_alt)
	
	if not possible_arts.is_empty():
		return possible_arts.pick_random()

	var fallback_arts = art_library[animal_id].filter(func(art): return art.is_alt != is_alt)
	if not fallback_arts.is_empty():
		print("ArtManager: Arte do tipo %s não encontrada para '%s'. Usando fallback." % [is_alt, animal_id])
		return fallback_arts.pick_random()
		
	printerr("ArtManager: Nenhuma arte de nenhum tipo encontrada para '%s'." % animal_id)
	return {"path": "", "artist": "Desconhecido"}

func get_all_alt_art_animals() -> Array:
	var alt_art_animals = []
	for animal_id in art_library:
		for art in art_library[animal_id]:
			if art.is_alt:
				if not animal_id in alt_art_animals:
					alt_art_animals.append(animal_id)
				break
	return alt_art_animals

func save_player_art(player_id: String, image_data: PackedByteArray, is_alt: bool = false):
	# Criar diretório se não existir
	var dir_path = "user://player_data/%s/arts/%s/" % [player_id, "alternate" if is_alt else "normal"]
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	# Gerar nome de arquivo único
	var file_name = "art_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	var full_path = dir_path + file_name
	
	# Salvar imagem
	var image = Image.new()
	var error = image.load_png_from_buffer(image_data)
	if error == OK:
		image.save_png(full_path)
		# Atualizar biblioteca
		_register_player_art(player_id, full_path, is_alt)
		return full_path
	else:
		printerr("Erro ao salvar arte do jogador: ", error)
		return ""

func _register_player_art(player_id: String, path: String, is_alt: bool):
	var animal_id = _extract_animal_id_from_path(path)
	if animal_id.is_empty():
		printerr("Não foi possível identificar animal ID no caminho: ", path)
		return
	
	if not art_library.has(animal_id):
		art_library[animal_id] = []
	
	art_library[animal_id].append({
		"path": path,
		"artist": "Jogador: %s" % player_id,
		"is_alt": is_alt
	})
	print("Arte registrada para ", animal_id, " por ", player_id)

func _extract_animal_id_from_path(path: String) -> String:
	var file_name = path.get_file().get_basename()
	var animal_ids = AnimalDatabase.get_animal_list()
	
	# Ordenar do mais longo para o mais curto para melhor matching
	animal_ids.sort_custom(func(a, b): return a.length() > b.length())
	
	for id in animal_ids:
		if file_name.find(id) != -1:
			return id
	
	return ""
