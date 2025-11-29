extends Node2D

# Cangrejos
@onready var crabs := {
	"red": $Crabs/CrabRed,
	"blue": $Crabs/CrabBlue,
	"green": $Crabs/CrabGreen,
	"yellow": $Crabs/CrabYellow
}

# HUD y paneles
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var info_label: Label = $CanvasLayer/InfoLabel

@onready var intro_panel: Control = $intro_panel
@onready var intro_button: Button = $intro_panel/Button

@onready var panel: Panel = $CanvasLayer/GameOverPanel
@onready var title: Label = $CanvasLayer/GameOverPanel/Title
@onready var score_lbl: Label = $CanvasLayer/GameOverPanel/Score
@onready var back_btn: TextureButton = $CanvasLayer/GameOverPanel/Buttons/BackButton
@onready var retry_btn: TextureButton = $CanvasLayer/GameOverPanel/Buttons/RetryButton
@onready var backButton: Button = $CanvasLayer/backButton

# Estado
var is_paused := false
var last_coins_gained: int = 0

var sequence: Array[String] = []
var player_input: Array[String] = []
var colors: Array[String] = ["red", "blue", "green", "yellow"]
var showing_sequence := false
var game_started := false

signal back_to_menu

# Inicio
func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(270, 480))
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	randomize()

	game_started = false
	showing_sequence = true
	panel.visible = false

	intro_panel.visible = true
	info_label.visible = false
	score_label.visible = false
	backButton.visible = false

	intro_button.connect("pressed", Callable(self, "_on_intro_pressed"))
	back_btn.connect("pressed", Callable(self, "_on_back_pressed"))
	backButton.pressed.connect(_on_backButton_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)

	for c in colors:
		crabs[c].connect("crab_pressed", Callable(self, "_on_crab_pressed"))

# Intro
func _on_intro_pressed() -> void:
	intro_panel.visible = false
	info_label.visible = true
	score_label.visible = true
	backButton.visible = true
	await get_tree().create_timer(0.3).timeout
	_start_game()

# Nueva partida
func _start_game() -> void:
	game_started = false
	showing_sequence = true
	panel.visible = false
	score_label.text = "Puntaje: 0"
	info_label.text = "Observa..."
	sequence.clear()
	player_input.clear()
	_add_color_to_sequence()
	await _play_sequence()

# Secuencia
func _add_color_to_sequence() -> void:
	var new_color: String = colors[randi() % colors.size()]
	sequence.append(new_color)
	print("Secuencia actual:", sequence)

func _play_sequence() -> void:
	showing_sequence = true
	game_started = false
	player_input.clear()
	info_label.text = "Observa..."

	for color in sequence:
		if crabs.has(color):
			crabs[color]._flash()
			await get_tree().create_timer(0.6).timeout

	showing_sequence = false
	game_started = true
	info_label.text = "Tu turno"
	print("Tu turno, secuencia esperada:", sequence)

# Input jugador
func _on_crab_pressed(color: String) -> void:
	if panel.visible or is_paused:
		return
	if showing_sequence or not game_started:
		print("Bloqueado (turno del juego o aun no inicia).")
		return

	player_input.append(color)
	crabs[color]._flash()
	print("Crab tocado:", color)

	var index := player_input.size() - 1
	if index >= sequence.size():
		return

	if player_input[index] != sequence[index]:
		_game_over()
		return

	if player_input.size() == sequence.size():
		_next_round()

# Rondas
func _next_round() -> void:
	game_started = false
	showing_sequence = true
	score_label.text = "Puntaje: %d" % sequence.size()
	info_label.text = "Bien hecho!"
	await get_tree().create_timer(1.0).timeout
	_add_color_to_sequence()
	await _play_sequence()

# Game over
func _game_over() -> void:
	if sequence.size() > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			score_manager.save_high_score("nyuron_color", sequence.size())
			var coins_earned = int(sequence.size() * 20.0)
			if coins_earned > 0 and score_manager:
				score_manager.add_coins(coins_earned)
				print("Ganaste:", coins_earned, "monedas")
				last_coins_gained = coins_earned

	game_started = false
	showing_sequence = true
	info_label.text = ""
	score_lbl.text = "Puntaje: %d" % sequence.size()
	$CanvasLayer/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained
	title.text = "Fallaste"
	panel.visible = true

	print("Fallo. Secuencia era:", sequence, "| Jugador puso:", player_input)

# Navegación
func _on_back_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

# Pausa
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not is_paused:
			pause_game()
		else:
			resume_game()

func pause_game():
	is_paused = true
	showing_sequence = true
	game_started = false

	for color in colors:
		if crabs.has(color):
			crabs[color].input_pickable = false
			crabs[color].set_process(false)
			var sprite = crabs[color].get_node("AnimatedSprite2D")
			if sprite and sprite.is_playing():
				sprite.pause()

	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	backButton.process_mode = Node.PROCESS_MODE_ALWAYS

	panel.visible = true
	title.text = "Pausa"
	score_lbl.text = "Puntaje: %d" % sequence.size()
	back_btn.visible = true
	retry_btn.visible = true

	print("Juego pausado - Secuencia congelada")

func resume_game():
	is_paused = false

	if not showing_sequence:
		game_started = true

	for color in colors:
		if crabs.has(color):
			crabs[color].input_pickable = true
			crabs[color].set_process(true)
			var sprite = crabs[color].get_node("AnimatedSprite2D")
			if sprite and not sprite.is_playing():
				sprite.play()

	if title.text == "Pausa":
		panel.visible = false

	print("Juego reanudado")

func _on_backButton_pressed():
	if not is_paused:
		pause_game()
	else:
		print("Volviendo al menú desde pausa")
		back_to_menu.emit()
