extends Node2D


@onready var playercollection = $MenuBar/PlayerCollection
@onready var play = $MenuBar/Play
@onready var marketplace = $MenuBar/Marketplace
@onready var configmenu = $MenuBar/ConfigMenu
@onready var news = $MenuBar/Novidades
@onready var allcollections = $MenuBar/AllCollections
@onready var buypacks = $MenuBar/PackStore
@onready var battle_classic = $MenuBar/BattleClassic
@onready var battle_blitz = $MenuBar/BattleBlitz
@onready var battle_survival = $MenuBar/BattleSurvival
@onready var battle_draft = $MenuBar/BattleDraft
@onready var battle_custom = $MenuBar/BattleCustom

var CardScene = preload("res://Card.tscn")
var PackOpening = preload("res://PackOpening.tscn")

func _ready():
	playercollection.pressed.connect(_on_playercollection_pressed)
	buypacks.pressed.connect(_on_buypacks_pressed)
	battle_classic.pressed.connect(_on_battle_classic_pressed)
	battle_blitz.pressed.connect(_on_battle_blitz_pressed)
	battle_survival.pressed.connect(_on_battle_survival_pressed)
	battle_draft.pressed.connect(_on_battle_draft_pressed)
	battle_custom.pressed.connect(_on_battle_custom_pressed)
	
func _on_playercollection_pressed():
	get_tree().change_scene_to_file("res://CollectionScene.tscn")
	
func _on_buypacks_pressed():
	get_tree().change_scene_to_file("res://PackOpening.tscn")
	
func _on_battle_classic_pressed():
	get_tree().change_scene_to_file("res://BattleScene.tscn")

func _on_battle_blitz_pressed():
	var blitz_scene = load("res://BlitzBattleScene.gd").new()
	get_tree().current_scene.add_child(blitz_scene)

func _on_battle_survival_pressed():
	var survival_scene = load("res://SurvivalBattleScene.gd").new()
	get_tree().current_scene.add_child(survival_scene)

func _on_battle_draft_pressed():
	var draft_scene = load("res://DraftBattleScene.gd").new()
	get_tree().current_scene.add_child(draft_scene)

func _on_battle_custom_pressed():
	var custom_scene = load("res://CustomBattleScene.gd").new()
	get_tree().current_scene.add_child(custom_scene)
