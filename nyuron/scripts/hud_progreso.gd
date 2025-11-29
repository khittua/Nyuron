extends Control

signal play_game_pressed(game_key: String)
signal back_pressed

# UI
@onready var label_jugador: Label = $LabelJugador
@onready var label_progreso: Label = $LabelProgreso
@onready var vbox_logros: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainerLogros

# Rangos por juego
var RANGOS_JUEGO := {
	"memorice": { "bronce": 200, "plata": 400, "oro": 600, "diamante": 1000 },
	"turtle_runner": { "bronce": 1000, "plata": 2000, "oro": 3000, "diamante": 4000 },
	"worm_catch": { "bronce": 60, "plata": 80, "oro": 100, "diamante": 115 },
	"food_catch": { "bronce": 1000, "plata": 2000, "oro": 2500, "diamante": 3000 },
	"counting_animals": { "bronce": 50, "plata": 150, "oro": 300, "diamante": 500 },
	"nyuron_color": { "bronce": 8, "plata": 12, "oro": 16, "diamante": 20 }
}

# Configuracion Inicial
func _ready():
	update_info()
	update_logros()

# Info jugador / encabezado
func update_info():
	var config = ConfigFile.new()
	if config.load("user://player_data.cfg") == OK:
		var name = config.get_value("player", "name", "Jugador")
		label_jugador.text = "Jugador: " + str(name)

	label_progreso.text = "Progreso en los minijuegos:"

# Construcción de tarjetas de logros
func update_logros():
	var scores = {}
	var cfg = ConfigFile.new()
	if cfg.load("user://high_scores.cfg") == OK:
		for key in cfg.get_section_keys("high_scores"):
			scores[key] = int(cfg.get_value("high_scores", key, 0))

	for card in vbox_logros.get_children():
		if not (card is Panel):
			continue

		var game_key = ""
		var button_name = ""

		match card.name:
			"Card_TurtleRun":
				game_key = "turtle_runner"; button_name = "TurtleButton"
			"Card_WormBucket":
				game_key = "worm_catch"; button_name = "WormButton"
			"Card_FoodCatch":
				game_key = "food_catch"; button_name = "FoodButton"
			"Card_Memorice":
				game_key = "memorice"; button_name = "MemoriceButton"
			"Card_CountingAnimals":
				game_key = "counting_animals"; button_name = "CountingButton"
			"Card_NyuronColor":
				game_key = "nyuron_color"; button_name = "ColorButton"

		if game_key == "" or button_name == "":
			continue

		var label_nombre: Label = card.get_node("HBox_Main/VBox_Info/HBoxHeader/LabelNombre")
		var icono: TextureRect = card.get_node("HBox_Main/MarginContainer/TextureRectLogro")
		var boton: Button = card.get_node("HBox_Main/VBox_Info/HBoxHeader/" + button_name)
		var progress_bar: ProgressBar = card.get_node("HBox_Main/VBox_Info/ProgressBar")
		var progress_label: Label = card.get_node("HBox_Main/VBox_Info/ProgressBar/ProgressLabel")

		if not (boton and icono and label_nombre and progress_label):
			push_error("¡Faltan nodos en '%s'! Revisa las rutas y la estructura de la escena." % card.name)
			continue

		var score = scores.get(game_key, 0)
		label_nombre.text = nombre_juego_legible(game_key)

		var progress_info = _get_progress_info(game_key, score)

		if progress_info.next_trophy == "none":
			progress_bar.visible = false
			progress_label.text = "N/A"
		elif progress_info.next_trophy == "max":
			progress_bar.visible = true
			progress_bar.min_value = 0
			progress_bar.max_value = progress_info.max
			progress_bar.value = score
			progress_label.text = "¡Máximo! (%d)" % score
		else:
			progress_bar.visible = true
			progress_bar.min_value = progress_info.min
			progress_bar.max_value = progress_info.max
			progress_bar.value = score
			progress_label.text = "%d / %d" % [score, progress_info.max]

		icono.texture = load(icono_por_score(game_key, score))

		if not boton.is_connected("pressed", Callable(self, "_on_jugar_pressed")):
			boton.connect("pressed", Callable(self, "_on_jugar_pressed").bind(game_key))

# iconos
func nombre_juego_legible(game_key: String) -> String:
	match game_key:
		"turtle_runner": return "Carrera de Tortugas"
		"worm_catch": return "Caza de Gusanos"
		"food_catch": return "Atrapa Comida"
		"memorice": return "Memorice Marino"
		"counting_animals": return "Conteo Marino"
		"nyuron_color": return "Nyuron Canta"
		_: return game_key

func icono_por_score(game_key: String, score: int) -> String:
	if not RANGOS_JUEGO.has(game_key):
		return "res://assets/bronze.png"

	var rangos = RANGOS_JUEGO[game_key]

	if score >= rangos["diamante"]:
		return "res://assets/diamond.png"
	elif score >= rangos["oro"]:
		return "res://assets/gold.png"
	elif score >= rangos["plata"]:
		return "res://assets/silver.png"
	elif score >= rangos["bronce"]:
		return "res://assets/bronze.png"
	else:
		return "res://assets/bronze.png"

# Progreso numerico
func _get_progress_info(game_key: String, score: int) -> Dictionary:
	if not RANGOS_JUEGO.has(game_key):
		return { "min": 0, "max": 100, "current": 0, "next_trophy": "none" }

	var rangos = RANGOS_JUEGO[game_key]

	if score < rangos["bronce"]:
		return { "min": 0, "max": rangos["bronce"], "current": score, "next_trophy": "bronce" }
	elif score < rangos["plata"]:
		return { "min": rangos["bronce"], "max": rangos["plata"], "current": score, "next_trophy": "plata" }
	elif score < rangos["oro"]:
		return { "min": rangos["plata"], "max": rangos["oro"], "current": score, "next_trophy": "oro" }
	elif score < rangos["diamante"]:
		return { "min": rangos["oro"], "max": rangos["diamante"], "current": score, "next_trophy": "diamante" }
	else:
		return { "min": 0, "max": rangos["diamante"], "current": score, "next_trophy": "max" }

# Cerrar panel
func _on_back_pressed():
	back_pressed.emit()

# Jugar minijuego desde la tarjeta
func _on_jugar_pressed(game_key: String):
	play_game_pressed.emit(game_key)
