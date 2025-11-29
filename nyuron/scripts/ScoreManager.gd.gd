extends Node

const SAVE_PATH = "user://high_scores.cfg"

# Señal para avisar a la tienda y al personaje que la apariencia cambió
signal skin_updated ### NUEVO

# Datos
var high_scores = {
	"memorice": 0,
	"turtle_runner": 0,
	"worm_catch": 0,
	"food_catch": 0,
	"counting_animals": 0,
	"nyuron_color": 0
}
var coins := 0
var inventory: Array = []

# ### NUEVO: Variables para guardar lo equipado actualmente
# Define aquí los nombres por defecto de tus sprites base
var equipped_items = {
	"caparazon": "default", 
	"accesorio": "none"
}

# Configuración Inicial
func _ready():
	load_high_scores()

# Monedas
func add_coins(amount: int):
	coins += amount
	save_to_file()
	print("Monedas actuales:", coins)

func get_coins() -> int:
	return coins

# Inventario
func add_to_inventory(item_name: String):
	if not inventory.has(item_name):
		inventory.append(item_name)
		save_to_file() # ### NUEVO: Es buena idea guardar apenas compras

func get_inventory() -> Array:
	return inventory

# ### NUEVO: Funciones de Equipado
func equip_item(category: String, item_name: String):
	# Verificamos si tenemos el item O si es un item por defecto (como "none" o "default")
	if inventory.has(item_name) or item_name == "default" or item_name == "none":
		equipped_items[category] = item_name
		save_to_file()
		emit_signal("skin_updated") # Avisamos a todos que cambiamos de ropa
		print("Equipado: ", item_name, " en ", category)
	else:
		print("Error: No tienes el item ", item_name)

func get_equipped_item(category: String) -> String:
	return equipped_items.get(category, "none")

func is_equipped(item_name: String) -> bool:
	return item_name == equipped_items["caparazon"] or item_name == equipped_items["accesorio"]

# Highscores
func save_high_score(game_name: String, new_score: int) -> bool:
	if not high_scores.has(game_name):
		print("Error: Juego '%s' no registrado" % game_name)
		return false

	if new_score > high_scores[game_name]:
		high_scores[game_name] = new_score
		save_to_file()
		print("Nuevo récord en %s: %d" % [game_name, new_score])
		return true
	else:
		print("Puntaje %d no supera el récord %d" % [new_score, high_scores[game_name]])
		return false

func get_high_score(game_name: String) -> int:
	return high_scores.get(game_name, 0)

func load_high_scores():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)

	if error != OK:
		print("Creando archivo de progreso...")
		save_to_file()
		return

	for game in high_scores.keys():
		high_scores[game] = config.get_value("high_scores", game, 0)

	coins = config.get_value("player_data", "coins", 0)
	inventory = config.get_value("inventory", "items", [])
	
	# ### NUEVO: Cargar equipamiento. Si no existe, usa los valores por defecto definidos arriba
	equipped_items = config.get_value("player_data", "equipped_items", equipped_items)

	print("Puntajes cargados:", high_scores)
	print("Monedas cargadas:", coins)
	print("Inventario cargado:", inventory)
	print("Equipado cargado:", equipped_items)

func save_to_file():
	var config = ConfigFile.new()
	config.load(SAVE_PATH)

	for game in high_scores.keys():
		config.set_value("high_scores", game, high_scores[game])

	config.set_value("player_data", "coins", coins)
	config.set_value("inventory", "items", inventory)
	
	# ### NUEVO: Guardar equipamiento
	config.set_value("player_data", "equipped_items", equipped_items)

	var error = config.save(SAVE_PATH)
	if error != OK:
		print("Error guardando:", error)
	else:
		print("Progreso guardado")

# Utilidades
func get_all_scores() -> Dictionary:
	return high_scores.duplicate()
