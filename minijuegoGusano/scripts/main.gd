extends Node2D

@onready var ui_score: Label = $UI/ScoreLabel
@onready var ui_time: Label = $UI/TimerLabel
@onready var game_timer: Timer = $GameTimer
@onready var escape_timer: Timer = $EscapeTimer
@onready var nyuron = $Nyuron
@onready var spawner = $Playfield/Spawner
@onready var bucket: Node2D = $Bucket
@onready var bucket_sprite: AnimatedSprite2D = $Bucket/Sprite

var score := 0
var bucket_count := 0
var is_stunned := false

func _ready():
	spawner.spawned.connect(_on_spawner_spawned)
	game_timer.timeout.connect(_on_game_over)
	escape_timer.timeout.connect(_on_escape_timer)
	
	_update_ui() # Llama a _update_ui para poner la animación "balde vacio"

func _process(_delta):
	var t_left: float = max(0.0, game_timer.time_left)
	ui_time.text = str("%.2f" % t_left) + " s"

# ... (El resto del código hasta _update_ui no cambia) ...

func _on_spawner_spawned(worm):
	$Playfield.add_child(worm)
	worm.request_catch.connect(_on_worm_request_catch)
	worm.escaped.connect(_on_worm_escaped)

func _on_escape_timer():
	if bucket_count <= 0: return
	
	bucket_count = max(0, bucket_count - 1)
	_update_ui()
	
	var w = spawner.worm_scene.instantiate()
	$Playfield.add_child(w)
	w.start_escape(bucket.global_position)
	w.request_catch.connect(_on_worm_request_catch)
	w.escaped.connect(_on_worm_escaped)

func _on_worm_request_catch(worm):
	if is_stunned:
		return

	if worm.is_bad:
		is_stunned = true
		nyuron.stun(2.0)
		get_tree().create_timer(2.0).timeout.connect(func(): is_stunned = false)
		worm.queue_free()
		return

	var is_recapture = (worm.state == "ESCAPING")
	nyuron.shoot_to(worm.global_position, is_recapture)
	
	nyuron.claw_reached_target.connect(func(_pos):
		if is_instance_valid(worm):
			var claw_tip_to_use = nyuron.claw_tip if not is_recapture else nyuron.claw_tip_recap
			worm.attach_to_claw(claw_tip_to_use)
	, CONNECT_ONE_SHOT)

	nyuron.shot_finished.connect(func():
		if not is_instance_valid(worm): return
		
		worm.detach_and_go_to_bucket()
		
		if not is_recapture:
			score += 1
		
		bucket_count += 1
		_update_ui()

	, CONNECT_ONE_SHOT)


func _on_worm_escaped(worm):
	score = max(0, score - 1)
	_update_ui()
	print_rich("[color=red]❌ Un gusano escapó completamente.[/color]")

func _on_game_over():
	$Playfield/Spawner/SpawnTimer.stop()
	escape_timer.stop()
	get_tree().paused = true
	ui_time.text = "¡Fin! Puntos: %d" % score

# ===========================================================
#  FUNCIÓN _update_ui (CORREGIDA)
# ===========================================================

func _update_ui():
	ui_score.text = "Puntos: %d" % score
	
	if bucket_sprite:
		# LÓGICA CORREGIDA:
		# Usamos 'match' para elegir la animación correcta
		# basada en el contador 'bucket_count'.
		match bucket_count:
			0:
				bucket_sprite.play("balde vacio")
			1:
				bucket_sprite.play("con 1 gusano")
			2:
				bucket_sprite.play("con 2 gusano")
			3:
				bucket_sprite.play("con 3 gusano")
			4:
				bucket_sprite.play("con 4 gusano")
			_: # Esto se activa para 5 o más gusanos
				bucket_sprite.play("balde lleno")
	else:
		print("ERROR: _update_ui -> No se puede asignar la animación porque bucket_sprite es null.")
