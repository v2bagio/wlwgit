# PackOpening.gd (Adaptado para usar o ArtManager)
extends Control

const CardScene = preload("res://Card.tscn")
const HOLLOW_CHANCE = 0.1 # 10% de chance

@onready var mainmenu = preload("res://Menu.tscn")
@onready var open_common_pack_button = $OpenCommonPackButton
@onready var open_premium_pack_button = $OpenPremiumPackButton
@onready var open_founders_pack_button = $OpenFoundersPackButton
@onready var card_display_area = $CardDisplayArea
@onready var view_collection_button = $ViewCollectionButton
@onready var background = $PanelContainer/Background
@onready var mainmenubutton = $mainmenubutton
@onready var backbackground = $PanelContainer

func _ready():
	Global.hover_habilitado = false
	open_common_pack_button.pressed.connect(func(): _open_pack("common"))
	open_premium_pack_button.pressed.connect(func(): _open_pack("premium"))
	open_founders_pack_button.pressed.connect(func(): _open_pack("founder"))
	view_collection_button.pressed.connect(_on_view_collection_button_pressed)
	mainmenubutton.pressed.connect(_on_mainmenubutton_pressed)
	card_display_area.alignment = HBoxContainer.ALIGNMENT_CENTER
	card_display_area.add_theme_constant_override("separation", 20)

func _open_pack(pack_type: String):
	open_common_pack_button.disabled = true
	open_premium_pack_button.disabled = true
	open_founders_pack_button.disabled = true
	
	var ui_fade_tween = create_tween()
	ui_fade_tween.tween_property(background, "modulate:a", 0.0, 0.5)
	ui_fade_tween.parallel().tween_property(open_common_pack_button, "modulate:a", 0.0, 0.5)
	ui_fade_tween.parallel().tween_property(open_premium_pack_button, "modulate:a", 0.0, 0.5)
	ui_fade_tween.parallel().tween_property(open_founders_pack_button, "modulate:a", 0.0, 0.5)
	ui_fade_tween.parallel().tween_property(view_collection_button, "modulate:a", 0.0, 0.5)
	ui_fade_tween.parallel().tween_property(mainmenubutton, "modulate:a", 0.0, 0.5)
	ui_fade_tween.parallel().tween_property(backbackground, "modulate:a", 0.0, 0.5)
	
	for child in card_display_area.get_children():
		child.queue_free()
	
	var cards_to_generate = []
	match pack_type:
		"common":
			for i in range(5): cards_to_generate.append({"full_art": false, "alt_art": false})
		"premium":
			for i in range(4): cards_to_generate.append({"full_art": false, "alt_art": false})
			cards_to_generate.append({"full_art": false, "alt_art": true})
		"founder":
			for i in range(3): cards_to_generate.append({"full_art": false, "alt_art": false})
			cards_to_generate.append({"full_art": true, "alt_art": false})
			cards_to_generate.append({"full_art": false, "alt_art": true})

	cards_to_generate.shuffle()

	for i in range(cards_to_generate.size()):
		var card_rules = cards_to_generate[i]
		var animal_id = ""
		var use_alt_art = card_rules.alt_art

		if use_alt_art:
			var alt_art_animals = ArtManager.get_all_alt_art_animals()
			if alt_art_animals != null and not alt_art_animals.is_empty():
				animal_id = alt_art_animals.pick_random()
			else:
				# Fallback para arte normal
				use_alt_art = false 
				animal_id = CardPoolManager.get_random_animal_id()
		else:
			animal_id = CardPoolManager.get_random_animal_id()

		# Garantir que temos um ID válido
		if animal_id.is_empty():
			# Fallback para animais disponíveis
			var all_animals = AnimalDatabase.get_animal_list()
			if not all_animals.is_empty():
				animal_id = all_animals.pick_random()
			else:
				# Fallback de emergência
				animal_id = "capivara"

		if animal_id.is_empty(): continue

		var is_hollow = randf() < HOLLOW_CHANCE
		
		var new_card = CardScene.instantiate() as Card
		card_display_area.add_child(new_card)
		new_card.flip_habilitado = true
		
		new_card.setup(animal_id, card_rules.full_art, is_hollow, use_alt_art)
		
		PlayerCollection.add_card(new_card.get_card_data())
		
		var card_tween = create_tween()
		new_card.modulate.a = 0
		new_card.scale = Vector2(0.8, 0.8)
		card_tween.tween_interval(0.05 + (i * 0.4))
		card_tween.tween_property(new_card, "modulate:a", 1.0, 0.3)
		card_tween.parallel().tween_property(new_card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)

	var reactivate_tween = create_tween()
	reactivate_tween.tween_interval(0.5 + (cards_to_generate.size() * 0.35))
	reactivate_tween.tween_callback(func():
		open_common_pack_button.disabled = false
		open_premium_pack_button.disabled = false
		open_founders_pack_button.disabled = false
		open_common_pack_button.modulate.a = 1.0
		open_premium_pack_button.modulate.a = 1.0
		open_founders_pack_button.modulate.a = 1.0
		view_collection_button.modulate.a = 1.0
		mainmenubutton.modulate.a = 1.0
	)
	
	var available_alt_art_animals = ArtManager.get_all_alt_art_animals()
	if available_alt_art_animals.is_empty():
		# Se não há arte alternativa, converter para arte normal
		for card in cards_to_generate:
			if card.alt_art:
				card.alt_art = false
				card.full_art = true  # Compensação
		
func _on_view_collection_button_pressed():
	get_tree().change_scene_to_file("res://CollectionScene.tscn")

func _on_mainmenubutton_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")
