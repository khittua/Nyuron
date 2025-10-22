extends Node2D
class_name Nyuron

# --- SEÑALES ---
# Se emiten para que main.gd sepa en qué punto de la animación estamos.
signal claw_reached_target(target_pos: Vector2)
signal shot_finished

# --- NODOS ---
@onready var anim: AnimatedSprite2D = $Body
@onready var claw_origin: Marker2D = $Body/ClawOrigin

# Brazo normal para capturas
@onready var claw_left_node: Node2D = $ClawLeft
@onready var claw_line: Line2D = $ClawLeft/Line2D
@onready var claw_tip: AnimatedSprite2D = $ClawLeft/ClawTip

# Brazo rápido para recapturas
@onready var claw_left_recap: Node2D = $ClawLeft_Recapture
@onready var claw_line_recap: Line2D = $ClawLeft_Recapture/Line2D
@onready var claw_tip_recap: AnimatedSprite2D = $ClawLeft_Recapture/ClawTip

# --- ESTADO ---
var is_stunned := false
var is_shooting := false


# ===========================================================
#   DISPARO PRINCIPAL (CORREGIDO)
# ===========================================================
# La firma de la función es ahora más simple. main.gd le pasa el objetivo y si es o no una recaptura.
func shoot_to(target: Vector2, is_recatch := false):
	if is_stunned or is_shooting:
		return

	is_shooting = true
	anim.stop()
	anim.play("grab")

	# 1. Selecciona qué brazo y pinza usar basado en si es una recaptura.
	var arm = claw_left_node
	var line = claw_line
	var tip = claw_tip
	var duration = 0.15 # Duración del viaje de ida o vuelta

	if is_recatch:
		arm = claw_left_recap
		line = claw_line_recap
		tip = claw_tip_recap
		duration *= 0.6 # El brazo de recaptura es más rápido.

	# 2. Prepara el brazo para la animación.
	arm.global_position = claw_origin.global_position
	arm.visible = true
	line.points = [Vector2.ZERO, Vector2.ZERO]
	tip.position = Vector2.ZERO
	tip.rotation = 0
	if tip.sprite_frames.has_animation("open"):
		tip.play("open")

	# 3. Crea la animación (Tween)
	var local_target = arm.to_local(target) # Convierte la coordenada del mundo a una local para el brazo.
	var t := create_tween()

	# IDA: Anima la línea estirándose hacia el objetivo.
	t.tween_property(line, "points", PackedVector2Array([Vector2.ZERO, local_target]), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# PAUSA CORTA: Espera un momento y luego emite la señal de que llegó.
	t.tween_interval(0.05)
	t.tween_callback(func():
		if tip.sprite_frames.has_animation("close"):
			tip.play("close")
		emit_signal("claw_reached_target", target) # AVISA A MAIN.GD: "¡Llegué!"
	)

	# VUELTA: Anima la línea retrayéndose a su origen.
	t.tween_property(line, "points", PackedVector2Array([Vector2.ZERO, Vector2.ZERO]), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# FINAL: Cuando termina, resetea el estado y avisa que la animación acabó.
	t.tween_callback(func():
		arm.visible = false
		is_shooting = false
		anim.play("idle")
		emit_signal("shot_finished") # AVISA A MAIN.GD: "¡Terminé!"
	)


# ===========================================================
#   ATURDIMIENTO
# ===========================================================
func stun(seconds := 2.0):
	is_stunned = true
	modulate = Color(1, 0.4, 0.4) # Tinte rojo para feedback visual.
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_callback(func():
		is_stunned = false
		modulate = Color(1, 1, 1) # Vuelve al color normal.
	)


# ===========================================================
#   ACTUALIZAR POSICIÓN VISUAL DEL BRAZO
# ===========================================================
func _process(_delta):
	# Asegura que los brazos siempre partan del origen correcto.
	if claw_left_node.visible: claw_left_node.global_position = claw_origin.global_position
	if claw_left_recap.visible: claw_left_recap.global_position = claw_origin.global_position
	
	# Actualiza la posición y rotación de las puntas de las pinzas.
	_update_tip(claw_line, claw_tip)
	_update_tip(claw_line_recap, claw_tip_recap)


func _update_tip(line: Line2D, tip: AnimatedSprite2D):
	if not line or not tip: return
	if line.points.size() >= 2:
		var global_tip = line.to_global(line.points[1])
		tip.global_position = global_tip
		var dir = line.points[1] - line.points[0]
		tip.rotation = dir.angle() + deg_to_rad(90)
		tip.flip_h = dir.x < 0
