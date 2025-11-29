extends CharacterBody2D

@export var max_speed: float = 200.0
@export var accel: float = 2600.0
@export var decel: float = 3600.0

var screen_size: Vector2 = Vector2.ZERO

const ANIM_IDLE: String  = "idle"
const ANIM_LEFT: String  = "left"
const ANIM_RIGHT: String = "right"
var touch_dir: float = 0.0
@onready var crab_sprite: AnimatedSprite2D = $AnimatedSprite2D
var base_scale: Vector2 = Vector2.ONE

# --- DICCIONARIOS DE SKIN ---
var color_codes = {
	"default": "",
	"caparazon": "",
	"Caparazón Azul": "_blue",
	"Caparazón Verde": "_green",
	"Caparazón Purpura": "_purple",
	"Caparazón Gris": "_gray"
}

var accessory_codes = {
	"none": "",
	"ninguno": "",
	"Corona": "_corona",
	"Gafas": "_lentes",
	"Gorro": "_gorro",
	"Cadena": "_cadena"
}

func _ready() -> void:
	# Orden de dibujo alto
	z_index = 100
	z_as_relative = false

	show()
	modulate.a = 1.0

	base_scale = crab_sprite.scale

	var vp := get_viewport()
	if vp and vp.has_signal("size_changed"):
		vp.size_changed.connect(_on_viewport_size_changed)

	await get_tree().process_frame
	_reposition_bottom_center()

	add_to_group("player")
	
	# --- CARGAR SKIN ANTES DE EMPEZAR ---
	update_skin()
	
	_play(ANIM_IDLE)

# --- FUNCIÓN DE SKIN MULTI-ANIMACIÓN ---
func update_skin():
	# 1. Obtener datos
	var id_cuerpo = ScoreManager.get_equipped_item("caparazon")
	var id_accesorio = ScoreManager.get_equipped_item("accesorio")
	
	var suffix = color_codes.get(id_cuerpo, "") + accessory_codes.get(id_accesorio, "")
	
	# --- CONFIGURACIÓN DE RUTAS (AJUSTA ESTO SI ES NECESARIO) ---
	# Carpeta donde está spr_rest (Global)
	var folder_global = "res://Accesorios/global/"
	# Carpeta donde están spr_left, spr_right y cangrejo_muelto2 (Minijuego)
	# IMPORTANTE: Reemplaza "res://ruta_a_food_catch/" con la ruta real de tus sprites de este juego
	var folder_game = "res://Accesorios/food_catch/" 
	
	# 2. Construir rutas para cada animación
	var file_idle  = folder_global + "spr_rest" + suffix + ".png"
	var file_left  = folder_game + "spr_walk_left" + suffix + ".png"
	var file_right = folder_game + "spr_walk_right" + suffix + ".png"
	# Nota: Si el archivo se llama "cangrejomuelto2_minijuego2...", ajusta el nombre base aquí abajo:
	var file_hide  = folder_game + "cangrejomuelto2" + "_minijuego2" + suffix + ".png" 

	# 3. Cargar y Aplicar texturas
	_try_apply_texture(ANIM_IDLE, file_idle)
	_try_apply_texture(ANIM_LEFT, file_left)
	_try_apply_texture(ANIM_RIGHT, file_right)
	_try_apply_texture("hide", file_hide)

func _try_apply_texture(anim_name: String, path: String):
	if ResourceLoader.exists(path):
		var tex = load(path)
		_apply_texture_to_anim_frames(anim_name, tex)
		print("Skin cargada para ", anim_name, ": ", path)
	else:
		print("ERROR: No existe imagen para ", anim_name, " en: ", path)

func _apply_texture_to_anim_frames(anim_name: String, new_texture: Texture2D):
	var frames = crab_sprite.sprite_frames
	if frames.has_animation(anim_name):
		var count = frames.get_frame_count(anim_name)
		for i in range(count):
			var frame_tex = frames.get_frame_texture(anim_name, i)
			if frame_tex is AtlasTexture:
				frame_tex.atlas = new_texture
# --- FIN LÓGICA SKIN ---

func _on_viewport_size_changed() -> void:
	_reposition_bottom_center()

func _reposition_bottom_center() -> void:
	screen_size = get_viewport_rect().size
	global_position = Vector2(screen_size.x * 0.5, max(56.0, screen_size.y - 56.0))

func _physics_process(delta: float) -> void:
	var dir: float = 0.0

	if Input.is_action_pressed("ui_left"):
		dir -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir += 1.0

	dir += touch_dir

	var target = dir * max_speed
	var rate = accel if dir != 0.0 else decel

	velocity.x = move_toward(velocity.x, target, rate * delta)
	velocity.y = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, screen_size.x - 40.0)
	_update_animation(dir)

func _update_animation(dir: float) -> void:
	var spd: float = absf(velocity.x) / max_speed
	crab_sprite.speed_scale = lerp(1.0, 1.6, spd)

	if absf(velocity.x) < 5.0:
		_play(ANIM_IDLE)
	elif dir < 0.0:
		_play(ANIM_LEFT)
	elif dir > 0.0:
		_play(ANIM_RIGHT)

func _play(name: String) -> void:
	if crab_sprite.animation != name or not crab_sprite.is_playing():
		crab_sprite.play(name)

func play_catch_pop() -> void:
	var t := create_tween()
	t.tween_property(crab_sprite, "scale", base_scale * 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(crab_sprite, "scale", base_scale, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func play_damage_flash() -> void:
	var t := create_tween()
	t.tween_property(crab_sprite, "modulate", Color(1.0, 0.3, 0.3), 0.07)
	t.tween_property(crab_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.15)

func play_hide_animation() -> void:
	set_physics_process(false)
	if crab_sprite.animation != "hide":
		crab_sprite.play("hide")
	await crab_sprite.animation_finished
	crab_sprite.frame = crab_sprite.sprite_frames.get_frame_count("hide") - 1
