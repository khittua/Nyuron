extends Node2D
class_name Spawner

signal spawned(worm: Node)

# Configuración
@export var worm_scene: PackedScene
@export var bad_ratio := 0.25
@export var start_interval := 1.8
@export var min_interval := 0.5
@export var difficulty_speed := 0.03

@onready var spots := get_children().filter(func(n): return n is Marker2D)
@onready var spawn_timer: Timer = $SpawnTimer

var current_interval := start_interval
var time_elapsed := 0.0
var worm_hole_map := {}

func _ready():
	randomize()
	spawn_timer.timeout.connect(_on_SpawnTimer_timeout)
	spawn_timer.start(current_interval)

func _process(delta):
	time_elapsed += delta
	current_interval = max(min_interval, start_interval - difficulty_speed * time_elapsed)
	spawn_timer.wait_time = current_interval

# Ciclo de aparición
func _on_SpawnTimer_timeout():
	var available_spots: Array[Marker2D] = []

	for m in spots:
		var too_close := false
		for child in get_parent().get_children():
			if child is Worm and child.global_position.distance_to(m.global_position) < 25:
				too_close = true
				break
		if not too_close:
			available_spots.append(m)

	if available_spots.is_empty():
		return

	var spot: Marker2D = available_spots.pick_random()
	var hole = spot.get_node_or_null("Hole")

	if hole:
		hole.animation_finished.connect(_spawn_worm_at_spot.bind(spot), CONNECT_ONE_SHOT)
		hole.play("open")
	else:
		_spawn_worm_at_spot(spot)

# Instanciar gusano
func _spawn_worm_at_spot(spot: Marker2D):
	var w: Worm = worm_scene.instantiate()
	w.position = spot.global_position

	if randf() < bad_ratio:
		w.is_bad = true

	get_parent().add_child(w)
	emit_signal("spawned", w)

	var hole = spot.get_node_or_null("Hole")
	if hole:
		worm_hole_map[w] = hole
		w.tree_exiting.connect(_on_worm_exiting.bind(w), CONNECT_ONE_SHOT)

# Limpieza al salir
func _on_worm_exiting(worm: Worm):
	if worm_hole_map.has(worm):
		var hole_to_close = worm_hole_map[worm]

		if is_instance_valid(hole_to_close):
			hole_to_close.play("close")

		worm_hole_map.erase(worm)
