extends CharacterBody2D

@export var lanes := [90.0, 150.0, 210.0] 
@export var move_speed := 15.0
@onready var anim := $AnimatedSprite2D

var current_lane := 1
var touch_start_pos := Vector2.ZERO
var swipe_threshold := 40.0
var swipe_cooldown := 0.15
var can_swipe := true

# --- DICCIONARIOS DE SKIN (NUEVO) ---
# Mapean el Nombre de la Tienda -> Parte del nombre del Archivo
var color_codes = {
	"default": "",
	"caparazon": "",        # Caso fallback
	"Caparazón Azul": "_blue",
	"Caparazón Verde": "_green",
	"Caparazón Purpura": "_purple",
	"Caparazón Gris": "_gray"
}

var accessory_codes = {
	"none": "",
	"ninguno": "",
	"Corona": "_corona",
	"Gafas": "_lentes",    # Tienda dice Gafas, archivo dice lentes
	"Gorro": "_gorro",
	"Cadena": "_cadena"
}

# Configuracion inicial
func _ready():
	position.y = lanes[current_lane]
	# Llamamos a la función que viste al personaje al iniciar
	update_skin()

# --- FUNCION DE VESTIDOR (NUEVO) ---
func update_skin():
	# 1. Obtener datos del ScoreManager
	var id_cuerpo = ScoreManager.get_equipped_item("caparazon")
	var id_accesorio = ScoreManager.get_equipped_item("accesorio")
	
	# 2. Traducir a sufijos de archivo
	var color_suffix = color_codes.get(id_cuerpo, "")
	var acc_suffix = accessory_codes.get(id_accesorio, "")
	
	# 3. Construir la ruta
	# IMPORTANTE: Verifica que esta ruta sea exacta a donde subiste la imagen dea3e5.png
	var folder_path = "res://Accesorios/turlerun/" 
	var base_filename = "pj_run"
	
	# Ejemplo resultado: "res://.../pj_run_blue_lentes.png"
	var final_path = folder_path + base_filename + color_suffix + acc_suffix + ".png"
	
	# 4. Cargar y Aplicar
	if ResourceLoader.exists(final_path):
		var new_texture = load(final_path)
		_apply_texture_to_anim(new_texture)
		print("Skin aplicada en Turtle: ", final_path)
	else:
		print("ERROR: No se encontró la imagen de skin: ", final_path)

func _apply_texture_to_anim(new_texture: Texture2D):
	var frames = anim.sprite_frames
	
	# 1. Verificar qué animaciones existen
	var lista_animaciones = frames.get_animation_names()
	print("Animaciones encontradas: ", lista_animaciones)
	
	# CAMBIA ESTO si tu animación se llama distinto (ej: "run", "caminar")
	var anim_name = "default" 
	
	if not frames.has_animation(anim_name):
		# Si no es "default", intentamos usar la primera que encuentre
		if lista_animaciones.size() > 0:
			anim_name = lista_animaciones[0]
			print("AVISO: Usando animación '", anim_name, "' en lugar de default")
	
	if frames.has_animation(anim_name):
		var frame_count = frames.get_frame_count(anim_name)
		print("Procesando ", frame_count, " frames para: ", anim_name)
		
		for i in range(frame_count):
			var frame_texture = frames.get_frame_texture(anim_name, i)
			
			# Debug: Ver qué tipo de textura es
			if frame_texture is AtlasTexture:
				frame_texture.atlas = new_texture
				print("Frame ", i, ": Textura Atlas actualizada OK.")
			else:
				print("Frame ", i, ": NO es AtlasTexture. Es ", frame_texture.get_class())
				# INTENTO DE ARREGLO DE EMERGENCIA
				# Si no es Atlas, intentamos forzarlo (esto funciona si usaste imagenes sueltas)
				# frames.set_frame(anim_name, i, new_texture) <--- Esto no funcionaría con spritesheets
				
	else:
		print("ERROR FATAL: No se encontró ninguna animación válida.")
		
	# Forzar refresco visual
	anim.stop()
	anim.play(anim_name)

# Movimiento principal
func _process(delta):
	var main = get_tree().get_first_node_in_group("turtle_game") # Asegurate que el grupo sea correcto
	if main and ("is_intro" in main and main.is_intro or "is_paused" in main and main.is_paused):
		return

	var target_y = lanes[current_lane]
	position.y = lerp(position.y, target_y, move_speed * delta)

# Input (touch + clicks de PC)
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

# Ajuste de animacion por velocidad global
func update_animation_speed(multiplier: float):
	anim.speed_scale = multiplier

# Acciones: bonus y muerte
func add_bonus():
	var main = get_tree().get_first_node_in_group("main") # O "turtle_game" segun tu grupo
	if main:
		main.add_score_bonus(50)
		# main.show_floating_text(global_position + Vector2(0, -10), "+50") # Descomenta si tienes esta func
		main.play_bonus_sound()

func die():
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.game_over()
		main.play_hit_sound()

# Swipe touch
func _process_swipe(current_pos: Vector2):
	if not can_swipe:
		return

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
