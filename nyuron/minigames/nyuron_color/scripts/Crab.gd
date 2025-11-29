extends Area2D

@export var color_name: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

signal crab_pressed(color: String)

# Variable de control para el "Debounce" (Evita doble toque accidental)
var can_press: bool = true 

func _ready() -> void:
	# Animación base
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	# Conectar el input del Area2D
	connect("input_event", Callable(self, "_on_input_event"))
	
	input_pickable = true
	monitoring = true

func _on_input_event(viewport, event, shape_idx) -> void:
	# 1. Si está en enfriamiento (cooldown), ignoramos el input inmediatamente
	if not can_press:
		return

	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		# 2. Bloqueamos inputs futuros
		can_press = false
		
		# 3. Emitimos la señal UNA sola vez
		emit_signal("crab_pressed", color_name)
		# print("Crab tocado:", color_name)

		# 4. Esperamos un poco (0.15s suele ser mejor que 0.1 para móviles)
		await get_tree().create_timer(0.15).timeout
		
		# 5. Desbloqueamos para permitir tocar de nuevo
		can_press = true

func _flash() -> void:
	# (Tu código de animación sigue igual)
	var t = create_tween()
	t.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	t.tween_property(sprite, "scale", Vector2(1, 1), 0.1)

	sprite.modulate = Color(1.3, 1.3, 1.3)

	if sfx and sfx.stream:
		sfx.play()
		sprite.play("talk")
		await get_tree().create_timer(0.3).timeout
		if sfx.playing:
			sfx.stop()
		sprite.play("idle")
	else:
		await get_tree().create_timer(0.3).timeout
		sprite.play("idle")

	sprite.modulate = Color(1, 1, 1)
