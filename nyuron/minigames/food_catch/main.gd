extends Node2D

# UI principal
@onready var player = $Player
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var lives_label: Label = $CanvasLayer/LivesLabel
@onready var damage_border: ColorRect = $CanvasLayer/DamageBorder
@onready var damage_mat: ShaderMaterial = damage_border.material
@onready var panel: Panel = $CanvasLayer/GameOverPanel
@onready var title: Label = $CanvasLayer/GameOverPanel/Title
@onready var score_lbl: Label = $CanvasLayer/GameOverPanel/Score
@onready var retry_btn: TextureButton = $CanvasLayer/GameOverPanel/Buttons/RetryButton
@onready var back_btn: TextureButton = $CanvasLayer/GameOverPanel/Buttons/BackButton
@onready var difficulty_label: Label = $CanvasLayer/DifficultyLabel
@onready var bg: Node2D = $Background
@onready var hud: CanvasLayer = $CanvasLayer
@onready var backButton: Button = $CanvasLayer/backButton

# Sonidos
@onready var sfx_eat: AudioStreamPlayer = $SFX_Eat
@onready var sfx_bad: AudioStreamPlayer = $SFX_Bad
@onready var sfx_bonus: AudioStreamPlayer = $SFX_Bonus

# Intro
@onready var intro_panel: Control = $intro_panel
@onready var play_button: Button = $intro_panel/Button

# Controles touch
@onready var touch_left = $CanvasLayer/TouchLeft
@onready var touch_right = $CanvasLayer/TouchRight

# Dificultad
@export var difficulty_interval: float = 30.0
@export var speed_multiplier: float = 1.2
@export var spawn_multiplier: float = 0.85
var difficulty_stage: int = 0

# Particulas
@onready var pescao1der: CPUParticles2D = $pescao1der
@onready var pescao1izq: CPUParticles2D = $pescao1izq
@onready var pescao2der: CPUParticles2D = $pescao2der
@onready var bubbles: CPUParticles2D = $bubbles

# Spawns
@export var food_scene: PackedScene
@export var trash_scene: PackedScene
@export var bonus_scene: PackedScene
@export var floating_text_scene: PackedScene

@export var bonus_probability: float = 0.05
@export var spawn_every: float = 0.8
@export var trash_probability: float = 0.35

var is_paused := false
var last_coins_gained: int = 0
var score: int = 0
var lives: int = 3
var screen_size: Vector2 = Vector2.ZERO

# HUD flashes
func _flash_label(label: Label, flash_color: Color, in_time := 0.06, out_time := 0.22):
	var base := label.modulate
	var t := create_tween()
	t.tween_property(label, "modulate", flash_color, in_time)
	t.tween_property(label, "modulate", base, out_time)

func _hud_damage_flash(): 
	_flash_label(lives_label, Color(1.0, 0.4, 0.4))

func _hud_pop_flash():    
	_flash_label(score_label, Color("60e55aff"))

