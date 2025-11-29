extends Node2D

signal spawn_finished

# Configuracion
@export var spawn_interval := 0.4
@export var total_to_spawn := 20
@export var animals: Array[PackedScene] = []
@export var sand_y_range := Vector2(180, 230)
@export var left_limit := -50
@export var right_limit := 520

# Estado
var timer: Timer
var spawn_counts: Dictionary = {}
var spawned_count := 0
var active_animals := 0
var favorite_type := ""

# Configuracion Inicial
func _ready():
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

# Inicio y detencion de los animales
func start_spawning(favorite: String = ""):
	favorite_type = favorite
	spawn_counts.clear()
	spawned_count = 0
	active_animals = 0
	timer.start()

func stop_spawning():
	timer.stop()

# Consultas
func get_correct_count_for(type_id: String) -> int:
	return spawn_counts.get(type_id, 0)

# Logica de spawn
func _on_timer_timeout():
	if animals.is_empty():
		return

	if spawned_count < animals.size():
		var scene_to_spawn: PackedScene = animals[spawned_count]
		_spawn_animal(scene_to_spawn)
	else:
		var scene_to_spawn: PackedScene = animals.pick_random()
		_spawn_animal(scene_to_spawn)

	if spawned_count >= total_to_spawn:
		timer.stop()

# Crear animal
func _spawn_animal(scene_to_spawn: PackedScene):
	var scene = scene_to_spawn.instantiate()

	var from_left = randf() < 0.5
	var start_x = -80 if from_left else 560
	var start_y = randf_range(sand_y_range.x, sand_y_range.y)
	scene.position = Vector2(start_x, start_y)

	var target_x = right_limit - 48 if from_left else left_limit + 48
	scene.set("target_x", target_x)
	scene.direction = Vector2.RIGHT if from_left else Vector2.LEFT
	scene.scale.x = -1 if from_left else 1
	scene.z_index = int(scene.position.y)
	scene.speed = randf_range(40, 70)

	add_child(scene)
	scene.start_moving()

	active_animals += 1
	scene.connect("finished_moving", Callable(self, "_on_animal_finished"))

	var t = str(scene.type_id).to_lower()
	spawn_counts[t] = spawn_counts.get(t, 0) + 1
	spawned_count += 1

# Fin de movimiento
func _on_animal_finished():
	active_animals -= 1
	if active_animals <= 0 and spawned_count >= total_to_spawn:
		emit_signal("spawn_finished")
