extends Area2D
class_name Worm

# Señales
signal request_catch(worm: Node)
signal reached_bucket(worm: Node)
signal escaped(worm: Node)

# Configuración
@export var is_bad := false
const ESCAPE_SPEED := 120.0

# Nodos
@onready var body: AnimatedSprite2D = $Body
@onready var lifetime_timer: Timer = $LifetimeTimer

# Estado
var state := "GROUND"
var attach_target: Node2D
var is_attached := false
var game: Node = null

# Inicialización
func _ready() -> void:
	input_pickable = true

	if game == null:
		game = get_tree().get_first_node_in_group("worm_game")

	if is_bad:
		body.play("bad_rise")
		body.modulate = Color(1, 0.5, 0.5) # Rojo suave
	else:
		body.play("good_rise")
		body.modulate = Color.WHITE

	lifetime_timer.timeout.connect(hide_and_destroy)
	lifetime_timer.start()

# Entrada de usuario
func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_action = event.is_action_pressed("click")

	if not (is_click or is_action):
		return

	# Bloquear si el juego está en estado de aturdimiento
	if game and "is_stunned" in game and game.is_stunned:
		return

	if state == "GROUND" or state == "ESCAPING":
		lifetime_timer.stop()
		emit_signal("request_catch", self)

# Loop principal
func _process(delta: float) -> void:
	# Seguir a la garra
	if is_attached and is_instance_valid(attach_target):
		global_position = attach_target.global_position
		return

	# Movimiento de escape
	if state == "ESCAPING":
		position.x -= ESCAPE_SPEED * delta
		if position.x < -30.0:
			emit_signal("escaped", self)
			queue_free()

# Tiempo de vida agotado
func hide_and_destroy() -> void:
	if state == "GROUND":
		emit_signal("reached_bucket", self)
		queue_free()

# Lógica de escape
func start_escape(from_pos: Vector2) -> void:
	position = from_pos
	state = "ESCAPING"
	body.play("walking")

# Lógica de captura
func attach_to_claw(claw_tip: Node2D) -> void:
	is_attached = true
	attach_target = claw_tip
	state = "ATTACHED"

	if is_bad:
		body.play("bad_idle")
	else:
		body.play("good_idle")

# Animación al balde
func detach_and_go_to_bucket() -> void:
	is_attached = false
	attach_target = null
	state = "IN_BUCKET"

	var target: Vector2
	var has_target := false
	
	if game and "bucket" in game and is_instance_valid(game.bucket):
		target = game.bucket.global_position
		has_target = true

	if has_target:
		var t := create_tween()
		t.tween_property(self, "global_position", target, 0.25)
		t.tween_callback(func ():
			emit_signal("reached_bucket", self)
			queue_free()
		)
	else:
		emit_signal("reached_bucket", self)
		queue_free()
