extends CharacterBody2D

@export var max_speed: float = 200.0
@export var accel: float = 2600.0    # qué tan rápido llega a la velocidad
@export var decel: float = 3600.0    # qué tan rápido frena
var screen_size: Vector2

const ANIM_IDLE  := "idle"
const ANIM_LEFT  := "left"
const ANIM_RIGHT := "right"

@onready var crab_sprite: AnimatedSprite2D = $AnimatedSprite2D
var base_scale := Vector2.ONE

func _ready():
	base_scale = crab_sprite.scale
	screen_size = get_viewport_rect().size
	# Colócalo abajo, visible
	global_position = Vector2(screen_size.x * 0.5, screen_size.y - 50.0)
	z_index = 10
	add_to_group("player")  # para que los ítems te detecten
	_play(ANIM_IDLE)

func _physics_process(delta):
	var dir := 0.0
	if Input.is_action_pressed("ui_left"):  dir -= 1.0
	if Input.is_action_pressed("ui_right"): dir += 1.0

	var target = dir * max_speed
	var rate   = accel if dir != 0.0 else decel
	velocity.x = move_toward(velocity.x, target, rate * delta)
	velocity.y = 0.0
	move_and_slide()

	global_position.x = clamp(global_position.x, 40.0, screen_size.x - 40.0)
	_update_animation(dir)

func _update_animation(dir: float) -> void:
	var spd: float = absf(velocity.x) / max_speed
	crab_sprite.speed_scale = lerp(1.0, 1.6, spd)  # 1.0–1.6x

	if abs(velocity.x) < 5.0:
		_play(ANIM_IDLE)
	elif dir < 0.1:
		_play(ANIM_LEFT)
	else:
		_play(ANIM_RIGHT)

func _play(name: String) -> void:
	if crab_sprite.animation != name or !crab_sprite.is_playing():
		crab_sprite.play(name)

func play_catch_pop():
	# Escala base -> 1.1x -> base (animación pop)
	var t := create_tween()
	t.tween_property(crab_sprite, "scale", base_scale * 1.1, 0.12)\
	 .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(crab_sprite, "scale", base_scale, 0.10)\
	 .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	
func play_damage_flash():
	# Tinte rojo MUY corto y vuelve a normal
	var t := create_tween()
	t.tween_property(crab_sprite, "modulate", Color(1.0, 0.3, 0.3), 0.07)
	t.tween_property(crab_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	
func play_hide_animation():
	# Desactiva movimiento
	set_physics_process(false)
	
	if crab_sprite.animation != "hide":
		crab_sprite.play("hide")

	# Esperar a que termine y quedarse en último frame
	await crab_sprite.animation_finished
	crab_sprite.frame = crab_sprite.sprite_frames.get_frame_count("hide") - 1
