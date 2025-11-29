extends Node2D
class_name Nyuron

# Señales
signal claw_reached_target(target_pos: Vector2)
signal shot_finished

@onready var anim: AnimatedSprite2D = $Body
@onready var claw_origin: Marker2D = $Body/ClawOrigin

@onready var claw_left_node: Node2D = $ClawLeft
@onready var claw_line: Line2D = $ClawLeft/Line2D
@onready var claw_tip: AnimatedSprite2D = $ClawLeft/ClawTip

@onready var claw_left_recap: Node2D = $ClawLeft_Recapture
@onready var claw_line_recap: Line2D = $ClawLeft_Recapture/Line2D
@onready var claw_tip_recap: AnimatedSprite2D = $ClawLeft_Recapture/ClawTip

# Estado
var is_stunned := false
var is_shooting := false

# --- DICCIONARIOS DE SKIN (NUEVO) ---
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
	# Aplicar la skin al iniciar el juego
	update_skin()

# --- FUNCIONES DE SKIN (NUEVO) ---
func update_skin():
	var id_cuerpo = ScoreManager.get_equipped_item("caparazon")
	var id_accesorio = ScoreManager.get_equipped_item("accesorio")
	
	var color_suffix = color_codes.get(id_cuerpo, "")
	var acc_suffix = accessory_codes.get(id_accesorio, "")
	
	var folder_path = "res://Accesorios/global/"
	
	# 1. Cargamos la textura para IDLE (spr_rest -> CON brazos)
	var path_idle = folder_path + "spr_rest" + color_suffix + acc_suffix + ".png"
	var tex_idle = null
	
	if ResourceLoader.exists(path_idle):
		tex_idle = load(path_idle)
	else:
		print("Error: No existe textura Idle ", path_idle)

	# 2. Cargamos la textura para GRAB (spr_no_claw -> SIN brazos)
	var path_grab = folder_path + "spr_no_claw" + color_suffix + acc_suffix + ".png"
	var tex_grab = null
	
	if ResourceLoader.exists(path_grab):
		tex_grab = load(path_grab)
	else:
		print("Error: No existe textura Grab ", path_grab)
	
	# 3. Aplicamos ambas
	if tex_idle and tex_grab:
		_apply_dual_textures(tex_idle, tex_grab)

func _apply_dual_textures(tex_idle: Texture2D, tex_grab: Texture2D):
	var frames = anim.sprite_frames
	var animation_names = frames.get_animation_names()
	
	for anim_name in animation_names:
		var frame_count = frames.get_frame_count(anim_name)
		
		# Decidimos qué textura usar según el nombre de la animación
		var texture_to_use = tex_grab # Por defecto usamos la sin brazos
		
		if anim_name == "idle":
			texture_to_use = tex_idle # Para idle usamos la con brazos (rest)
		
		# Aplicamos la textura a todos los frames de esa animación
		for i in range(frame_count):
			var frame_texture = frames.get_frame_texture(anim_name, i)
			
			if frame_texture is AtlasTexture:
				frame_texture.atlas = texture_to_use
				
	# Refrescar visualmente
	anim.stop()
	anim.play("idle")
	print("Skins aplicadas: Idle(Rest) y Grab(NoClaw)")

# --- FIN NUEVO CÓDIGO ---

# Disparo
func shoot_to(target: Vector2, is_recatch := false):
	if is_stunned or is_shooting:
		return

	is_shooting = true
	anim.stop()
	anim.play("grab")

	var arm = claw_left_node
	var line = claw_line
	var tip = claw_tip
	var duration = 0.15

	if is_recatch:
		arm = claw_left_recap
		line = claw_line_recap
		tip = claw_tip_recap
		duration *= 0.6

	arm.global_position = claw_origin.global_position
	arm.visible = true
	line.points = [Vector2.ZERO, Vector2.ZERO]
	tip.position = Vector2.ZERO
	tip.rotation = 0
	if tip.sprite_frames.has_animation("open"):
		tip.play("open")

	var local_target = arm.to_local(target)
	var t := create_tween()

	t.tween_property(
		line,
		"points",
		PackedVector2Array([Vector2.ZERO, local_target]),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.tween_interval(0.05)
	t.tween_callback(func():
		if tip.sprite_frames.has_animation("close"):
			tip.play("close")
		emit_signal("claw_reached_target", target)
	)

	t.tween_property(
		line,
		"points",
		PackedVector2Array([Vector2.ZERO, Vector2.ZERO]),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	t.tween_callback(func():
		arm.visible = false
		is_shooting = false
		anim.play("idle")
		emit_signal("shot_finished")
	)


# Aturdimiento
func stun(seconds := 2.0):
	is_stunned = true
	modulate = Color(1, 0.4, 0.4)
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_callback(func():
		is_stunned = false
		modulate = Color(1, 1, 1)
	)


# Actualización de brazo
func _process(_delta):
	if claw_left_node.visible:
		claw_left_node.global_position = claw_origin.global_position
	if claw_left_recap.visible:
		claw_left_recap.global_position = claw_origin.global_position

	_update_tip(claw_line, claw_tip)
	_update_tip(claw_line_recap, claw_tip_recap)


func _update_tip(line: Line2D, tip: AnimatedSprite2D):
	if not line or not tip:
		return
	if line.points.size() >= 2:
		var global_tip = line.to_global(line.points[1])
		tip.global_position = global_tip
		var dir = line.points[1] - line.points[0]
		tip.rotation = dir.angle() + deg_to_rad(90)
		tip.flip_h = dir.x < 0
