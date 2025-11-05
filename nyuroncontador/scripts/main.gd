extends Node2D

@onready var spawner = $AnimalSpawner
@onready var instruction_label = $CanvasLayer/instruction_label
@onready var number_buttons = $CanvasLayer/number_buttons
@onready var animal_preview = $CanvasLayer/AnimalPreview
@onready var animal_container = $CanvasLayer/animal_container
@onready var intro_panel = $CanvasLayer/intro_panel
@onready var intro_label = $CanvasLayer/intro_panel/Label
@onready var play_button = $CanvasLayer/intro_panel/Button
@onready var score_label = $CanvasLayer/score_label
@onready var game_over_panel = $CanvasLayer/game_over_panel
@onready var title_label = $CanvasLayer/game_over_panel/title_label
@onready var points_label = $CanvasLayer/game_over_panel/points_label
@onready var retry_button = $CanvasLayer/game_over_panel/retry_button
@onready var back_button = $CanvasLayer/game_over_panel/back_button


var counting = false
var current_target: String = ""
var correct_count = 0
var difficulty_level := 1
var correct_streak := 0
var current_targets: Array = []
var score := 0
var rounds_completed := 0


var animal_names := {
	"foca": "focas",
	"nyuron_azul": "Nyuron Azules",
	"nyuron_lengua": "Nyuron con lengua",
	"nyuron_soda": "Nyuron Soda",
	"tortuguita": "Tortuguitas",
	"tortuguita_estrella": "Tortuguitas Estrella"
}


# ------------------------------------------------------------
# 🔹 READY
# ------------------------------------------------------------
func _ready():
	setup_number_buttons()
	number_buttons.hide()
	score_label.hide()
	game_over_panel.hide()

	# ✅ Solo el AnimalPreview correcto va en el grupo
	if animal_preview and not animal_preview.is_in_group("AnimalPreviewGroup"):
		animal_preview.add_to_group("AnimalPreviewGroup")

	spawner.connect("spawn_finished", Callable(self, "_on_spawn_finished"))
	intro_panel.show()
	play_button.pressed.connect(_on_play_pressed)


# ------------------------------------------------------------
# 🔹 INTRO → INICIO
# ------------------------------------------------------------
func _on_play_pressed():
	intro_panel.hide()

	var t := create_tween()
	t.tween_property(intro_panel, "modulate:a", 0.0, 0.8)
	await t.finished

	intro_panel.hide()
	score_label.show()
	start_round()


# ------------------------------------------------------------
# 🔹 INICIO DE RONDA
# ------------------------------------------------------------
func start_round():
	counting = false
	current_targets.clear()

	var num_types = clamp(difficulty_level, 1, 3)
	var all_types = []

	for s in spawner.animals:
		var inst = s.instantiate()
		if "type_id" in inst:
			all_types.append(inst.type_id)
		inst.queue_free()

	all_types.shuffle()
	current_targets = all_types.slice(0, num_types)

	show_instruction(current_targets)

	await get_tree().create_timer(4.0).timeout

	instruction_label.text = ""
	animal_container.hide()
	animal_preview.hide()

	instruction_label.text = "¡Empieza!"
	await get_tree().create_timer(1.5).timeout
	instruction_label.text = ""

	counting = true
	spawner.start_spawning(current_targets[0])


# ------------------------------------------------------------
# 🔹 FIN DE SPAWN
# ------------------------------------------------------------
func _on_spawn_finished():
	counting = false
	correct_count = 0

	await get_tree().create_timer(1.0).timeout

	for t in current_targets:
		correct_count += spawner.get_correct_count_for(t.to_lower())

	show_answer_choices()


# ------------------------------------------------------------
# 🔹 MOSTRAR INSTRUCCIÓN E IMÁGENES
# ------------------------------------------------------------
func show_instruction(animal_type_or_types):
	instruction_label.text = "Animal/es a contar:"
	number_buttons.hide()

	for child in animal_container.get_children():
		child.queue_free()
	animal_container.hide()

	var types_to_show = []
	if typeof(animal_type_or_types) == TYPE_STRING:
		types_to_show = [animal_type_or_types]
	else:
		types_to_show = animal_type_or_types

	for t in types_to_show:
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(64, 64)
		tex.texture = _get_texture_for_animal(t)
		animal_container.add_child(tex)

	animal_container.show()


