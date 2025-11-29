extends CanvasLayer

signal transition_finished   # ✅ Nueva señal

@export var block_size := Vector2i(16, 16)
@export var block_color := Color.BLACK

var blocks := []
var block_order := []

func _ready():
	visible = false
	create_blocks()
	calc_spiral_order()

func create_blocks():
	var viewport_size = get_viewport().get_visible_rect().size
	var cols = int(ceil(viewport_size.x / block_size.x))
	var rows = int(ceil(viewport_size.y / block_size.y))

	for y in range(rows):
		for x in range(cols):
			var block = ColorRect.new()
			block.size = block_size
			block.color = block_color
			block.position = Vector2(x * block_size.x, y * block_size.y)
			block.visible = false
			add_child(block)
			blocks.append(block)

func calc_spiral_order():
	var viewport_size = get_viewport().get_visible_rect().size
	var cols = int(ceil(viewport_size.x / block_size.x))
	var rows = int(ceil(viewport_size.y / block_size.y))
	var visited = []
	visited.resize(rows)
	for i in range(rows):
		visited[i] = []
		visited[i].resize(cols)

	var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var dir_idx = 0
	var pos = Vector2i(0, 0)

	for i in range(cols * rows):
		block_order.append(pos.y * cols + pos.x)
		visited[pos.y][pos.x] = true
		var next = pos + directions[dir_idx]
		if next.x < 0 or next.x >= cols or next.y < 0 or next.y >= rows or visited[next.y][next.x]:
			dir_idx = (dir_idx + 1) % 4
			next = pos + directions[dir_idx]
		pos = next

func wipe_to(scene_path: String, duration := 0.1):
	visible = true
	var delay_per_block := 0.004
	for i in range(blocks.size()):
		var idx = block_order[i]
		var block = blocks[idx]
		block.visible = true
		block.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(block, "modulate:a", 1.0, duration)\
			.set_delay(i * delay_per_block)

	var total_time := duration + blocks.size() * delay_per_block
	get_tree().create_timer(total_time).timeout.connect(func():
		get_tree().change_scene_to_file(scene_path)
		wipe_out_fade()
	)

func wipe_out_fade(duration := 0.45):
	var fade_rect := ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.modulate.a = 0.0
	add_child(fade_rect)

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		for block in blocks:
			block.visible = false

		var tween2 := create_tween()
		tween2.tween_property(fade_rect, "modulate:a", 0.0, duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		tween2.tween_callback(func():
			fade_rect.queue_free()
			visible = false
			emit_signal("transition_finished")  # ✅ AVISA QUE TERMINÓ
		)
	)
