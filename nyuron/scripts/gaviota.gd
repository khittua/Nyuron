extends Node2D

@export var speed := 100.0
var direction := Vector2(1, 0)

# # Configuracion Inicial
func _ready():
	modulate.a = randf_range(0.95, 1.00)
	scale *= randf_range(0.7, 1.2)
	call_deferred("_start_animation")

# Animacion y movimiento
func _start_animation():
	if $AnimatedSprite2D:
		var chance := randf()
		var anim := ""
		if chance < 0.3:
			anim = "picado"
		else:
			anim = "volar"
		$AnimatedSprite2D.play(anim)

		if anim == "picado":
			speed *= 2.0
			rotation_degrees = 20 if direction.x > 0 else -20
			direction.y = 0.25
		else:
			rotation_degrees = 0
			direction.y = 0

	var viewport_size = get_viewport_rect().size
	var target_x = -100.0 if direction.x < 0 else viewport_size.x + 100.0
	var target_y = position.y + (300 * direction.y)

	var distance = Vector2(target_x, target_y).distance_to(position)
	var time = distance / speed

	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(target_x, target_y), time)
	tween.tween_callback(_on_reach_edge)

# Salida de escena
func _on_reach_edge():
	queue_free()
