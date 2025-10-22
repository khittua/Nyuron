extends CharacterBody2D

@export var lanes := [90.0, 150.0, 210.0] # posiciones Y de los carriles
@export var move_speed := 15.0

@onready var anim := $AnimatedSprite2D

var current_lane := 1 # empieza en el carril del medio

func _ready():
	position.y = lanes[current_lane]

func _process(delta):
	# Movimiento suave hacia la posición del carril actual
	var target_y = lanes[current_lane]
	position.y = lerp(position.y, target_y, move_speed * delta)

func _input(event):
	if event.is_action_pressed("ui_up") and current_lane > 0:
		current_lane -= 1
	elif event.is_action_pressed("ui_down") and current_lane < lanes.size() - 1:
		current_lane += 1

# --- Ajustar velocidad de animación según el multiplicador global ---
func update_animation_speed(multiplier: float):
	anim.speed_scale = multiplier

# --- Sumar puntos al agarrar bonus ---
func add_bonus():
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.add_score_bonus(50)
		main.show_floating_text(global_position + Vector2(0, -10), "+50")
		main.play_bonus_sound()

# --- Perder al tocar una lata ---
func die():
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.game_over()
		main.play_hit_sound()
