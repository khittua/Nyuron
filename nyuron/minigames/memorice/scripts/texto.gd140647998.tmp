extends Label

func mostrar(posicion: Vector2, texto: String, color: Color):
	text = texto
	modulate = color
	position = posicion
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 30, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()
