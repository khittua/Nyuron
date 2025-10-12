extends Node2D

@onready var player          = $Player
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var lives_label: Label = $CanvasLayer/LivesLabel
@onready var damage_border: ColorRect = $CanvasLayer/DamageBorder
@onready var damage_mat: ShaderMaterial = damage_border.material
@onready var panel: Panel         = $CanvasLayer/GameOverPanel
@onready var title: Label         = $CanvasLayer/GameOverPanel/Title
@onready var score_lbl: Label     = $CanvasLayer/GameOverPanel/Score
@onready var retry_btn: TextureButton    = $CanvasLayer/GameOverPanel/Buttons/RetryButton
@onready var back_btn: TextureButton     = $CanvasLayer/GameOverPanel/Buttons/BackButton
@onready var difficulty_label: Label = $CanvasLayer/DifficultyLabel

#Control de la dificultad y sus multiplicadores
@export var difficulty_interval: float = 30.0  # cada 30 segundos
@export var speed_multiplier: float = 1.2      # los ítems caen 10% más rápido
@export var spawn_multiplier: float = 0.85      # el spawn se acelera 10%
var difficulty_stage: int = 0                  # contador de rondas

@export var food_scene: PackedScene
@export var trash_scene: PackedScene
@export var bonus_scene: PackedScene
@export var floating_text_scene: PackedScene

#Control de la frecuencia y tipo de ítems que aparecen.
@export var bonus_probability: float = 0.05  # 5% chance
@export var spawn_every: float = 0.8
@export var trash_probability: float = 0.35  # 35% basura

#Tween (interpolación animada).
func _flash_label(label: Label, flash_color: Color, in_time := 0.06, out_time := 0.22):
	var base := label.modulate
	var t := create_tween()
	t.tween_property(label, "modulate", flash_color, in_time)
	t.tween_property(label, "modulate", base, out_time)

#Cambia color de las label del hud al recibir daño, o al ganar puntos
func _hud_damage_flash():
	_flash_label(lives_label, Color(1.0, 0.4, 0.4))  
func _hud_pop_flash():
	_flash_label(score_label, Color("60e55aff"))  
	
#Valores iniciales de juego
var score: int = 0
var lives: int = 3
var screen_size: Vector2

func _ready():
	#Carga botones
	retry_btn.pressed.connect(_on_retry_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	#oculta el panel de gameover
	panel.visible = false
	
	# Obtiene tamaño de pantalla (para limitar posiciones aleatorias)
	screen_size = get_viewport_rect().size
	
	$SpawnTimer.wait_time = spawn_every #definido arriba, 0.8
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	$SpawnTimer.start()
	_update_hud() # muestra el hud inicial

	# Coloca el fondo en el centro
	$Background.position = screen_size * 0.5

	# Reinicia dificultad al comenzar partida
	difficulty_stage = 0
	FallingItem.global_speed_multiplier = 1.0

	
func _on_spawn_timer_timeout():
	var scene: PackedScene


	# se elige aleatoriamente qué tipo de ítem aparece
	var roll := randf()
	if roll < bonus_probability:
		scene = bonus_scene
	elif roll < bonus_probability + trash_probability:
		scene = trash_scene
	else:
		scene = food_scene
		
	# se instancia la escena elegida
	var item = scene.instantiate()
	
	# spawnea el item en una posición aleatorea en la parte superior de la pantalla
	var spawn_x = randf_range(40.0, screen_size.x - 40.0)
	item.position = Vector2(spawn_x, -40.0)

	# conectar según tipo
	if item is BonusItem:
		item.connect("resolved_bonus", _on_bonus_resolved)
	else:
		item.connect("resolved", _on_item_resolved)

	add_child(item)

func _on_item_resolved(is_trash: bool):
	if is_trash:
		lives -= 1
		_hud_damage_flash()
		_flash_damage_overlay() 
		if player.has_method("play_damage_flash"):
			player.play_damage_flash()
	else:
		score += 10
		_hud_pop_flash()
		if player.has_method("play_catch_pop"):
			player.play_catch_pop()
		_spawn_floating_text("+10", Color(1, 1, 0.5))
	_update_hud()
	_check_game_over()
	
func _on_bonus_resolved(points: int):
	_hud_pop_flash()
	score += points
	_spawn_floating_text("+%d" % points, Color(0.414, 0.993, 1.0, 1.0)) 

	if player.has_method("play_catch_pop"):
		player.play_catch_pop()
	_update_hud()
	
func _update_hud():
	$CanvasLayer/ScoreLabel.text = "Puntos: %d" % score
	$CanvasLayer/LivesLabel.text = "Vidas: %d" % lives

func _check_game_over():
	if lives <= 0:
		
		# se detiene el spawn de objetos
		$SpawnTimer.stop()

		# se ejecuta la animación de hide
		if player.has_method("play_hide_animation"):
			player.play_hide_animation()
			player.play_damage_flash()
		# se espera 0.8s antes de mostrar el panel de gameover
		await get_tree().create_timer(0.8).timeout

		get_tree().paused = true
		_show_game_over()

func _show_game_over():
	
	$CanvasLayer/GameOverPanel/Title.text = "¡Fin del Juego!"
	$CanvasLayer/GameOverPanel/Score.text = "Puntos: %d" % score
	panel.visible = true
	



func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_back_pressed():
	get_tree().paused = false
	# para cuando tengamos escena de menu:
	# get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	# x ahora funciona como retry
	get_tree().reload_current_scene()
	
func _flash_damage_overlay():
	if damage_mat == null: return
	var tw := create_tween()

	tw.tween_property(damage_mat, "shader_parameter/intensity", 0.5, 0.08).from(0.0)

	tw.tween_property(damage_mat, "shader_parameter/intensity", 0.0, 0.25)




# instancia una escena de floating text sobre el cangrejo
# Luego llama a su función show_text() que lo anima y destruye automáticamente.
func _spawn_floating_text(text: String, color: Color):
	if floating_text_scene == null:
		return
	var ftxt = floating_text_scene.instantiate()
	ftxt.position = player.global_position + Vector2(20 + randf_range(-10, 10), -30)  # leve aleatoriedad
	add_child(ftxt)
	ftxt.show_text(text, color)


func _on_DifficultyTimer_timeout():
	difficulty_stage += 1

	_show_difficulty_message("¡Más rápido!")


	FallingItem.global_speed_multiplier = pow(speed_multiplier, difficulty_stage)

	# Acelerar el spawn
	$SpawnTimer.wait_time *= spawn_multiplier


func _show_difficulty_message(text: String):
	difficulty_label.text = text
	difficulty_label.visible = true
	difficulty_label.modulate.a = 0.0
	difficulty_label.scale = Vector2(1.4, 1.4)

	var t := create_tween()
	t.tween_property(difficulty_label, "modulate:a", 1.0, 0.2)   # aparece
	t.parallel().tween_property(difficulty_label, "scale", Vector2.ONE, 0.2)
	t.tween_interval(1.0)                                       # espera visible
	t.tween_property(difficulty_label, "modulate:a", 0.0, 0.4)   # desaparece
	await t.finished
	difficulty_label.visible = false
