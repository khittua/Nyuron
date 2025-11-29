extends Label

signal finished

@export var full_text: String = "Antes de empezar nuestra aventura submarina... \n ¿Cómo te gustaría que te llame?"
@export var speed := 0.04

var index := 0
var timer: Timer

func _ready():
	if full_text != "":
		start(full_text)


func start(new_text := ""):
	if new_text != "":
		full_text = new_text

	text = ""
	index = 0

	if not timer:
		timer = Timer.new()
		timer.wait_time = speed
		timer.timeout.connect(_on_tick)
		add_child(timer)
	else:
		timer.stop()

	timer.start()


func _on_tick():
	if index < full_text.length():
		text += full_text[index]
		index += 1
	else:
		timer.stop()
		emit_signal("finished")
