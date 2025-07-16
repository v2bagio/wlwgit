# ArtManager.gd (Com sistema de descoberta automática de arte melhorado)
extends Node

var art_library = {}
signal scan_completed

# Extensões de imagem suportadas
const SUPPORTED_EXTENSIONS = [".png", ".jpg", ".jpeg"]

func _ready():
	load_all_art()
	scan_completed.emit()
	
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

# --- FUNÇÃO DE DESCOBERTA MELHORADA PARA MÚLTIPLOS TIPOS E SUFIXOS ---
func _scan_art_folder(folder_path: String, artist_name: String, is_alt: bool):
	var dir = DirAccess.open(folder_path)
	if not dir: 
		print("ArtManager: Pasta não encontrada: %s" % folder_path)
		return

	var animal_ids = AnimalDatabase.get_animal_list()
	
	# Ordena os IDs por comprimento, do mais longo para o mais curto
	# Isto garante que "onca_pintada" seja verificado antes de "onca"
	animal_ids.sort_custom(func(a, b): return a.length() > b.length())

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var matched_animal = _match_file_to_animal(file_name, animal_ids)
			if not matched_animal.is_empty():
				if not art_library.has(matched_animal):
					art_library[matched_animal] = []
				
				art_library[matched_animal].append({
					"path": folder_path + file_name,
					"artist": artist_name,
					"is_alt": is_alt
				})
				print("ArtManager: Arte encontrada - %s -> %s (%s)" % [file_name, matched_animal, artist_name])
		file_name = dir.get_next()

func _match_file_to_animal(file_name: String, animal_ids: Array) -> String:
	"""
	Verifica se um arquivo corresponde a um animal, considerando:
	- Múltiplas extensões (.png, .jpg, .jpeg)
	- Sufixos numéricos (ex: lobo_guara1.png, lobo_guara2.jpg)
	- Sufixos de versão (ex: lobo_guara_v2.png)
	"""
	
	# Verificar se o arquivo tem uma extensão suportada
	var has_supported_extension = false
	for ext in SUPPORTED_EXTENSIONS:
		if file_name.to_lower().ends_with(ext):
			has_supported_extension = true
			break
	
	if not has_supported_extension:
		return ""
	
	# Remover a extensão para análise
	var file_base = file_name.get_basename().to_lower()
	
	# Tentar fazer match com cada animal_id
	for animal_id in animal_ids:
		if _is_file_match_for_animal(file_base, animal_id):
			return animal_id
	
	return ""

func _is_file_match_for_animal(file_base: String, animal_id: String) -> bool:
	"""
	Verifica se um nome de arquivo (sem extensão) corresponde a um animal específico.
	Considera padrões como:
	- lobo_guara.png
	- lobo_guara1.jpg
	- lobo_guara2.jpeg
	- lobo_guara_v2.png
	- lobo_guara_alt.png
	"""
	
	var animal_id_lower = animal_id.to_lower()
	
	# Caso 1: Match exato
	if file_base == animal_id_lower:
		return true
	
	# Caso 2: Arquivo começa com o animal_id
	if file_base.begins_with(animal_id_lower):
		# Obter o sufixo após o nome do animal
		var suffix = file_base.substr(animal_id_lower.length())
		
		# Verificar se o sufixo é válido
		return _is_valid_suffix(suffix)
	
	return false

func _is_valid_suffix(suffix: String) -> bool:
	"
	Verifica se um sufixo é válido para variações de arte.
	Sufixos válidos incluem:
	- Números: 1, 2, 3, etc.
	- Versões: _v1, _v2, _version2, etc.
	- Alternativas: _alt, _alternate, _alternative
	- Variações: _var, _variation
	- Vazio (arquivo base)
	"
	
	# Sufixo vazio é válido (arquivo base)
	if suffix.is_empty():
		return true
	
	# Remover underscores iniciais
	suffix = suffix.lstrip("_")
	
	# Verificar se é apenas um número
	if suffix.is_valid_int():
		return true
	
	# Verificar padrões de versão
	var version_patterns = [
		"v", "version", "ver",
		"alt", "alternate", "alternative",
		"var", "variation", "variant"
	]
	
	for pattern in version_patterns:
		if suffix.begins_with(pattern):
			var remaining = suffix.substr(pattern.length())
			# Se não há nada após o padrão, é válido
			if remaining.is_empty():
				return true
			# Se há um número após o padrão, é válido
			if remaining.is_valid_int():
				return true
	
	return false

func _get_player_artist_name(player_id: String) -> String:
	var info_path = "user://player_data/%s/artist_info.json" % player_id
	if not FileAccess.file_exists(info_path):
		return "Artista Desconhecido (%s)" % player_id

	var file = FileAccess.open(info_path, FileAccess.READ)
	var parse_result = JSON.parse_string(file.get_as_text())
	
	if parse_result and parse_result.has("artist_name"):
		return parse_result.artist_name
	
	return "Artista da Comunidade"

# --- FUNÇÕES PÚBLICAS ---
func get_random_art(animal_id: String, is_alt: bool) -> Dictionary:
	if not art_library.has(animal_id):
		printerr("ArtManager: Nenhuma arte encontrada para o animal '%s'." % animal_id)
		return {"path": "", "artist": "Desconhecido"}

	var possible_arts = art_library[animal_id].filter(func(art): return art.is_alt == is_alt)
	
	if not possible_arts.is_empty():
		var selected_art = possible_arts.pick_random()
		print("ArtManager: Arte selecionada para %s (alt=%s): %s" % [animal_id, is_alt, selected_art.path])
		return selected_art

	var fallback_arts = art_library[animal_id].filter(func(art): return art.is_alt != is_alt)
	if not fallback_arts.is_empty():
		print("ArtManager: Arte do tipo %s não encontrada para '%s'. Usando fallback." % [is_alt, animal_id])
		return fallback_arts.pick_random()
		
	printerr("ArtManager: Nenhuma arte de nenhum tipo encontrada para '%s'." % animal_id)
	return {"path": "", "artist": "Desconhecido"}

func get_all_available_arts(animal_id: String) -> Array:
	"""Retorna todas as artes disponíveis para um animal específico"""
	if not art_library.has(animal_id):
		return []
	return art_library[animal_id]

func get_art_count(animal_id: String, is_alt: bool = false) -> int:
	"""Retorna o número de artes disponíveis para um animal"""
	if not art_library.has(animal_id):
		return 0
	
	var filtered_arts = art_library[animal_id].filter(func(art): return art.is_alt == is_alt)
	return filtered_arts.size()

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

# --- FUNÇÕES DE DIAGNÓSTICO ---
func print_art_library():
	"""Função de debug para imprimir toda a biblioteca de arte"""
	print("=== BIBLIOTECA DE ARTE ===")
	for animal_id in art_library.keys():
		print("Animal: %s" % animal_id)
		for art in art_library[animal_id]:
			print("  - %s (Alt: %s) por %s" % [art.path, art.is_alt, art.artist])
	print("=== FIM DA BIBLIOTECA ===")

func get_library_stats() -> Dictionary:
	"""Retorna estatísticas da biblioteca de arte"""
	var stats = {
		"total_animals": art_library.size(),
		"total_arts": 0,
		"normal_arts": 0,
		"alt_arts": 0,
		"animals_with_multiple_arts": 0
	}
	
	for animal_id in art_library.keys():
		var arts = art_library[animal_id]
		stats.total_arts += arts.size()
		
		if arts.size() > 1:
			stats.animals_with_multiple_arts += 1
		
		for art in arts:
			if art.is_alt:
				stats.alt_arts += 1
			else:
				stats.normal_arts += 1
	
	return stats
