# Baralho.gd
extends Node2D

const CardScene = preload("res://Card.tscn")
var cartas = []

func _ready():
	criar_baralho_teste()
	embaralhar()

func criar_baralho_teste():
	var lista_de_animais = AnimalDatabase.get_animal_list()
	print("Animais a serem carregados para o baralho: ", lista_de_animais)
	
	for id_animal in lista_de_animais:
		for i in range(5): # Cria 5 cópias de cada
			var nova_carta = CardScene.instantiate() as Card
			if nova_carta:
				add_child(nova_carta)
				nova_carta.setup(id_animal)
				cartas.append(nova_carta)
				nova_carta.hide()

func embaralhar():
	cartas.shuffle()

func comprar_carta():
	if cartas.is_empty(): return null
	var carta = cartas.pop_front()
	remove_child(carta)
	carta.show()
	return carta