# Inicialización
func _ready() -> void:
	touch_left.gui_input.connect(_on_touch_input.bind(-1))
	touch_right.gui_input.connect(_on_touch_input.bind(1))

	hud.follow_viewport_enabled = true
	panel.visible = false
	retry_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	retry_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	back_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	backButton.pressed.connect(_on_backButton_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	if bg:
		bg.z_index = -100
	if player:
		player.visible = true
		player.z_as_relative = false
		player.z_index = 1000

	$SpawnTimer.wait_time = spawn_every
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	$SpawnTimer.start()

	difficulty_stage = 0
	FallingItem.global_speed_multiplier = 1.0

	_update_hud()
	screen_size = get_viewport_rect().size

	intro_panel.visible = true
	player.process_mode = Node.PROCESS_MODE_DISABLED
	$SpawnTimer.stop()
	backButton.visible = false
	touch_left.visible = false
	touch_right.visible = false

	play_button.pressed.connect(_on_play_pressed)

# Intro
func _on_play_pressed() -> void:
	var t := create_tween()
	t.tween_property(intro_panel, "modulate:a", 0.0, 0.4)
	await t.finished
	intro_panel.visible = false

	player.process_mode = Node.PROCESS_MODE_INHERIT
	$SpawnTimer.start()
	backButton.visible = true
	touch_left.visible = true
	touch_right.visible = true

# Spawning de items
func _on_spawn_timer_timeout() -> void:
	var scene: PackedScene
	var roll := randf()
	if roll < bonus_probability:
		scene = bonus_scene
	elif roll < bonus_probability + trash_probability:
		scene = trash_scene
	else:
		scene = food_scene

	if scene == null:
		return

	var item = scene.instantiate()
	if "z_index" in item:
		item.z_index = 20

	var spawn_x = randf_range(40.0, max(40.0, screen_size.x - 40.0))
	item.position = Vector2(spawn_x, -40.0)

	if item is BonusItem:
		item.connect("resolved_bonus", _on_bonus_resolved)
	else:
		item.connect("resolved", _on_item_resolved)

	add_child(item)

func _play_varied(player: AudioStreamPlayer, pmin := 0.95, pmax := 1.05) -> void:
	if player == null:
		return
	if player.playing:
		player.stop()
	player.pitch_scale = randf_range(pmin, pmax)
	player.play()

# Resolución de items
func _on_item_resolved(is_trash: bool) -> void:
	if is_trash:
		lives -= 1
		_play_varied(sfx_bad, 0.9, 1.0)
		_hud_damage_flash()
		_flash_damage_overlay()
		if player and player.has_method("play_damage_flash"):
			player.play_damage_flash()
	else:
		score += 10
		_play_varied(sfx_eat, 1.0, 1.15)
		_hud_pop_flash()
		if player and player.has_method("play_catch_pop"):
			player.play_catch_pop()
		_spawn_floating_text("+10", Color(1, 1, 0.5))

	_update_hud()
	_check_game_over()

func _on_bonus_resolved(points: int) -> void:
	_hud_pop_flash()
	score += points
	_play_varied(sfx_bonus, 1.05, 1.2)
	_spawn_floating_text("+%d" % points, Color(0.414, 0.993, 1.0, 1.0))
	if player and player.has_method("play_catch_pop"):
		player.play_catch_pop()
	_update_hud()

func _update_hud() -> void:
	score_label.text = "Puntos: %d" % score
	lives_label.text = "Vidas: %d" % lives

# Game Over
func _check_game_over() -> void:
	if lives > 0:
		return

	$SpawnTimer.stop()

	if player and player.has_method("play_hide_animation"):
		player.play_hide_animation()
		player.play_damage_flash()

	await get_tree().create_timer(0.8).timeout
	if score > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			score_manager.save_high_score("food_catch", score)
			var coins_earned = int(score * 0.1)
			if coins_earned > 0 and score_manager:
				score_manager.add_coins(coins_earned)
				print("Ganaste:", coins_earned, "monedas")
				last_coins_gained = coins_earned

	_show_game_over()

func _show_game_over() -> void:
	title.text = "¡Fin del Juego!"
	score_lbl.text = "Puntos: %d" % score
	$CanvasLayer/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained
	panel.visible = true
	backButton.visible = false
	touch_left.visible = false
	touch_right.visible = false

# Navegación
func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_back_pressed() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_backButton_pressed() -> void:
	if not is_paused:
		pause_game()
	else:
		resume_game()

# Efectos
func _flash_damage_overlay() -> void:
	if damage_mat == null:
		return
	var tw := create_tween()
	tw.tween_property(damage_mat, "shader_parameter/intensity", 0.5, 0.08).from(0.0)
	tw.tween_property(damage_mat, "shader_parameter/intensity", 0.0, 0.25)

func _spawn_floating_text(text: String, color: Color) -> void:
	if floating_text_scene == null or player == null:
		return
	var ftxt = floating_text_scene.instantiate()
	ftxt.position = player.global_position + Vector2(20 + randf_range(-10, 10), -30)
	add_child(ftxt)
	ftxt.show_text(text, color)

# Dificultad dinámica
func _on_DifficultyTimer_timeout() -> void:
	difficulty_stage += 1
	_show_difficulty_message("¡Más rápido!")
	FallingItem.global_speed_multiplier = pow(speed_multiplier, difficulty_stage)
	$SpawnTimer.wait_time *= spawn_multiplier

func _show_difficulty_message(text: String) -> void:
	difficulty_label.text = text
	difficulty_label.visible = true
	difficulty_label.modulate.a = 0.0
	difficulty_label.scale = Vector2(1.4, 1.4)

	var t := create_tween()
	t.tween_property(difficulty_label, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(difficulty_label, "scale", Vector2.ONE, 0.2)
	t.tween_interval(1.0)
	t.tween_property(difficulty_label, "modulate:a", 0.0, 0.4)
	await t.finished
	difficulty_label.visible = false

# Pausa
func pause_game():
	print("Pausando juego...")
	is_paused = true

	$SpawnTimer.paused = true
	if has_node("DifficultyTimer"):
		$DifficultyTimer.paused = true

	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		var player_anim := player.get_node_or_null("AnimatedSprite2D")
		if player_anim:
			player_anim.speed_scale = 0.0
		if player.has_method("set_velocity"):
			player.set_velocity(Vector2.ZERO)

	pause_all_particles(true)
	pause_all_falling_items(true)

	panel.visible = true
	title.text = "Pausa"
	score_lbl.text = "Puntos: %d" % score
	back_btn.visible = true
	backButton.visible = true
	touch_left.visible = false
	touch_right.visible = false
	print("Juego pausado")

func resume_game():
	print("Reanudando juego...")
	is_paused = false

	$SpawnTimer.paused = false
	if has_node("DifficultyTimer"):
		$DifficultyTimer.paused = false

	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		var player_anim := player.get_node_or_null("AnimatedSprite2D")
		if player_anim:
			player_anim.speed_scale = 1.0

	pause_all_particles(false)
	$pescao1der.speed_scale = 0.4
	$pescao2der.speed_scale = 0.4
	$pescao1izq.speed_scale = 0.4

	pause_all_falling_items(false)

	panel.visible = false
	touch_left.visible = true
	touch_right.visible = true
	print("Juego reanudado")

# Auxiliares de pausa
func pause_all_particles(pause: bool):
	var particles = [pescao1der, pescao1izq, pescao2der, bubbles]
	for particle in particles:
		if particle and is_instance_valid(particle):
			if pause:
				particle.emitting = false
				particle.speed_scale = 0.0
			else:
				particle.speed_scale = 1.0
				particle.emitting = true

	for node in get_children():
		if node is CPUParticles2D:
			if pause:
				node.emitting = false
				node.speed_scale = 0.0
			else:
				node.speed_scale = 1.0
				node.emitting = true

func pause_all_falling_items(pause: bool):
	for node in get_children():
		var is_falling_item = "FallingItem" in node.name or (node.has_method("get_class") and node.get_class() == "FallingItem")
		
		if node is Area2D or node.has_method("_physics_process") or is_falling_item:
			if pause:
				node.process_mode = Node.PROCESS_MODE_DISABLED
				var anim := node.get_node_or_null("AnimatedSprite2D")
				if anim:
					anim.speed_scale = 0.0
			else:
				node.process_mode = Node.PROCESS_MODE_INHERIT
				var anim := node.get_node_or_null("AnimatedSprite2D")
				if anim:
					anim.speed_scale = 1.0

# Controles touch
func _on_touch_input(event: InputEvent, dir: float) -> void:
	if player == null:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			player.touch_dir = dir
		else:
			player.touch_dir = 0.0
