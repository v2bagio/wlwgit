# CardPoolManager.gd
extends Node

const TOTAL_CARD_POOL_SIZE = 100000

var total_population_weight = 0
var weighted_pool = []

func _ready():
	print("--- A calcular o pool de cartas do lançamento ---")
	# Espera o ArtManager terminar sua varredura de artes
	await ArtManager.scan_completed 
	_calculate_card_pool()
	print("Cálculo do pool concluído.")

func _calculate_card_pool():
	var all_animal_ids = AnimalDatabase.get_animal_list()
	var valid_animal_ids = []
	
	# Filtra a lista para incluir apenas animais que o ArtManager tem arte.
	for animal_id in all_animal_ids:
		# Usamos a própria função do ArtManager para verificar. 
		# Ela já tem a lógica de fallback, então se retornar um caminho, o animal é válido.
		var art_data = ArtManager.get_random_art(animal_id, false)
		if art_data and not art_data.get("path", "").is_empty():
			valid_animal_ids.append(animal_id)
		else:
			print("CardPoolManager: Excluindo '%s' do pool por falta de arte." % animal_id)

	# A partir daqui, a função usa a lista 'valid_animal_ids'
	
	for animal_id in valid_animal_ids:
		var animal_data = AnimalDatabase.get_animal_data(animal_id)
		if animal_data:
			total_population_weight += animal_data.get("population", 0)
	print("Animais com arte reconhecida:")
	for a in valid_animal_ids:
		print("- ", a)
	if total_population_weight == 0:
		print("ERRO: População total dos animais válidos é zero. Nenhuma carta será gerada.")
		return
		
	print("Peso total da população (apenas animais com arte): ", total_population_weight)
	
	var cumulative_weight = 0.0
	for animal_id in valid_animal_ids:
		var animal_data = AnimalDatabase.get_animal_data(animal_id)
		var population = animal_data.get("population", 0)
		var probability = float(population) / total_population_weight
		
		cumulative_weight += probability
		weighted_pool.append({"id": animal_id, "weight": cumulative_weight})
		
		var card_count = round(probability * TOTAL_CARD_POOL_SIZE)
		print(" - %s: %d cartas (%.2f%%), Peso Cumulativo: %.4f" % [animal_id, card_count, probability * 100, cumulative_weight])

	Engine.set_meta("card_pool_weights", weighted_pool)
	Engine.set_meta("card_pool_total_weight", total_population_weight)

func get_random_animal_id() -> String:
	var random_roll = randf()
	#Ajuste do cálculo da Pool
	#Lianna Aragoni
	#16 de julho
	for pool_entry in weighted_pool:
		if random_roll <= pool_entry.weight:
			return pool_entry.id

	return weighted_pool.back().id
	var _pool = Engine.get_meta("card_pool_weights", [])
	if weighted_pool.is_empty(): return ""
		# Fallback se o pool estiver vazio
	var all_animals = AnimalDatabase.get_animal_list()
	if not all_animals.is_empty():
		return all_animals.pick_random()
	return "capivara"  # Fallback final
	
func get_boosted_animal_id(preferred_biome: String) -> String:
	var candidates = []
	for entry in weighted_pool:
		var data = AnimalDatabase.get_animal_data(entry.id)
		# Adicione verificação de segurança
		if data and preferred_biome in data.get("bioma", []):
			candidates.append(entry)
	
	if candidates.is_empty():
		return get_random_animal_id()
	
	# Lógica de seleção ponderada
	var total_weight = 0.0
	for candidate in candidates:
		var animal_data = AnimalDatabase.get_animal_data(candidate.id)
		total_weight += animal_data.get("population", 0)
	
	var random_roll = randf() * total_weight
	var cumulative = 0.0
	
	for candidate in candidates:
		var animal_data = AnimalDatabase.get_animal_data(candidate.id)
		cumulative += animal_data.get("population", 0)
		if random_roll <= cumulative:
			return candidate.id

	return candidates.back().id  # Fallback seguro
