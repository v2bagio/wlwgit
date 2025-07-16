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
		"nome_display": "Onça-pintada", "iucn_status": "NT",
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
		"nome_display": "Tucano-toco", "iucn_status": "LC",
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
	},
	"lobo_guara": {
		"nome_display": "Lobo-guará",
		"iucn_status": "NT",
		"bioma": ["Cerrado", "Pantanal", "Pampa"],
		"descricao": "O maior canídeo da América do Sul, conhecido por suas pernas longas e finas e uma dieta onívora, com destaque para o 'fruto-do-lobo'.",
		"artes": [
			{"path": "res://assets/normal/lobo_guara.jpeg", "artist": "Artista A", "is_alt": false}
		],
		"population": 17000,
		"altura": { "min": 0.9, "max": 1.0, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.2, "max": 1.5, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 60.0, "max": 75.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 20.0, "max": 30.0, "unidade": "kg", "archetype": "MEDIUM" }
	},
	"ariranha": {
		"nome_display": "Ariranha",
		"iucn_status": "EN",
		"bioma": ["Amazônia", "Pantanal"],
		"descricao": "Uma lontra gigante e social que vive em grupos familiares. É um predador de topo de rios e lagos, alimentando-se principalmente de peixes.",
		"artes": [
			{"path": "res://assets/normal/ariranha.jpg", "artist": "Artista B", "is_alt": false}
		],
		"population": 5000,
		"altura": { "min": 0.3, "max": 0.4, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 1.5, "max": 1.8, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 10.0, "max": 15.0, "unidade": "km/h", "archetype": "LOW" },
		"peso": { "min": 22.0, "max": 32.0, "unidade": "kg", "archetype": "MEDIUM" }
	},
	"boa_constrictor": {
		"nome_display": "Boa constrictor",
		"iucn_status": "LC",
		"bioma": ["Amazônia", "Cerrado", "Mata Atlântica", "Caatinga"],
		"descricao": "Serpente não peçonhenta que mata suas presas por constrição. Possui padrões de cores que a ajudam na camuflagem.",
		"artes": [
			{"path": "res://assets/normal/jiboia.jpg", "artist": "Artista C", "is_alt": false}
		],
		"population": 100000,
		"altura": { "min": 0.1, "max": 0.15, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 2.0, "max": 4.0, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 1.5, "max": 2.0, "unidade": "km/h", "archetype": "LOW" },
		"peso": { "min": 15.0, "max": 30.0, "unidade": "kg", "archetype": "MEDIUM" }
	},
	"carcara": {
		"nome_display": "Carcará",
		"iucn_status": "LC",
		"bioma": ["Cerrado", "Caatinga", "Pampa", "Pantanal"],
		"descricao": "Ave de rapina oportunista, conhecida por sua inteligência e por se alimentar de uma grande variedade de presas, incluindo carniça.",
		"artes": [
			{"path": "res://assets/normal/carcara.jpg", "artist": "Artista D", "is_alt": false}
		],
		"population": 500000,
		"altura": { "min": 0.5, "max": 0.6, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 0.5, "max": 0.6, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 80.0, "max": 100.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 0.8, "max": 1.4, "unidade": "kg", "archetype": "LOW" }
	},
	"cchinga": {
		"nome_display": "Conepatus chinga",
		"iucn_status": "LC",
		"bioma": ["Pampa", "Cerrado"],
		"descricao": "Um tipo de gambá conhecido por sua capacidade de ejetar um líquido de odor forte e desagradável como mecanismo de defesa.",
		"artes": [
			{"path": "res://assets/normal/cchinga.jpg", "artist": "Artista E", "is_alt": false}
		],
		"population": 100000,
		"altura": { "min": 0.2, "max": 0.25, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.4, "max": 0.5, "unidade": "m", "archetype": "LOW" },
		"velocidade": { "min": 10.0, "max": 15.0, "unidade": "km/h", "archetype": "LOW" },
		"peso": { "min": 2.0, "max": 4.5, "unidade": "kg", "archetype": "LOW" }
	},
	"cervo_do_pantanal": {
		"nome_display": "Cervo-do-Pantanal",
		"iucn_status": "VU",
		"bioma": ["Pantanal", "Cerrado"],
		"descricao": "O maior cervídeo da América do Sul, adaptado a ambientes alagados, com cascos especiais que o ajudam a não afundar na lama.",
		"artes": [
			{"path": "res://assets/normal/cervo_pantanal.jpg", "artist": "Artista G", "is_alt": false}
		],
		"population": 40000,
		"altura": { "min": 1.1, "max": 1.2, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.8, "max": 2.0, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 50.0, "max": 60.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 100.0, "max": 150.0, "unidade": "kg", "archetype": "HIGH" }
	},
	"cyacare": {
		"nome_display": "Cayman yacare",
		"iucn_status": "LC",
		"bioma": ["Pantanal", "Amazônia"],
		"descricao": "Um jacaré de porte médio, abundante no Pantanal. Desempenha um papel crucial no ecossistema como predador e na ciclagem de nutrientes.",
		"artes": [
			{"path": "res://assets/normal/cyacare.jpg", "artist": "Artista H", "is_alt": false}
		],
		"population": 100000,
		"altura": { "min": 0.3, "max": 0.4, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 2.0, "max": 2.5, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 40.0, "max": 50.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 50.0, "max": 60.0, "unidade": "kg", "archetype": "MEDIUM" }
	},
	"gaviao_caboclo": {
		"nome_display": "Gavião-Caboclo",
		"iucn_status": "LC",
		"bioma": ["Cerrado", "Mata Atlântica", "Pampa"],
		"descricao": "Gavião de porte médio com cauda branca distintiva. É frequentemente visto em áreas abertas e campos, caçando pequenos animais.",
		"artes": [
			{"path": "res://assets/normal/gaviao_caboclo.jpg", "artist": "Artista I", "is_alt": false}
		],
		"population": 2000000,
		"altura": { "min": 0.45, "max": 0.58, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 0.45, "max": 0.58, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 70.0, "max": 90.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 0.7, "max": 1.2, "unidade": "kg", "archetype": "LOW" }
	},
	"gaivota_ocidental": {
		"nome_display": "Gaivota-Ocidental",
		"iucn_status": "LC",
		"bioma": ["Mata Atlântica"],
		"descricao": "Uma grande gaivota encontrada na costa oeste da América do Norte. Não é nativa do Brasil, mas pode ser avistada ocasionalmente.",
		"artes": [
			{"path": "res://assets/normal/gaivota_ocidental.jpg", "artist": "Artista J", "is_alt": false}
		],
		"population": 90000,
		"altura": { "min": 0.53, "max": 0.65, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 0.53, "max": 0.65, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 50.0, "max": 65.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 0.8, "max": 1.4, "unidade": "kg", "archetype": "LOW" }
	},
	"gralha_do_campo": {
		"nome_display": "Gralha-do-Campo",
		"iucn_status": "LC",
		"bioma": ["Cerrado", "Pampa"],
		"descricao": "Ave barulhenta e social que vive em bandos. Possui uma crista distinta e plumagem predominantemente branca e preta.",
		"artes": [
			{"path": "res://assets/normal/gralha_campo.jpg", "artist": "Artista K", "is_alt": false}
		],
		"population": 100000,
		"altura": { "min": 0.35, "max": 0.38, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.35, "max": 0.38, "unidade": "m", "archetype": "LOW" },
		"velocidade": { "min": 40.0, "max": 50.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 0.15, "max": 0.17, "unidade": "kg", "archetype": "LOW" }
	},
	"epicrates_crassus": {
		"nome_display": "Epicrates crassus",
		"iucn_status": "LC",
		"bioma": ["Cerrado", "Caatinga", "Mata Atlântica"],
		"descricao": "Conhecida como jiboia-arco-íris, esta serpente exibe um brilho iridescente em suas escamas sob a luz. É de hábito noturno e terrestre.",
		"artes": [
			{"path": "res://assets/normal/salamanta.jpg", "artist": "Artista L", "is_alt": false}
		],
		"population": 80000,
		"altura": { "min": 0.05, "max": 0.1, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 1.5, "max": 2.0, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 1.0, "max": 1.5, "unidade": "km/h", "archetype": "LOW" },
		"peso": { "min": 2.0, "max": 4.0, "unidade": "kg", "archetype": "LOW" }
	},
	"sagui_de_tufo_preto": {
		"nome_display": "Sagui-de-tufo-preto",
		"iucn_status": "LC",
		"bioma": ["Cerrado", "Mata Atlântica"],
		"descricao": "Pequeno primata com tufos de pelos pretos característicos nas orelhas. Vive em grupos familiares e se alimenta de insetos, frutos e seiva.",
		"artes": [
			{"path": "res://assets/normal/sagui_tufo_preto.jpg", "artist": "Artista M", "is_alt": false}
		],
		"population": 200000,
		"altura": { "min": 0.19, "max": 0.22, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.28, "max": 0.33, "unidade": "m", "archetype": "LOW" },
		"velocidade": { "min": 30.0, "max": 40.0, "unidade": "km/h", "archetype": "MEDIUM" },
		"peso": { "min": 0.35, "max": 0.45, "unidade": "kg", "archetype": "LOW" }
	},
	"puma": {
		"nome_display": "Puma concolor",
		"iucn_status": "LC",
		"bioma": ["Amazônia", "Cerrado", "Mata Atlântica", "Pantanal", "Pampa", "Caatinga"],
		"descricao": "Também conhecida como onça-parda, é o segundo maior felino das Américas. É um predador versátil e solitário, com grande capacidade de adaptação.",
		"artes": [
			{"path": "res://assets/normal/puma.jpg", "artist": "Artista N", "is_alt": false}
		],
		"population": 40000,
		"altura": { "min": 0.6, "max": 0.9, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.5, "max": 2.75, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 65.0, "max": 80.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 53.0, "max": 100.0, "unidade": "kg", "archetype": "HIGH" }
	},
	"tuiuiu": {
		"nome_display": "Tuiuiú",
		"iucn_status": "LC",
		"bioma": ["Pantanal"],
		"descricao": "Considerada a ave-símbolo do Pantanal, é a maior cegonha do continente. Constrói ninhos enormes no topo das árvores.",
		"artes": [
		],
		"population": 25000,
		"altura": { "min": 1.4, "max": 1.6, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.4, "max": 1.6, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 40.0, "max": 50.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 5.0, "max": 8.0, "unidade": "kg", "archetype": "LOW" }
	},
	"lycalopex_gymnocercus": {
		"nome_display": "Graxaim-do-Campo",
		"iucn_status": "LC",
		"bioma": ["Pampa", "Cerrado"],
		"descricao": "Uma raposa sul-americana de hábitos noturnos e onívoros. É adaptável e pode ser encontrada em campos, matas e áreas rurais.",
		"artes": [
		],
		"population": 100000,
		"altura": { "min": 0.4, "max": 0.45, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.5, "max": 0.8, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 40.0, "max": 50.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 4.0, "max": 6.5, "unidade": "kg", "archetype": "LOW" }
	},
	"jararaca_pintada": {
		"nome_display": "Jararaca-Pintada",
		"iucn_status": "LC",
		"bioma": ["Cerrado", "Mata Atlântica", "Pampa"],
		"descricao": "Serpente peçonhenta da família Viperidae, encontrada em diversas regiões da América do Sul. Possui um padrão de manchas que a camufla no ambiente.",
		"artes": [
		],
		"population": 100000,
		"altura": { "min": 0.05, "max": 0.08, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.7, "max": 1.2, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 1.0, "max": 1.5, "unidade": "km/h", "archetype": "LOW" },
		"peso": { "min": 0.2, "max": 0.5, "unidade": "kg", "archetype": "LOW" }
	},
	"aranha_armadeira": {
		"nome_display": "Aranha-Armadeira",
		"iucn_status": "NE",
		"bioma": ["Mata Atlântica", "Amazônia"],
		"descricao": "Gênero de aranhas peçonhentas e agressivas, conhecidas pela postura de defesa com as pernas dianteiras erguidas. Sua picada pode ser perigosa.",
		"artes": [
		],
		"population": 500000,
		"altura": { "min": 0.03, "max": 0.05, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.1, "max": 0.17, "unidade": "m", "archetype": "LOW" },
		"velocidade": { "min": 3.0, "max": 4.0, "unidade": "km/h", "archetype": "LOW" },
		"peso": { "min": 0.005, "max": 0.015, "unidade": "kg", "archetype": "LOW" }
	},
	"ema": {
		"nome_display": "Ema",
		"iucn_status": "NT",
		"bioma": ["Cerrado", "Pampa", "Caatinga"],
		"descricao": "A maior ave brasileira, incapaz de voar, mas uma excelente corredora. O macho é responsável por chocar os ovos e cuidar dos filhotes.",
		"artes": [
		],
		"population": 70000,
		"altura": { "min": 1.5, "max": 1.7, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 1.5, "max": 1.7, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 50.0, "max": 60.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 20.0, "max": 34.0, "unidade": "kg", "archetype": "MEDIUM" }
	},
	"joao_pobre": {
		"nome_display": "João-Pobre",
		"iucn_status": "LC",
		"bioma": ["Mata Atlântica", "Pampa", "Cerrado"],
		"descricao": "Pequeno pássaro insetívoro que habita margens de rios e lagos. É conhecido por seu canto simples e por balançar a cauda constantemente.",
		"artes": [
		],
		"population": 100000,
		"altura": { "min": 0.1, "max": 0.12, "unidade": "m", "archetype": "LOW" },
		"comprimento": { "min": 0.1, "max": 0.12, "unidade": "m", "archetype": "LOW" },
		"velocidade": { "min": 20.0, "max": 30.0, "unidade": "km/h", "archetype": "MEDIUM" },
		"peso": { "min": 0.008, "max": 0.01, "unidade": "kg", "archetype": "LOW" }
	},
	"maguari": {
		"nome_display": "Maguari",
		"iucn_status": "LC",
		"bioma": ["Pantanal", "Pampa"],
		"descricao": "Uma grande cegonha branca com cauda preta e uma área vermelha ao redor dos olhos. Alimenta-se em áreas alagadas, caçando peixes e anfíbios.",
		"artes": [
			{"path": "res://assets/normal/maguari.jpg", "artist": "Artista U", "is_alt": false}
		],
		"population": 1,
		"altura": { "min": 0.9, "max": 1.1, "unidade": "m", "archetype": "HIGH" },
		"comprimento": { "min": 0.9, "max": 1.1, "unidade": "m", "archetype": "HIGH" },
		"velocidade": { "min": 40.0, "max": 50.0, "unidade": "km/h", "archetype": "HIGH" },
		"peso": { "min": 3.5, "max": 4.5, "unidade": "kg", "archetype": "LOW" }
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
