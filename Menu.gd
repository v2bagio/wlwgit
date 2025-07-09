extends Node2D


@onready var playercollection = $MenuBar/PlayerCollection
@onready var play = $MenuBar/Play
@onready var marketplace = $MenuBar/Marketplace
@onready var configmenu = $MenuBar/ConfigMenu
@onready var news = $MenuBar/Novidades
@onready var allcollections = $MenuBar/AllCollections
@onready var buypacks = $MenuBar/PackStore

var CardScene = preload("res://Card.tscn")
var PackOpening = preload("res://PackOpening.tscn")

func _ready():
	playercollection.pressed.connect(_on_playercollection_pressed)
	buypacks.pressed.connect(_on_buypacks_pressed)
	
	
func _on_playercollection_pressed():
	get_tree().change_scene_to_file("res://CollectionScene.tscn")
	
func _on_buypacks_pressed():
	get_tree().change_scene_to_file("res://PackOpening.tscn")
