extends Area2D
class_name Worm

# --- SEÑALES ---
signal request_catch(worm: Node)
signal reached_bucket(worm: Node)
signal escaped(worm: Node)

# --- PROPIEDADES ---
@export var is_bad := false

var state := "GROUND"
var attach_target: Node2D
var is_attached := false

@onready var main := get_tree().get_root().get_node("Main")
@onready var body: AnimatedSprite2D = $Body
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	if is_bad:
		body.play("bad_rise") 
		body.modulate = Color(1, 0.5, 0.5) 
	else:
		body.play("good_rise")
		body.modulate = Color(1, 1, 1)
	
	lifetime_timer.start()
	lifetime_timer.timeout.connect(hide_and_destroy)

func _input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("click"):
		if main.is_stunned: return
		if state == "GROUND" or state == "ESCAPING":
			lifetime_timer.stop()
			emit_signal("request_catch", self)

func _process(delta):
	if is_attached and is_instance_valid(attach_target):
		global_position = attach_target.global_position
		return

	if state == "ESCAPING":
		position.x -= 120 * delta
		if position.x < -30:
			emit_signal("escaped", self)
			queue_free()

func hide_and_destroy():
	if state == "GROUND":
		emit_signal("reached_bucket", self) 
		queue_free()

# ===========================================================
#  FUNCIÓN start_escape (CORREGIDA)
# ===========================================================
func start_escape(from_pos: Vector2):
	position = from_pos
	state = "ESCAPING"
	
	# LÓGICA CORREGIDA:
	# Como los gusanos que escapan nunca son malos,
	# solo reproducimos la animación "walking".
	body.play("walking")

func attach_to_claw(claw_tip: Node2D):
	is_attached = true
	attach_target = claw_tip
	state = "ATTACHED"
	if is_bad:
		body.play("bad_idle")
	else:
		body.play("good_idle")

func detach_and_go_to_bucket():
	is_attached = false
	attach_target = null
	state = "IN_BUCKET"
	
	var t := create_tween()
	var target = main.bucket.global_position
	t.tween_property(self, "global_position", target, 0.25)
	
	t.tween_callback(func():
		emit_signal("reached_bucket", self)
		queue_free()
	)
