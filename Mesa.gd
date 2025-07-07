# Mesa.gd
extends Node2D

@onready var baralho = $Baralho
@onready var mao_do_jogador = $MaoDoJogador

func _ready():
	# Adiciona um espaçamento de 10 pixels entre as cartas
	mao_do_jogador.add_theme_constant_override("separation", 10)

	await get_tree().create_timer(0.2).timeout
	
	for i in range(5):
		var carta_comprada = baralho.comprar_carta()
		if carta_comprada != null:
			mao_do_jogador.add_child(carta_comprada)
