# Global.gd - Singleton para gerenciar estados globais do jogo
extends Node

# Estados globais da interface
var flip_habilitado: bool = false
var hover_habilitado: bool = true
var viewer_opened: bool = false

# Estados do multiplayer
var is_multiplayer_session: bool = false
var local_player_id: int = 0
var opponent_player_id: int = 0

# Configurações do jogo
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

# Estatísticas do jogador
var total_matches_played: int = 0
var total_matches_won: int = 0
var total_packs_opened: int = 0
var total_cards_collected: int = 0

# Configurações de rede
var default_server_port: int = 7000
var last_server_ip: String = "127.0.0.1"

func _ready():
	print("Global: Sistema global inicializado")
	load_game_settings()

# Funções para gerenciar estados da interface
func set_flip_enabled(enabled: bool):
	flip_habilitado = enabled
	print("Global: Flip ", "habilitado" if enabled else "desabilitado")

func set_hover_enabled(enabled: bool):
	hover_habilitado = enabled
	print("Global: Hover ", "habilitado" if enabled else "desabilitado")

func set_viewer_opened(opened: bool):
	viewer_opened = opened
	print("Global: Viewer ", "aberto" if opened else "fechado")

# Funções para gerenciar multiplayer
func start_multiplayer_session(local_id: int, opponent_id: int):
	is_multiplayer_session = true
	local_player_id = local_id
	opponent_player_id = opponent_id
	print("Global: Sessão multiplayer iniciada. Local: ", local_id, ", Oponente: ", opponent_id)

func end_multiplayer_session():
	is_multiplayer_session = false
	local_player_id = 0
	opponent_player_id = 0
	print("Global: Sessão multiplayer encerrada")

func is_local_player(player_id: int) -> bool:
	return player_id == local_player_id

# Funções para estatísticas
func increment_matches_played():
	total_matches_played += 1
	save_game_settings()

func increment_matches_won():
	total_matches_won += 1
	save_game_settings()

func increment_packs_opened():
	total_packs_opened += 1
	save_game_settings()

func update_cards_collected(count: int):
	total_cards_collected = count
	save_game_settings()

func get_win_rate() -> float:
	if total_matches_played == 0:
		return 0.0
	return float(total_matches_won) / float(total_matches_played) * 100.0

# Funções para configurações de áudio
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	save_game_settings()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	# Aplicar ao bus de SFX se existir
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	save_game_settings()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	# Aplicar ao bus de música se existir
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	save_game_settings()

# Funções para salvar/carregar configurações
func save_game_settings():
	var config = ConfigFile.new()
	
	# Seção de áudio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	
	# Seção de estatísticas
	config.set_value("stats", "total_matches_played", total_matches_played)
	config.set_value("stats", "total_matches_won", total_matches_won)
	config.set_value("stats", "total_packs_opened", total_packs_opened)
	config.set_value("stats", "total_cards_collected", total_cards_collected)
	
	# Seção de rede
	config.set_value("network", "default_server_port", default_server_port)
	config.set_value("network", "last_server_ip", last_server_ip)
	
	var error = config.save("user://game_settings.cfg")
	if error != OK:
		printerr("Global: Erro ao salvar configurações: ", error)
	else:
		print("Global: Configurações salvas com sucesso")

func load_game_settings():
	var config = ConfigFile.new()
	var error = config.load("user://game_settings.cfg")
	
	if error != OK:
		print("Global: Arquivo de configurações não encontrado, usando padrões")
		return
	
	# Carregar configurações de áudio
	master_volume = config.get_value("audio", "master_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	
	# Aplicar volumes
	set_master_volume(master_volume)
	set_sfx_volume(sfx_volume)
	set_music_volume(music_volume)
	
	# Carregar estatísticas
	total_matches_played = config.get_value("stats", "total_matches_played", 0)
	total_matches_won = config.get_value("stats", "total_matches_won", 0)
	total_packs_opened = config.get_value("stats", "total_packs_opened", 0)
	total_cards_collected = config.get_value("stats", "total_cards_collected", 0)
	
	# Carregar configurações de rede
	default_server_port = config.get_value("network", "default_server_port", 7000)
	last_server_ip = config.get_value("network", "last_server_ip", "127.0.0.1")
	
	print("Global: Configurações carregadas com sucesso")

# Função para resetar estatísticas
func reset_statistics():
	total_matches_played = 0
	total_matches_won = 0
	total_packs_opened = 0
	total_cards_collected = 0
	save_game_settings()
	print("Global: Estatísticas resetadas")

# Função para obter informações do sistema
func get_system_info() -> Dictionary:
	return {
		"platform": OS.get_name(),
		"version": Engine.get_version_info(),
		"multiplayer_active": is_multiplayer_session,
		"total_cards": total_cards_collected,
		"win_rate": get_win_rate()
	}
