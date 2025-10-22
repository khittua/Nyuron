extends Node2D

@onready var label: Label = $Label

func show_text(text: String, color: Color = Color(1,1,1), duration := 0.8):
	label.text = text
	label.modulate = color
	label.scale = Vector2(0.8, 0.8)

	# Movimiento ascendente + fade + leve crecimiento
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 40, duration).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(label, "modulate:a", 0.0, duration)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), duration * 0.7)

	await t.finished
	queue_free()
