extends Node2D

signal finished_moving

@export var speed := 115.0
@export var type_id := "default"

var direction := Vector2.RIGHT
var target_x := 0.0

# Inicio de movimiento
func start_moving():
	set_process(true)

# Movimiento
func _process(delta):
	position += direction * speed * delta

	if (direction.x > 0 and position.x > target_x + 40) \
	or (direction.x < 0 and position.x < target_x - 40):
		emit_signal("finished_moving")
		queue_free()
