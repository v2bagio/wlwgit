extends Node

var card_data: Dictionary = {}

func set_card_data(data: Dictionary):
	card_data = data.duplicate(true)

func get_card_data() -> Dictionary:
	return card_data.duplicate(true)

func clear_data():
	card_data = {}
