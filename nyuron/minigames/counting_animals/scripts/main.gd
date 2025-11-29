extends Node2D

signal finished_moving

# UI Principal
@onready var instruction_label = $CanvasLayer/instruction_label
@onready var number_buttons = $CanvasLayer/number_buttons
@onready var animal_preview = $CanvasLayer/AnimalPreview
@onready var animal_container = $CanvasLayer/animal_container
@onready var intro_panel = $CanvasLayer/intro_panel
@onready var intro_label = $CanvasLayer/intro_panel/Label
@onready var play_button = $CanvasLayer/intro_panel/Button

# UI Game Over / Info
@onready var score_label = $CanvasLayer/score_label
@onready var panel: Panel = $CanvasLayer/GameOverPanel
@onready var title: Label = $CanvasLayer/GameOverPanel/Title
@onready var points_label: Label = $CanvasLayer/GameOverPanel/Score
@onready var back_btn: TextureButton = $CanvasLayer/GameOverPanel/Buttons/BackButton
@onready var retry_btn: TextureButton = $CanvasLayer/GameOverPanel/Buttons/RetryButton
@onready var backButton: Button = $CanvasLayer/backButton

# Lógica
@onready var spawner = $AnimalSpawner

# Variables de Estado
var is_paused := false
var last_coins_gained: int = 0
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

# Inicialización
func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS

	setup_number_buttons()
	number_buttons.hide()
	score_label.hide()
	panel.hide()

	if animal_preview and not animal_preview.is_in_group("AnimalPreviewGroup"):
		animal_preview.add_to_group("AnimalPreviewGroup")

	spawner.connect("spawn_finished", Callable(self, "_on_spawn_finished"))

	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	retry_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	backButton.process_mode = Node.PROCESS_MODE_ALWAYS

	back_btn.pressed.connect(_on_back_pressed)
	backButton.pressed.connect(_on_backButton_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)

	intro_panel.show()
	play_button.pressed.connect(_on_play_pressed)

# Pausa
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not is_paused:
			pause_game()
		else:
			resume_game()

func pause_game():
	print("Pausando juego...")
	is_paused = true

	if spawner:
		spawner.process_mode = Node.PROCESS_MODE_DISABLED
		if spawner.has_method("pause"):
			spawner.pause()

	pause_all_animals(true)

	number_buttons.process_mode = Node.PROCESS_MODE_DISABLED
	animal_container.process_mode = Node.PROCESS_MODE_DISABLED
	instruction_label.process_mode = Node.PROCESS_MODE_DISABLED

	panel.visible = true
	title.text = "Pausa"
	points_label.text = "Puntaje: %d" % score
	back_btn.visible = true
	animal_preview.hide()
	instruction_label.visible = false
	intro_panel.visible = false

	print("Juego pausado")

func resume_game():
	print("Reanudando juego...")
	is_paused = false

	if spawner:
		spawner.process_mode = Node.PROCESS_MODE_INHERIT
		if spawner.has_method("resume"):
			spawner.resume()

	pause_all_animals(false)

	number_buttons.process_mode = Node.PROCESS_MODE_INHERIT
	animal_container.process_mode = Node.PROCESS_MODE_INHERIT
	instruction_label.process_mode = Node.PROCESS_MODE_INHERIT

	panel.visible = false
	animal_preview.show()
	instruction_label.visible = true
	intro_panel.visible = true

	print("Juego reanudado")

func pause_all_animals(pause: bool):
	var animal_count = 0
	for animal in get_tree().get_nodes_in_group("spawned_animals"):
		if is_instance_valid(animal):
			if pause:
				animal.process_mode = Node.PROCESS_MODE_DISABLED
				var anim := animal.get_node_or_null("AnimatedSprite2D")
				if anim:
					anim.speed_scale = 0.0
			else:
				animal.process_mode = Node.PROCESS_MODE_INHERIT
				var anim := animal.get_node_or_null("AnimatedSprite2D")
				if anim:
					anim.speed_scale = 1.0
			animal_count += 1

# Inicio partida
func _on_play_pressed():
	intro_panel.hide()

	var t := create_tween()
	t.tween_property(intro_panel, "modulate:a", 0.0, 0.8)
	await t.finished

	intro_panel.hide()
	score_label.show()
	start_round()

# Rondas
func start_round():
	if is_paused:
		return

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

func _on_spawn_finished():
	if is_paused:
		return

	counting = false
	correct_count = 0

	await get_tree().create_timer(1.0).timeout

	for t in current_targets:
		correct_count += spawner.get_correct_count_for(t.to_lower())

	show_answer_choices()

# Visualización
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
		"tortuguita":
			return load("res://minigames/counting_animals/assets/Presentacion/cTortuga.png")
		"foca":
			return load("res://minigames/counting_animals/assets/Presentacion/cFoca.png")
		"nyuron_azul":
			return load("res://minigames/counting_animals/assets/Presentacion/cAzul.png")
		"nyuron_lengua":
			return load("res://minigames/counting_animals/assets/Presentacion/cNyuron.png")
		"nyuron_soda":
			return load("res://minigames/counting_animals/assets/Presentacion/cSoda.png")
		"tortuguita_estrella":
			return load("res://minigames/counting_animals/assets/Presentacion/cEstrella.png")
		_:
			return null

# Opciones de respuesta
func show_answer_choices():
	if is_paused:
		return

	instruction_label.text = "¿Cuántas viste en total?"
	number_buttons.show()

func setup_number_buttons():
	for btn in number_buttons.get_children():
		var num = int(btn.name.replace("btn", ""))
		btn.pressed.connect(_on_number_pressed.bind(str(num)))

func _on_number_pressed(num_str: String):
	if is_paused:
		return

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

	if correct_streak >= 2:
		correct_streak = 0
		difficulty_level = min(difficulty_level + 1, 3)
		instruction_label.text += "\n Subes a dificultad %d" % difficulty_level

	await get_tree().create_timer(2.0).timeout
	start_round()

# Navegación
func _on_back_pressed() -> void:
	get_tree().paused = false
	is_paused = false

	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_backButton_pressed():
	if not is_paused:
		pause_game()
	else:
		resume_game()

# Puntuación y Dificultad
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

# Fin del Juego
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

	for n in get_tree().get_nodes_in_group("AnimalPreviewGroup"):
		if is_instance_valid(n):
			n.visible = false
			n.texture = null
			n.hide()

	for node in get_tree().get_nodes_in_group("root"):
		if is_instance_valid(node) and node.name == "AnimalPreview" and node != animal_preview:
			node.queue_free()

	# Guardado de puntaje
	var final_score = int(score)
	if final_score > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			# Se corrigió "turtle_runner" a "counting_animals"
			score_manager.save_high_score("counting_animals", final_score)
			var coins_earned = int(final_score * 2.0)
			if coins_earned > 0 and score_manager:
				score_manager.add_coins(coins_earned)
				print("Ganaste: ", coins_earned, " monedas")
				last_coins_gained = coins_earned

	panel.visible = true
	title.text = "¡Fin del Juego!"
	points_label.text = "Puntaje: %d" % score
	$CanvasLayer/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained

	back_btn.visible = true
	animal_preview.hide()
	instruction_label.visible = false
	intro_panel.visible = false
