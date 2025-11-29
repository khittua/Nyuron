extends Area2D

@export var color_name: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

signal crab_pressed(color: String)

func _ready() -> void:
	# Animación base
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	# MUY IMPORTANTE: conectar el input del Area2D
	connect("input_event", Callable(self, "_on_input_event"))

	# (opcional) asegúrate de que tenga colisión y que sea cliqueable
	input_pickable = true  # (CollisionObject2D) — debe estar en true
	monitoring = true


func _on_input_event(viewport, event, shape_idx) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		emit_signal("crab_pressed", color_name)
		print("Crab tocado:", color_name)


func _flash() -> void:
	var t = create_tween()
	t.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	t.tween_property(sprite, "scale", Vector2(1, 1), 0.1)

	sprite.modulate = Color(1.3, 1.3, 1.3)

	# sonido + hablar sincronizados
	if sfx and sfx.stream:
		sfx.play()
		sprite.play("talk")

		# detener sonido y volver a idle al mismo tiempo
		await get_tree().create_timer(0.3).timeout
		if sfx.playing:
			sfx.stop()
		sprite.play("idle")
	else:
		await get_tree().create_timer(0.3).timeout
		sprite.play("idle")

	sprite.modulate = Color(1, 1, 1)
