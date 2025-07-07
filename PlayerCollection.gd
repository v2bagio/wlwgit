# PlayerCollection.gd
extends Node

const SAVE_PATH = "user://collection.json"
const SAVE_VERSION = 1

var owned_cards = []

func _ready():
	load_collection()

func add_card(card_data: Dictionary):
	owned_cards.append(card_data.duplicate(true))
	save_collection()

func get_collection():
	return owned_cards

func save_collection():
	var _data = {
	"version": SAVE_VERSION,
	"cards": owned_cards
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(owned_cards, "\t")
		file.store_string(json_string)
		print("Coleção guardada com sucesso.")

func load_collection():
	if not FileAccess.file_exists(SAVE_PATH):
		owned_cards = []
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parse_result = JSON.parse_string(json_string)
		if parse_result != null:
			owned_cards = parse_result
		else:
			owned_cards = []

func clear_collection():
	owned_cards.clear()
	if FileAccess.file_exists(SAVE_PATH):
		# Usar DirAccess para remoção segura
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("collection.json")
	print("Coleção limpa com sucesso!")
