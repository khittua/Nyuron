extends Node2D
class_name Spawner

signal spawned(worm: Node)

# --- PROPIEDADES (sin cambios) ---
@export var worm_scene: PackedScene
@export var bad_ratio := 0.25
@export var start_interval := 1.8
@export var min_interval := 0.5
@export var difficulty_speed := 0.03

# --- NODOS Y VARIABLES (sin cambios) ---
@onready var spots := get_children().filter(func(n): return n is Marker2D)
@onready var spawn_timer: Timer = $SpawnTimer
var current_interval := start_interval
var time_elapsed := 0.0

# NUEVA VARIABLE: Un diccionario para recordar qué agujero le corresponde a cada gusano.
var worm_hole_map := {}


func _ready():
	randomize()
	spawn_timer.timeout.connect(_on_SpawnTimer_timeout)
	spawn_timer.start(current_interval)

func _process(delta):
	time_elapsed += delta
	current_interval = max(min_interval, start_interval - difficulty_speed * time_elapsed)
	spawn_timer.wait_time = current_interval

# --- LÓGICA PRINCIPAL DEL SPAWNER (sin cambios) ---
func _on_SpawnTimer_timeout():
	var available_spots: Array[Marker2D] = []
	for m in spots:
		var too_close := false
		for child in get_parent().get_children():
			if child is Worm and child.global_position.distance_to(m.global_position) < 25:
				too_close = true; break
		if not too_close:
			available_spots.append(m)

	if available_spots.is_empty(): return

	var spot: Marker2D = available_spots.pick_random()
	var hole = spot.get_node_or_null("Hole")

	if hole:
		# Conectamos la señal de que la animación terminó a la función que crea el gusano.
		hole.animation_finished.connect(_spawn_worm_at_spot.bind(spot), CONNECT_ONE_SHOT)
		hole.play("open")
	else:
		_spawn_worm_at_spot(spot)

# ===========================================================
#  LÓGICA DE CREACIÓN Y CIERRE (CORREGIDA)
# ===========================================================

func _spawn_worm_at_spot(spot: Marker2D):
	# 1. Instancia y configura el gusano (sin cambios).
	var w: Worm = worm_scene.instantiate()
	w.position = spot.global_position
	if randf() < bad_ratio:
		w.is_bad = true

	get_parent().add_child(w)
	emit_signal("spawned", w)

	# 2. LÓGICA CORREGIDA PARA CERRAR EL AGUJERO
	var hole = spot.get_node_or_null("Hole")
	if hole:
		# Guardamos en nuestro mapa que este gusano 'w' está asociado con este 'hole'.
		worm_hole_map[w] = hole
		
		# Conectamos la señal 'tree_exiting' del gusano a nuestra función de limpieza.
		# Esta señal se disparará SIEMPRE que el gusano esté a punto de desaparecer.
		w.tree_exiting.connect(_on_worm_exiting.bind(w), CONNECT_ONE_SHOT)

# NUEVA FUNCIÓN: Esta función se ejecuta justo antes de que un gusano se elimine.
func _on_worm_exiting(worm: Worm):
	# Revisa si el gusano que está desapareciendo tiene un agujero asociado en nuestro mapa.
	if worm_hole_map.has(worm):
		var hole_to_close = worm_hole_map[worm]
		
		# Si el agujero todavía existe, reproduce la animación de cerrar.
		if is_instance_valid(hole_to_close):
			hole_to_close.play("close")
		
		# Limpiamos el mapa para no guardar referencias a gusanos que ya no existen.
		worm_hole_map.erase(worm)
