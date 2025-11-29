extends CharacterBody2D

@export var lanes := [90.0, 150.0, 210.0]
@export var move_speed := 15.0
@onready var anim := $AnimatedSprite2D

var current_lane := 1
var touch_start_pos := Vector2.ZERO
var swipe_threshold := 40.0
var swipe_cooldown := 0.15
var can_swipe := true

# Mapeo de nombres de tienda a sufijos de archivo
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

func _ready():
	position.y = lanes[current_lane]
	update_skin()

# Sistema de vestidor
func update_skin():
	# Obtener datos guardados
	var id_cuerpo = ScoreManager.get_equipped_item("caparazon")
	var id_accesorio = ScoreManager.get_equipped_item("accesorio")
	
	# Obtener sufijos
	var color_suffix = color_codes.get(id_cuerpo, "")
	var acc_suffix = accessory_codes.get(id_accesorio, "")
	
	# Construir ruta
	var folder_path = "res://Accesorios/turlerun/"
	var base_filename = "pj_run"
	var final_path = folder_path + base_filename + color_suffix + acc_suffix + ".png"
	
	# Cargar textura
	if ResourceLoader.exists(final_path):
		var new_texture = load(final_path)
		_apply_texture_to_anim(new_texture)
		print("Skin aplicada: ", final_path)
	else:
		print("Error: No existe la imagen ", final_path)

func _apply_texture_to_anim(new_texture: Texture2D):
	var frames = anim.sprite_frames
	var lista_animaciones = frames.get_animation_names()
	var anim_name = "default"
	
	# Validar animación
	if not frames.has_animation(anim_name):
		if lista_animaciones.size() > 0:
			anim_name = lista_animaciones[0]
	
	if frames.has_animation(anim_name):
		var frame_count = frames.get_frame_count(anim_name)
		
		for i in range(frame_count):
			var frame_texture = frames.get_frame_texture(anim_name, i)
			
			# Reemplazo de AtlasTexture (requiere spritesheet)
			if frame_texture is AtlasTexture:
				frame_texture.atlas = new_texture
			else:
				print("Frame ", i, " no es AtlasTexture. No se pudo reemplazar.")
	else:
		print("Error: No hay animaciones válidas.")
		
	# Refrescar
	anim.stop()
	anim.play(anim_name)

func _process(delta):
	# Validar estado del juego
	var main = get_tree().get_first_node_in_group("turtle_game")
	if main:
		if "is_intro" in main and main.is_intro: return
		if "is_paused" in main and main.is_paused: return

	var target_y = lanes[current_lane]
	position.y = lerp(position.y, target_y, move_speed * delta)

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		touch_start_pos = event.position
		can_swipe = true

	if event is InputEventScreenDrag:
		_process_swipe(event.position)

	if event.is_action_pressed("ui_up") and current_lane > 0:
		current_lane -= 1
	elif event.is_action_pressed("ui_down") and current_lane < lanes.size() - 1:
		current_lane += 1

func update_animation_speed(multiplier: float):
	anim.speed_scale = multiplier

func add_bonus():
	var main = get_tree().get_first_node_in_group("turtle_game")
	if main:
		main.add_score_bonus(50)
		main.play_bonus_sound()

func die():
	var main = get_tree().get_first_node_in_group("turtle_game")
	if main:
		main.game_over()
		main.play_hit_sound()

func _process_swipe(current_pos: Vector2):
	if not can_swipe: return

	var delta := current_pos - touch_start_pos

	if abs(delta.y) > swipe_threshold:
		if delta.y < 0 and current_lane > 0:
			current_lane -= 1
		elif delta.y > 0 and current_lane < lanes.size() - 1:
			current_lane += 1

		can_swipe = false
		touch_start_pos = current_pos

		await get_tree().create_timer(swipe_cooldown).timeout
		can_swipe = true
