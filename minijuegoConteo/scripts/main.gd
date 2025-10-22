extends Node2D

@onready var spawner = $AnimalSpawner
@onready var instruction_label = $CanvasLayer/instruction_label
@onready var number_buttons = $CanvasLayer/number_buttons
@onready var animal_preview = $CanvasLayer/AnimalPreview
@onready var animal_container = $CanvasLayer/animal_container
@onready var intro_panel = $CanvasLayer/intro_panel
@onready var intro_label = $CanvasLayer/intro_panel/Label
@onready var play_button = $CanvasLayer/intro_panel/Button



var counting = false
var current_target: String = ""
var correct_count = 0
var difficulty_level := 1      # Nivel actual (1 a 3)
var correct_streak := 0        # Racha de respuestas correctas
var current_targets: Array = []  # Lista de tipos a contar (1 o más)
var score := 0                      # Puntaje total del jugador
var rounds_completed := 0           # Rondas superadas en la dificultad actual



var animal_names := {
	"foca": "focas",
	"nyuron_azul": "Nyuron Azules",
	"nyuron_lengua": "Nyuron con lengua",
	"nyuron_soda": "Nyuron Soda",
	"tortuguita": "Tortuguitas",
	"tortuguita_estrella": "Tortuguitas Estrella"
}

# 🔹 Al iniciar la escena
func _ready():
	setup_number_buttons()
	number_buttons.hide()
	spawner.connect("spawn_finished", Callable(self, "_on_spawn_finished"))

	intro_panel.show()
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed():
	intro_panel.hide()

	# Animación de salida
	var t := create_tween()
	t.tween_property(intro_panel, "modulate:a", 0.0, 0.8)
	await t.finished

	intro_panel.hide()
	start_round()



# 🌀 Inicia una nueva ronda
func start_round():
	counting = false
	current_targets.clear()

	# 🔹 Decide cuántos tipos pedir según dificultad
	var num_types = clamp(difficulty_level, 1, 3)
	var all_types = []

	# Sacamos todos los tipos disponibles
	for s in spawner.animals:
		var inst = s.instantiate()
		if "type_id" in inst:
			all_types.append(inst.type_id)
		inst.queue_free()

	all_types.shuffle()
	current_targets = all_types.slice(0, num_types)

	# 🔹 Muestra la instrucción visual antes de empezar
	show_instruction(current_targets)

	# ⏳ Espera 4 segundos y luego comienza el spawn
	await get_tree().create_timer(4.0).timeout

	# 🔹 Ocultamos la instrucción y las imágenes antes de empezar
	instruction_label.text = "¡Empieza!"
	animal_container.hide()  # 👈 ocultar el contenedor múltiple
	animal_preview.hide()    # 👈 por si solo hay uno

	await get_tree().create_timer(2.0).timeout
	instruction_label.text = ""  # 👈 lo limpia

	# 🔹 Ahora sí, empieza la ronda real
	counting = true
	spawner.start_spawning(current_targets[0])




# 🧩 El spawner avisa que TODOS los animales ya se fueron
func _on_spawn_finished():
	counting = false
	correct_count = 0

	# 🔹 Suma la cantidad correcta de todos los tipos pedidos
	for t in current_targets:
		correct_count += spawner.get_correct_count_for(t.to_lower())

	print("✅ Conteo correcto:", correct_count, "para", current_targets)

	show_answer_choices()



# 📋 Muestra el texto de instrucciones (y oculta botones)
func show_instruction(animal_type_or_types):
	instruction_label.text = "Animal/es a contar:"
	number_buttons.hide()

	# Limpia el contenedor
	for child in animal_container.get_children():
		child.queue_free()
	animal_container.hide()

	# Convierte en array si es solo un string
	var types_to_show = []
	if typeof(animal_type_or_types) == TYPE_STRING:
		types_to_show = [animal_type_or_types]
	else:
		types_to_show = animal_type_or_types

	# Agrega una imagen por cada tipo
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
		"tortuguita":
			return load("res://assets/Presentacion/cTortuga.png")
		"foca":
			return load("res://assets/Presentacion/cFoca.png")
		"nyuron_azul":
			return load("res://assets/Presentacion/cAzul.png")
		"nyuron_lengua":
			return load("res://assets/Presentacion/cNyuron.png")
		"nyuron_soda":
			return load("res://assets/Presentacion/cSoda.png")
		"tortuguita_estrella":
			return load("res://assets/Presentacion/cEstrella.png")
		_:
			return null



# 🔢 Muestra las opciones numéricas al jugador
func show_answer_choices():
	var name_list: Array = []
	for t in current_targets:
		name_list.append(animal_names.get(t, t))
	var readable_list = ", ".join(name_list)
	instruction_label.text = "¿Cuántas viste en total?"
	number_buttons.show()



# ⚙️ Conecta los botones del HUD (solo al inicio)
func setup_number_buttons():
	for btn in number_buttons.get_children():
		var num = int(btn.name.replace("btn", ""))
		btn.pressed.connect(_on_number_pressed.bind(str(num)))


# ✅ Lógica cuando el jugador elige una respuesta
func _on_number_pressed(num_str: String):
	var answer = int(num_str)
	number_buttons.hide()

	if answer == correct_count:
		correct_streak += 1
		instruction_label.text = "¡Correcto!  Eran %d en total." % correct_count
	else:
		correct_streak = 0
		difficulty_level = 1
		instruction_label.text = "Fallaste eran %d en total." % correct_count

	# 🔹 Si acierta 2 veces seguidas, sube dificultad
	if correct_streak >= 2:
		correct_streak = 0
		difficulty_level = min(difficulty_level + 1, 3)
		instruction_label.text += "\n⬆️ Subes a dificultad %d" % difficulty_level

	await get_tree().create_timer(2.0).timeout
	start_round()



# 🎲 Elegir un tipo aleatorio de animal disponible
func choose_random_animal_type() -> String:
	if spawner.animals.is_empty():
		return ""
	var available_types: Array[String] = []
	for s in spawner.animals:
		var inst = s.instantiate()
		if "type_id" in inst:
			available_types.append(inst.type_id)
		inst.queue_free()
	return available_types.pick_random()
