# ResourceLoader.gd (autoload)
extends Node

var texture_cache = {}

func load_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	
	if ResourceLoader.exists(path):
		var texture = load(path)
		texture_cache[path] = texture
		return texture
	
	printerr("Texture not found: ", path)
	return null
