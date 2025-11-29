extends Node2D

# UI y Nodos
@onready var parallax := $ParallaxBackground
@onready var spawn_timer := $SpawnTimer
@onready var obstacle_container := $ObstacleContainer
@onready var bonus_container := $BonusContainer
@onready var score_label := $UI/Label

# Paneles UI
@onready var panel: Control = $UI/GameOverPanel
@onready var title_lbl: Label = $UI/GameOverPanel/Title
@onready var score_lbl: Label = $UI/GameOverPanel/Score
@onready var back_btn: TextureButton = $UI/GameOverPanel/Buttons/BackButton
@onready var retry_btn: TextureButton = $UI/GameOverPanel/Buttons/RetryButton
@onready var backButton: Button = $UI/backButton
@onready var intro_panel := $intro_panel
@onready var intro_button := $intro_panel/Button

# Audio
@onready var sfx_bonus := $AudioBonus
@onready var sfx_hit := $AudioHit

# Configuración Exportada
@export var scroll_speed := 200.0
@export var floating_text_scene: PackedScene
@export var obstacle_scene: PackedScene
@export var bonus_scene: PackedScene
@export var lanes := [100.0, 160.0, 220.0]

# Variables de Estado
var last_coins_gained: int = 0
var score: float = 0.0
var last_lane := -1
var elapsed_time := 0.0
var speed_increase_interval := 6.0
var speed_multiplier := 1.0
var is_paused := false
var is_intro := true

signal back_to_menu

# Configuración Inicial
func _ready() -> void:
	var ui_node := $UI
	if ui_node is CanvasLayer:
		ui_node.follow_viewport_enabled = true

	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	back_btn.pressed.connect(_on_back_pressed)
	backButton.pressed.connect(_on_backButton_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)

	randomize()
	add_to_group("turtle_game")

	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	backButton.process_mode = Node.PROCESS_MODE_ALWAYS

	spawn_timer.wait_time = randf_range(1.0, 2.0)
	spawn_timer.timeout.connect(_on_SpawnTimer_timeout)
	spawn_timer.start()
	spawn_timer.stop()

	is_intro = true
	intro_panel.visible = true
	backButton.visible = false
	intro_button.pressed.connect(_on_intro_play_pressed)

	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.process_mode = Node.PROCESS_MODE_DISABLED
		var anim := turtle.get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.speed_scale = 0.0

# Intro
func _on_intro_play_pressed():
	intro_panel.visible = false
	is_intro = false
	spawn_timer.start()

	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.process_mode = Node.PROCESS_MODE_INHERIT
		var anim := turtle.get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.speed_scale = 1.0

	backButton.visible = true

# Loop Principal
func _process(delta: float) -> void:
	if is_paused or is_intro:
		return
	
	parallax.scroll_offset.x -= scroll_speed * speed_multiplier * delta
	score += delta * 10 * speed_multiplier
	score_label.text = "Puntaje: %d" % int(score)

	elapsed_time += delta
	if elapsed_time >= speed_increase_interval:
		elapsed_time = 0
		speed_multiplier *= 1.1

	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.update_animation_speed(speed_multiplier)

# Spawning de obstaculos
func _on_SpawnTimer_timeout() -> void:
	if is_paused or is_intro:
		return

	spawn_timer.wait_time = randf_range(0.5, 1.5)
	spawn_timer.start()

	var lanes_available = lanes.duplicate()
	if last_lane != -1:
		lanes_available.erase(last_lane)

	var lane_y = lanes_available.pick_random()
	last_lane = lane_y

	if randf() < 0.9:
		spawn_obstacle(lane_y)
	else:
		spawn_bonus(lane_y)

func spawn_obstacle(y_pos: float) -> void:
	if obstacle_scene == null:
		return
	var obstacle = obstacle_scene.instantiate()
	obstacle.position = Vector2(get_viewport_rect().size.x + 50, y_pos)
	obstacle_container.add_child(obstacle)

