extends Node2D

signal finished_moving

@export var speed := 60.0
var direction := Vector2.RIGHT
var target_x := 0.0
@export var type_id := "default"

func start_moving():
	set_process(true)

func _process(delta):
	position += direction * speed * delta
	
	# 🔹 Cuando sale fuera de la pantalla (según dirección)
	if (direction.x > 0 and position.x > target_x + 40) or (direction.x < 0 and position.x < target_x - 40):
		emit_signal("finished_moving")
		queue_free()
