extends Area2D
class_name Worm
signal request_catch(worm: Node)
signal reached_bucket(worm: Node)
signal escaped(worm: Node)
@export var is_bad := false
var state := "GROUND"
var attach_target: Node2D
var is_attached := false

# Referencia al juego
var game: Node = null

@onready var body: AnimatedSprite2D = $Body
@onready var lifetime_timer: Timer = $LifetimeTimer

# Inicialización
func _ready() -> void:
	input_pickable = true

	if game == null:
		game = get_tree().get_first_node_in_group("worm_game")

	if is_bad:
		body.play("bad_rise")
		body.modulate = Color.from_rgba8(255, 128, 128, 255)
	else:
		body.play("good_rise")
		body.modulate = Color(1, 1, 1)

	lifetime_timer.start()
	lifetime_timer.timeout.connect(hide_and_destroy)

# Input
func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	var pressed_click: bool = (
		(event is InputEventMouseButton
		 and event.pressed
		 and event.button_index == MOUSE_BUTTON_LEFT)
		or (event.is_action_pressed("click"))
	)

	if not pressed_click:
		return

	if game != null and "is_stunned" in game and game.is_stunned:
		return

	if state == "GROUND" or state == "ESCAPING":
		lifetime_timer.stop()
		emit_signal("request_catch", self)

# Actualización
func _process(delta: float) -> void:
	if is_attached and is_instance_valid(attach_target):
		global_position = attach_target.global_position
		return

	if state == "ESCAPING":
		position.x -= 120.0 * delta
		if position.x < -30.0:
			emit_signal("escaped", self)
			queue_free()

# Vida y destrucción
func hide_and_destroy() -> void:
	if state == "GROUND":
		emit_signal("reached_bucket", self)
		queue_free()

# Escape
func start_escape(from_pos: Vector2) -> void:
	position = from_pos
	state = "ESCAPING"
	body.play("walking")

# Unión a la garra
func attach_to_claw(claw_tip: Node2D) -> void:
	is_attached = true
	attach_target = claw_tip
	state = "ATTACHED"

	if is_bad:
		body.play("bad_idle")
	else:
		body.play("good_idle")

# Ir al balde
func detach_and_go_to_bucket() -> void:
	is_attached = false
	attach_target = null
	state = "IN_BUCKET"

	var t := create_tween()

	var target: Vector2
	var has_target := false
	if game != null and "bucket" in game and is_instance_valid(game.bucket):
		target = game.bucket.global_position
		has_target = true

	if has_target:
		t.tween_property(self, "global_position", target, 0.25)
		t.tween_callback(func ():
			emit_signal("reached_bucket", self)
			queue_free()
		)
	else:
		emit_signal("reached_bucket", self)
		queue_free()