func _get_texture_for_animal(t: String) -> Texture2D:
	match t:
		"tortuguita": return load("res://assets/Presentacion/cTortuga.png")
		"foca": return load("res://assets/Presentacion/cFoca.png")
		"nyuron_azul": return load("res://assets/Presentacion/cAzul.png")
		"nyuron_lengua": return load("res://assets/Presentacion/cNyuron.png")
		"nyuron_soda": return load("res://assets/Presentacion/cSoda.png")
		"tortuguita_estrella": return load("res://assets/Presentacion/cEstrella.png")
		_: return null


# ------------------------------------------------------------
# 🔹 OPCIONES DE RESPUESTA
# ------------------------------------------------------------
func show_answer_choices():
	instruction_label.text = "¿Cuántas viste en total?"
	number_buttons.show()


func setup_number_buttons():
	for btn in number_buttons.get_children():
		var num = int(btn.name.replace("btn", ""))
		btn.pressed.connect(_on_number_pressed.bind(str(num)))


# ------------------------------------------------------------
# 🔹 RESPUESTA DEL JUGADOR
# ------------------------------------------------------------
func _on_number_pressed(num_str: String):
	var answer = int(num_str)
	number_buttons.hide()

	if answer == correct_count:
		correct_streak += 1
		rounds_completed += 1
		instruction_label.text = "¡Correcto! Eran %d en total." % correct_count
		add_score()
		check_difficulty_progression()
	else:
		instruction_label.text = "Fallaste eran %d en total." % correct_count
		await get_tree().create_timer(2.0).timeout
		show_game_over()
		return

	await get_tree().create_timer(2.0).timeout
	start_round()


# ------------------------------------------------------------
# 🔹 PUNTAJE Y DIFICULTAD
# ------------------------------------------------------------
func add_score():
	var points := 0
	match difficulty_level:
		1: points = 10 + ((rounds_completed - 1) * 5)
		2: points = 40 + ((rounds_completed - 1) * 20)
		3: points = 150 + ((rounds_completed - 1) * 30)

	score += points
	score_label.text = "Puntaje: %d" % score


func check_difficulty_progression():
	match difficulty_level:
		1:
			if rounds_completed >= 3:
				difficulty_level = 2
				rounds_completed = 0
				show_transition_message("¡Nueva dificultad desbloqueada! (Nivel 2)")
		2:
			if rounds_completed >= 5:
				difficulty_level = 3
				rounds_completed = 0
				show_transition_message("¡Máxima dificultad alcanzada! (Nivel 3)")


func show_transition_message(text: String):
	instruction_label.text = text
	await get_tree().create_timer(2.5).timeout
	if instruction_label.text == text:
		instruction_label.text = ""


# ------------------------------------------------------------
# 🔹 GAME OVER
# ------------------------------------------------------------
func show_game_over():
	spawner.stop_spawning()
	counting = false
	get_tree().paused = true

	if instruction_label:
		instruction_label.visible = false
		instruction_label.text = ""

	if animal_container:
		animal_container.visible = false
		for child in animal_container.get_children():
			child.hide()

	if number_buttons:
		number_buttons.hide()
	if score_label:
		score_label.hide()
	if intro_panel:
		intro_panel.hide()

	# 🧹 Limpieza del AnimalPreview fantasma
	for n in get_tree().get_nodes_in_group("AnimalPreviewGroup"):
		if is_instance_valid(n):
			n.visible = false
			n.texture = null
			n.hide()

	# Borra copias sueltas fuera del CanvasLayer
	for node in get_tree().get_nodes_in_group("root"):
		if is_instance_valid(node) and node.name == "AnimalPreview" and node != animal_preview:
			node.queue_free()

	if game_over_panel:
		game_over_panel.show()
	if points_label:
		points_label.text = "Puntos: %d" % score

	if not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


# ------------------------------------------------------------
# 🔹 REINTENTAR
# ------------------------------------------------------------
func _on_retry_pressed():
	get_tree().paused = false

	# 🔹 Limpia cualquier texto o nodo visible anterior
	instruction_label.text = ""
	instruction_label.visible = true  # ✅ vuelve a activarse visualmente
	number_buttons.hide()
	animal_container.hide()
	animal_preview.hide()
	game_over_panel.hide()

	# 🔹 Limpia el spawner sin borrar sus timers
	spawner.stop_spawning()

	# Limpia animales instanciados si los tienes en grupo (opcional)
	for node in get_tree().get_nodes_in_group("SpawnedAnimals"):
		if is_instance_valid(node):
			node.queue_free()

	# 🔹 Reinicia variables
	score = 0
	score_label.text = "Puntaje: 0"
	score_label.show()
	difficulty_level = 1
	correct_streak = 0
	rounds_completed = 0

	start_round()



func _on_back_pressed():
	# Por ahora no hace nada
	pass
