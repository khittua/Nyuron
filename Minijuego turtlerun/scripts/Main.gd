extends Node2D

@onready var parallax := $ParallaxBackground
@onready var spawn_timer := $SpawnTimer
@onready var obstacle_container := $ObstacleContainer
@onready var bonus_container := $BonusContainer

@onready var score_label := $UI/Label

@onready var panel: Control = $UI/GameOverPanel
@onready var title_lbl: Label = $UI/GameOverPanel/Title
@onready var score_lbl: Label = $UI/GameOverPanel/Score
@onready var retry_btn: TextureButton = $UI/GameOverPanel/Buttons/RetryButton
@onready var back_btn: TextureButton = $UI/GameOverPanel/Buttons/BackButton


@onready var sfx_bonus := $AudioBonus
@onready var sfx_hit := $AudioHit

@export var scroll_speed := 200.0
@export var floating_text_scene: PackedScene
@export var obstacle_scene: PackedScene
@export var bonus_scene: PackedScene
@export var lanes := [100.0, 160.0, 220.0]

var score: float = 0.0
var last_lane := -1
var elapsed_time := 0.0                 # tiempo total acumulado
var speed_increase_interval := 6.0     # cada 8 segundos
var speed_multiplier := 1.0             # factor multiplicador

func _ready():
	
	panel.visible = false
	retry_btn.pressed.connect(_on_retry_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	randomize()

	# Agregar este nodo al grupo main para que los obstaculos puedan leer el multiplicador
	add_to_group("main")

	#Configurar y startear el timer
	spawn_timer.wait_time = randf_range(1.0, 2.0)
	spawn_timer.timeout.connect(_on_SpawnTimer_timeout)
	spawn_timer.start()

func _process(delta):
	#Fondo infinito y puntaje
	parallax.scroll_offset.x -= scroll_speed * speed_multiplier * delta
	score += delta * 10 * speed_multiplier

	score_label.text = "Puntaje: " + str(int(score))

	#Aumentar la velocidad cada 10 segundos
	elapsed_time += delta
	if elapsed_time >= speed_increase_interval:
		elapsed_time = 0
		speed_multiplier *= 1.1 # aumenta 5 %
		print("Velocidad aumentada a ", snapped(speed_multiplier, 0.01), "x")
	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.update_animation_speed(speed_multiplier)

func _on_SpawnTimer_timeout():
	spawn_timer.wait_time = randf_range(0.5, 1.5)
	spawn_timer.start()

	var lanes_available = lanes.duplicate()
	if last_lane != -1 and lanes_available.has(last_lane):
		lanes_available.erase(last_lane)
	var lane_y = lanes_available.pick_random()
	last_lane = lane_y

	if randf() < 0.9:
		spawn_obstacle(lane_y)
	else:
		spawn_bonus(lane_y)

func spawn_obstacle(y_pos):
	if obstacle_scene == null:
		push_error("⚠️ obstacle_scene no asignado")
		return
	var obstacle = obstacle_scene.instantiate()
	obstacle.position = Vector2(get_viewport_rect().size.x + 50, y_pos)
	obstacle_container.add_child(obstacle)

func spawn_bonus(y_pos):
	if bonus_scene == null:
		push_error("⚠️ bonus_scene no asignado")
		return
	var bonus = bonus_scene.instantiate()
	bonus.position = Vector2(get_viewport_rect().size.x + 50, y_pos)
	bonus_container.add_child(bonus)


# --- Sumar puntos extra por bonus ---
func add_score_bonus(amount: int):
	score += amount

# --- Perder ---
func game_over():
	print("💥 ¡Perdiste! Puntaje final:", int(score))

	# Detener generación de nuevos objetos
	spawn_timer.stop()

	# Detener el fondo (parallax)
	scroll_speed = 0

	# Detener todos los obstáculos y bonus activos
	for node in obstacle_container.get_children():
		node.set_process(false)
	for node in bonus_container.get_children():
		node.set_process(false)

	# Detener el puntaje (desactivar su actualización)
	set_process(false)  # esto pausa _process(delta) del Main
	

	# Detener el movimiento y animación del jugador
	var turtle = get_node_or_null("Turtle")
	if turtle:
		turtle.set_process(false)
		var anim := turtle.get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.speed_scale = 0.0  # pausa la animación

	# Reproducir sonido de impacto
	play_hit_sound()

	#  Pequeña espera para que se escuche el sonido (sin pausar el árbol aún)
	await get_tree().create_timer(0.8).timeout
	$UI/Label.visible = false
	_show_game_over()
	
	get_tree().paused = true

func _show_game_over():
	title_lbl.text = "¡Fin del Juego!"
	score_lbl.text = "Puntos: %d" % int(score)
	panel.visible = true

func show_floating_text(pos: Vector2, text := "+50", color := Color(0.645, 0.645, 0.0, 1.0)):
	if floating_text_scene == null:
		push_error("floating_text_scene no asignado")
		return
	var ft = floating_text_scene.instantiate()
	ft.position = pos
	add_child(ft)
	ft.show_text(text, color)


func play_bonus_sound():
	if sfx_bonus:
		sfx_bonus.play()

func play_hit_sound():
	if sfx_hit:
		sfx_hit.play()
		
func _on_retry_pressed():
	get_tree().paused = false  # quitar pausa global antes de recargar
	get_tree().reload_current_scene()

func _on_back_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene() #por ahora se reinicia hasta tener escena de menu
	#get_tree().change_scene_to_file("res://scenes/Menu.tscn") --para despuéss
