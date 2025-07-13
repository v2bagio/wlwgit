# AnimalDatabase.gd (Com sistema de descrição, artistas e backgrounds)
extends Node

# Cache para backgrounds. O cache de arte não é mais necessário aqui.
var background_cache = {}
# Lista dos biomas válidos para o sistema reconhecer nos nomes dos ficheiros de background
const VALID_BIOMES = ["pampa", "mata_atlantica", "cerrado", "caatinga", "pantanal", "amazonia"]
const BIOME_NORMALIZATION = {
	"pantanal": "Pantanal",
	"amazonia": "Amazônia",
	"mata_atlantica": "Mata Atlântica",
	"pampa": "Pampa",
	"cerrado": "Cerrado",
	"caatinga": "Caatinga"
	}
# --- ESTRUTURA DO BANCO DE DADOS ATUALIZADA ---
# Adicionamos "descricao" e um array "artes" para cada animal.
# "bioma" agora também é um array de strings.
const DB = {
	"capivara": {
		"nome_display": "Capivara", "iucn_status": "LC",
		"bioma": ["Pantanal", "Amazônia"],
		"descricao": "A capivara é o maior roedor do mundo. Sociável e semiaquática, é frequentemente encontrada perto de lagos e rios, vivendo em grandes grupos familiares.",
		"artes": [
			{"path": "res://assets/normal/capivara.jpg", "artist": "Artista A", "is_alt": false},
			{"path": "res://assets/normal/capivara_v2.jpg", "artist": "Artista B", "is_alt": false}
		],
		"population": 50000,
		"altura":      { "min": 0.5, "max": 0.65, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.0, "max": 1.4,  "unidade": "m", "archetype": "HIGH" },
		"velocidade":  { "min": 30.0,"max": 40.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso":        { "min": 75.0,"max": 95.0, "unidade": "kg", "archetype": "HIGH" }
	},
	"onca_pintada": {
		"nome_display": "Onça-Pintada", "iucn_status": "NT",
		"bioma": ["Pantanal", "Cerrado", "Mata Atlântica"],
		"descricao": "O maior felino das Américas, a onça-pintada é um predador de topo com uma mordida poderosa. As suas manchas, chamadas rosetas, são únicas para cada indivíduo.",
		"artes": [
			{"path": "res://assets/normal/onca_pintada.png", "artist": "Artista C", "is_alt": false},
			{"path": "res://assets/alternate/onca_pintada_alt.png", "artist": "Artista D (Arte Alt.)", "is_alt": true}
		],
		"population": 5000,
		"altura":      { "min": 0.8, "max": 0.95, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.5, "max": 1.9, "unidade": "m", "archetype": "HIGH" },
		"velocidade":  { "min": 70.0, "max": 85.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso":        { "min": 90.0, "max": 110.0, "unidade": "kg", "archetype": "HIGH" }
	},
	"mico_leao_dourado": {
		"nome_display": "Mico-Leão-Dourado", "iucn_status": "EN",
		"bioma": ["Mata Atlântica"],
		"descricao": "Endêmico da Mata Atlântica brasileira, este pequeno primata é um símbolo da luta pela conservação de espécies ameaçadas.",
		"artes": [
			{"path": "res://assets/normal/mico_leao_dourado.jpg", "artist": "Artista E", "is_alt": false}
		],
		"population": 1000,
		"altura":      { "min": 0.25,"max": 0.35, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.15,"max": 0.25, "unidade": "m", "archetype": "LOW" },
		"velocidade":  { "min": 35.0,"max": 45.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso":        { "min": 0.4, "max": 0.6,  "unidade": "kg", "archetype": "LOW" }
	},
	"tucano": {
		"nome_display": "Tucano-Toco", "iucn_status": "LC",
		"bioma": ["Pantanal", "Cerrado"],
		"descricao": "Conhecido pelo seu enorme e colorido bico, o tucano-toco utiliza-o para alcançar frutos e regular a temperatura corporal.",
		"artes": [
			{"path": "res://assets/normal/tucano.jpg", "artist": "Artista F", "is_alt": false}
		],
		"population": 50000,
		"altura":      { "min": 0.45, "max": 0.55, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 0.5, "max": 0.65, "unidade": "m", "archetype": "HIGH" },
		"velocidade":  { "min": 45.0, "max": 55.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso":        { "min": 0.5, "max": 0.8, "unidade": "kg", "archetype": "LOW" }
	}
}

func _ready():
	print("--- A verificar a biblioteca de backgrounds ---")
	_scan_background_folder("res://assets/backgrounds")
	print("Verificação de backgrounds concluída.")
	print("DIAGNÓSTICO: Backgrounds Encontrados: ", background_cache)


func _scan_background_folder(folder_path: String):
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".jpg") or file_name.ends_with(".png")):
				var file_base_name = file_name.get_basename().to_lower()
				for biome in VALID_BIOMES:
					if file_base_name.begins_with(biome):
						if not background_cache.has(biome):
							background_cache[biome] = []
						var full_path = "%s/%s" % [folder_path, file_name]
						background_cache[biome].append(full_path)
						break
			file_name = dir.get_next()
	else:
		print("AVISO: Não foi possível abrir a pasta de backgrounds '%s'." % folder_path)

# --- FUNÇÕES PÚBLICAS ---

# Pega todos os dados de um animal específico
func get_animal_data(id: String): 
	return DB.get(id, {})

# Retorna a lista de todos os IDs de animais no banco de dados
func get_animal_list(): 
	return DB.keys()

# Retorna um dicionário de arte aleatório { "path": "...", "artist": "..." } para um animal
func get_random_art(animal_id: String, is_alt: bool) -> Dictionary:
	var animal_data = get_animal_data(animal_id)
	if animal_data.is_empty():
		return {"path": "", "artist": "Desconhecido"}
	
	# Filtra a lista de artes para encontrar apenas as do tipo correto (alt ou normal)
	var possible_arts = animal_data.artes.filter(func(art): return art.is_alt == is_alt)
	
	if not possible_arts.is_empty():
		return possible_arts.pick_random()
	
	# Fallback: se não encontrar arte do tipo pedido (ex: alt art não existe),
	# tenta encontrar uma arte normal para não deixar a carta sem imagem.
	var normal_arts = animal_data.artes.filter(func(art): return not art.is_alt)
	if not normal_arts.is_empty():
		return normal_arts.pick_random()
		
	return {"path": "", "artist": "Desconhecido"}

# Retorna uma lista de animais que possuem pelo menos uma arte alternativa
func get_all_alt_art_animals() -> Array:
	var alt_art_animals = []
	for animal_id in DB.keys():
		var animal_data = DB[animal_id]
		if animal_data.has("artes"):
			for art in animal_data.artes:
				if art.is_alt:
					alt_art_animals.append(animal_id)
					break # Já encontrámos uma, podemos passar para o próximo animal
	return alt_art_animals

# Retorna o caminho para uma imagem de background aleatória de um bioma
func get_random_background(biome_name: String) -> String:
	var normalized_key = biome_name.to_lower().replace(" ", "_")
	normalized_key = BIOME_NORMALIZATION.get(normalized_key, normalized_key)
	var biome_key = biome_name.to_lower().replace(" ", "_").replace("â", "a").replace("ô", "o").replace("ã", "a")
	
	if background_cache.has(biome_key) and not background_cache[biome_key].is_empty():
		return background_cache[biome_key].pick_random()
	
	# Adicionado um print para ajudar a identificar falhas futuras
	print("AVISO: Nenhum background encontrado para o bioma '%s' (chave de busca: '%s')" % [biome_name, biome_key])
	return "" # Retorna vazio se não encontrar nenhum background para o bioma
