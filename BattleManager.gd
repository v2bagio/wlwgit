# BattleManager.gd - Gerenciador de diferentes formatos de batalha
extends Node

signal battle_started(format: String)
signal battle_ended(winner: int, format: String)

enum BattleFormat {
	CLASSIC,
	BLITZ,
	SURVIVAL,
	DRAFT,
	TOURNAMENT,
	ARENA,
	CUSTOM
}

const FORMAT_NAMES = {
	BattleFormat.CLASSIC: "Clássico",
	BattleFormat.BLITZ: "Blitz",
	BattleFormat.SURVIVAL: "Sobrevivência", 
	BattleFormat.DRAFT: "Draft",
	BattleFormat.TOURNAMENT: "Torneio",
	BattleFormat.ARENA: "Arena",
	BattleFormat.CUSTOM: "Personalizado"
}

const FORMAT_DESCRIPTIONS = {
	BattleFormat.CLASSIC: "Melhor de 3 rodadas com banimento de características",
	BattleFormat.BLITZ: "Rodada única, decisão rápida",
	BattleFormat.SURVIVAL: "5 rodadas, último animal em pé vence",
	BattleFormat.DRAFT: "Jogadores escolhem cartas de um pool comum",
	BattleFormat.TOURNAMENT: "Eliminatória com múltiplos oponentes",
	BattleFormat.ARENA: "Batalhas contínuas com ranking",
	BattleFormat.CUSTOM: "Regras personalizadas pelo jogador"
}

var current_format: BattleFormat
var battle_history: Array = []
var player_stats: Dictionary = {}

func _ready():
	initialize_player_stats()

func initialize_player_stats():
	"""Inicializa as estatísticas dos jogadores"""
	player_stats = {
		"player1": {
			"wins": 0,
			"losses": 0,
			"draws": 0,
			"favorite_characteristics": [],
			"win_rate": 0.0
		},
		"player2": {
			"wins": 0,
			"losses": 0,
			"draws": 0,
			"favorite_characteristics": [],
			"win_rate": 0.0
		}
	}

func start_battle(format: BattleFormat, custom_rules: Dictionary = {}):
	"""Inicia uma batalha com o formato especificado"""
	current_format = format
	emit_signal("battle_started", FORMAT_NAMES[format])
	
	match format:
		BattleFormat.CLASSIC:
			_start_classic_battle()
		BattleFormat.BLITZ:
			_start_blitz_battle()
		BattleFormat.SURVIVAL:
			_start_survival_battle()
		BattleFormat.DRAFT:
			_start_draft_battle()
		BattleFormat.TOURNAMENT:
			_start_tournament_battle()
		BattleFormat.ARENA:
			_start_arena_battle()
		BattleFormat.CUSTOM:
			_start_custom_battle(custom_rules)

func _start_classic_battle():
	"""Inicia uma batalha clássica"""
	var battle_scene = load("res://BattleScene.tscn").instantiate()
	battle_scene.initialize_battle(BattleFormat.CLASSIC)
	get_tree().current_scene.add_child(battle_scene)

func _start_blitz_battle():
	"""Inicia uma batalha blitz (rodada única)"""
	var battle_scene = load("res://BlitzBattleScene.tscn").instantiate()
	get_tree().current_scene.add_child(battle_scene)

func _start_survival_battle():
	"""Inicia uma batalha de sobrevivência"""
	var battle_scene = load("res://SurvivalBattleScene.tscn").instantiate()
	get_tree().current_scene.add_child(battle_scene)

func _start_draft_battle():
	"""Inicia uma batalha draft"""
	var battle_scene = load("res://DraftBattleScene.tscn").instantiate()
	get_tree().current_scene.add_child(battle_scene)

func _start_tournament_battle():
	"""Inicia um torneio"""
	var tournament_scene = load("res://TournamentScene.tscn").instantiate()
	get_tree().current_scene.add_child(tournament_scene)

func _start_arena_battle():
	"""Inicia uma batalha de arena"""
	var arena_scene = load("res://ArenaScene.tscn").instantiate()
	get_tree().current_scene.add_child(arena_scene)

func _start_custom_battle(rules: Dictionary):
	"""Inicia uma batalha com regras personalizadas"""
	var custom_scene = load("res://CustomBattleScene.tscn").instantiate()
	custom_scene.apply_custom_rules(rules)
	get_tree().current_scene.add_child(custom_scene)

func record_battle_result(winner: int, format: BattleFormat, details: Dictionary = {}):
	"""Registra o resultado de uma batalha"""
	var battle_record = {
		"timestamp": Time.get_datetime_string_from_system(),
		"format": FORMAT_NAMES[format],
		"winner": winner,
		"details": details
	}
	
	battle_history.append(battle_record)
	update_player_stats(winner)
	emit_signal("battle_ended", winner, FORMAT_NAMES[format])

func update_player_stats(winner: int):
	"""Atualiza as estatísticas dos jogadores"""
	match winner:
		1:
			player_stats.player1.wins += 1
			player_stats.player2.losses += 1
		2:
			player_stats.player2.wins += 1
			player_stats.player1.losses += 1
		0:
			player_stats.player1.draws += 1
			player_stats.player2.draws += 1
	
	# Calcular taxa de vitória
	for player in ["player1", "player2"]:
		var stats = player_stats[player]
		var total_games = stats.wins + stats.losses + stats.draws
		if total_games > 0:
			stats.win_rate = float(stats.wins) / total_games

func get_player_stats(player: String) -> Dictionary:
	"""Retorna as estatísticas de um jogador"""
	return player_stats.get(player, {})

func get_battle_history() -> Array:
	"""Retorna o histórico de batalhas"""
	return battle_history

func get_format_description(format: BattleFormat) -> String:
	"""Retorna a descrição de um formato"""
	return FORMAT_DESCRIPTIONS.get(format, "Formato desconhecido")

func create_custom_rules() -> Dictionary:
	"""Cria regras personalizadas para batalha"""
	return {
		"max_rounds": 3,
		"ban_count_per_player": 2,
		"system_ban_enabled": true,
		"deck_size": 5,
		"allow_duplicates": false,
		"time_limit_per_turn": 30,
		"special_rules": []
	}

# Funções específicas para cada formato

class ClassicBattleRules:
	"""Regras para batalha clássica"""
	const MAX_ROUNDS = 3
	const BANS_PER_PLAYER = 2
	const SYSTEM_BAN = true
	const DECK_SIZE = 5

class BlitzBattleRules:
	"""Regras para batalha blitz"""
	const MAX_ROUNDS = 1
	const BANS_PER_PLAYER = 1
	const SYSTEM_BAN = false
	const DECK_SIZE = 3
	const TIME_LIMIT = 15

class SurvivalBattleRules:
	"""Regras para batalha de sobrevivência"""
	const MAX_ROUNDS = 5
	const BANS_PER_PLAYER = 3
	const SYSTEM_BAN = true
	const DECK_SIZE = 8
	const ELIMINATION_MODE = true

class DraftBattleRules:
	"""Regras para batalha draft"""
	const DRAFT_POOL_SIZE = 12
	const PICKS_PER_PLAYER = 6
	const BANS_PER_PLAYER = 1
	const SYSTEM_BAN = false

class TournamentBattleRules:
	"""Regras para torneio"""
	const PARTICIPANTS = 8
	const ROUNDS = 3
	const ELIMINATION = true
	const DECK_SIZE = 6

class ArenaBattleRules:
	"""Regras para arena"""
	const CONTINUOUS_BATTLES = true
	const RANKING_SYSTEM = true
	const SEASONAL_REWARDS = true
	const DECK_SIZE = 10