func spawn_bonus(y_pos: float) -> void:
	if bonus_scene == null:
		return
	var bonus = bonus_scene.instantiate()
	bonus.position = Vector2(get_viewport_rect().size.x + 50, y_pos)
	bonus_container.add_child(bonus)

func add_score_bonus(amount: int) -> void:
	score += amount

# Juego Terminado
func game_over() -> void:
	if is_paused:
		return

	spawn_timer.stop()
	scroll_speed = 0
	set_process(false)

	for node in obstacle_container.get_children():
		node.set_process(false)
	for node in bonus_container.get_children():
		node.set_process(false)

	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.set_process(false)
		var anim := turtle.get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.speed_scale = 0.0

	play_hit_sound()
	await get_tree().create_timer(0.8).timeout
	$UI/Label.visible = false

	var final_score = int(score)
	if final_score > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			score_manager.save_high_score("turtle_runner", final_score)

		var coins_earned = int(final_score * 0.1)
		if coins_earned > 0 and score_manager:
			score_manager.add_coins(coins_earned)
			last_coins_gained = coins_earned

	_show_game_over()

func _show_game_over() -> void:
	title_lbl.text = "Fin del Juego"
	score_lbl.text = "Puntos: %d" % int(score)
	$UI/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained

	panel.visible = true
	back_btn.visible = true

# Sonidos y Efectos
func show_floating_text(pos: Vector2, text := "+50", color := Color(0.645, 0.645, 0.0, 1.0)) -> void:
	if floating_text_scene == null:
		return
	var ft = floating_text_scene.instantiate()
	ft.position = pos
	add_child(ft)
	ft.show_text(text, color)

func play_bonus_sound() -> void:
	if sfx_bonus:
		sfx_bonus.play()

func play_hit_sound() -> void:
	if sfx_hit:
		sfx_hit.play()

# Navegación
func _on_back_pressed() -> void:
	if is_paused:
		resume_game()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_backButton_pressed() -> void:
	if not is_paused:
		pause_game()
	else:
		resume_game()

# Pausa
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not is_paused:
			pause_game()
		else:
			resume_game()

func pause_game():
	is_paused = true
	spawn_timer.paused = true
	parallax.scroll_base_offset = parallax.scroll_offset

	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.process_mode = Node.PROCESS_MODE_DISABLED
		var anim := turtle.get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.speed_scale = 0.0

	pause_all_obstacles(true)
	pause_all_bonus(true)

	sfx_bonus.stream_paused = true
	sfx_hit.stream_paused = true

	panel.visible = true
	title_lbl.text = "Pausa"
	score_lbl.text = "Puntos: %d" % int(score)
	back_btn.visible = true

func resume_game():
	is_paused = false
	spawn_timer.paused = false

	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.process_mode = Node.PROCESS_MODE_INHERIT
		var anim := turtle.get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.speed_scale = 1.0

	pause_all_obstacles(false)
	pause_all_bonus(false)

	sfx_bonus.stream_paused = false
	sfx_hit.stream_paused = false

	panel.visible = false

# Auxiliares de pausa
func pause_all_obstacles(pause: bool):
	for obstacle in obstacle_container.get_children():
		if is_instance_valid(obstacle):
			obstacle.process_mode = Node.PROCESS_MODE_DISABLED if pause else Node.PROCESS_MODE_INHERIT
			var anim := obstacle.get_node_or_null("AnimatedSprite2D")
			if anim:
				anim.speed_scale = 0.0 if pause else 1.0

func pause_all_bonus(pause: bool):
	for bonus in bonus_container.get_children():
		if is_instance_valid(bonus):
			bonus.process_mode = Node.PROCESS_MODE_DISABLED if pause else Node.PROCESS_MODE_INHERIT
			var anim := bonus.get_node_or_null("AnimatedSprite2D")
			if anim:
				anim.speed_scale = 0.0 if pause else 1.0
