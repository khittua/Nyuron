extends Area2D

@export var base_speed := 200.0

# Movimiento
func _process(delta):
	var main = get_tree().get_first_node_in_group("main")
	if main:
		position.x -= base_speed * main.speed_multiplier * delta

	if position.x < -50:
		queue_free()

# Colisión
func _on_body_entered(body):
	if body.name == "Turtle":
		var main = get_tree().get_first_node_in_group("main")
		if main:
			main.game_over()
		queue_free()
