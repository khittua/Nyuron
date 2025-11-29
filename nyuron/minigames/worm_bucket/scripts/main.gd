extends Node2D

# UI
@onready var ui_score: Label = $UI/ScoreLabel
@onready var ui_time: Label = $UI/TimerLabel
@onready var game_timer: Timer = $GameTimer
@onready var escape_timer: Timer = $EscapeTimer
@onready var nyuron = $Nyuron
@onready var spawner = $Playfield/Spawner
@onready var bucket: Node2D = $Bucket
@onready var bucket_sprite: AnimatedSprite2D = $Bucket/Sprite
@onready var intro_panel: Control = $intro_panel
@onready var intro_button: Button = $intro_panel/Button
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var title_lbl: Label = $UI/GameOverPanel/Title
@onready var score_lbl: Label = $UI/GameOverPanel/Score
@onready var back_btn: TextureButton = $UI/GameOverPanel/Buttons/BackButton
@onready var backButton: Button = $UI/backButton
@onready var retry_btn: TextureButton = $UI/GameOverPanel/Buttons/RetryButton
@onready var damage_border: ColorRect = $UI/DamageBorder
@onready var damage_mat: ShaderMaterial = damage_border.material

# Audio
@onready var sfx_catch: AudioStreamPlayer = $SFX_Catch
@onready var sfx_fail: AudioStreamPlayer = $SFX_Fail

# Estado
var score := 0
var bucket_count := 0
var is_stunned := false
var last_coins_gained: int = 0
var is_paused := false
var damage_tween: Tween

signal back_to_menu

# Inicialización
func _ready() -> void:
	add_to_group("worm_game")

	spawner.spawned.connect(_on_spawner_spawned)
	game_timer.timeout.connect(_on_game_over)
	escape_timer.timeout.connect(_on_escape_timer)
	retry_btn.pressed.connect(_on_retry_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	if backButton:
		backButton.pressed.connect(_on_backButton_pressed)

	var ui_node := $UI
	if ui_node is CanvasLayer:
		ui_node.follow_viewport_enabled = true

	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	backButton.process_mode = Node.PROCESS_MODE_ALWAYS

	game_over_panel.visible = false

	if bucket_sprite:
		bucket_sprite.stop()

	_update_ui()
	_show_intro()

# Intro
func _show_intro():
	intro_panel.visible = true
	is_paused = true
	backButton.visible = false

	game_timer.paused = true
	escape_timer.paused = true
	if spawner and spawner.has_node("SpawnTimer"):
		spawner.get_node("SpawnTimer").paused = true

	for worm in $Playfield.get_children():
		if worm is Area2D:
			worm.input_pickable = false

	intro_button.pressed.connect(_start_game)

func _start_game():
	print("Iniciando juego...")

	intro_panel.visible = false
	is_paused = false
	backButton.visible = true

	game_timer.paused = false
	escape_timer.paused = false
	if spawner and spawner.has_node("SpawnTimer"):
		spawner.get_node("SpawnTimer").paused = false

	for worm in $Playfield.get_children():
		if worm is Area2D:
			worm.input_pickable = true

	if game_timer.is_stopped():
		game_timer.start()

# Loop principal
func _process(_delta: float) -> void:
	if is_paused:
		return

	var t_left: float = max(0.0, game_timer.time_left)
	ui_time.text = "%.2f s" % t_left

# Spawner y gusanos
func _on_spawner_spawned(worm: Node) -> void:
	if "game" in worm:
		worm.game = self

	if worm.has_signal("request_catch"):
		worm.request_catch.connect(_on_worm_request_catch)
	if worm.has_signal("escaped"):
		worm.escaped.connect(_on_worm_escaped)

	if worm is Area2D:
		worm.input_pickable = true
		if worm.input_event.is_connected(_on_worm_input_event):
			worm.input_event.disconnect(_on_worm_input_event)
			
		worm.input_event.connect(_on_worm_input_event.bind(worm))

func _on_worm_input_event(_viewport, event: InputEvent, _shape_idx: int, worm: Node) -> void:
	if is_paused:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_worm_request_catch(worm)

func _on_escape_timer() -> void:
	if is_paused:
		return

	if bucket_count <= 0:
		return

	bucket_count = max(0, bucket_count - 1)
	_update_ui()

	var w = spawner.worm_scene.instantiate()
	$Playfield.add_child(w)

	if "game" in w:
		w.game = self

	if w.has_method("start_escape"):
		w.start_escape(bucket.global_position)

	if w.has_signal("request_catch"):
		w.request_catch.connect(_on_worm_request_catch)
	if w.has_signal("escaped"):
		w.escaped.connect(_on_worm_escaped)

	if w is Area2D:
		w.input_pickable = true
		w.input_event.connect(_on_worm_input_event.bind(w))

# Captura y daño
func _on_worm_request_catch(worm: Node) -> void:
	if is_paused:
		return
	if is_stunned:
		return

	# Lógica Gusano Malo
	if "is_bad" in worm and worm.is_bad:
		if sfx_fail:
			sfx_fail.play()
			
		is_stunned = true
		if nyuron.has_method("stun"):
			nyuron.stun(2.0)
		_start_damage_pulse()

		get_tree().create_timer(2.0).timeout.connect(func ():
			is_stunned = false
			_stop_damage_pulse()
		)

		if is_instance_valid(worm):
			worm.queue_free()
		return

	# Lógica Gusano Normal
	var is_recapture: bool = ("state" in worm and worm.state == "ESCAPING")

	if nyuron.has_method("shoot_to"):
		nyuron.shoot_to(worm.global_position, is_recapture)

	if nyuron.has_signal("claw_reached_target"):
		nyuron.claw_reached_target.connect(func (_pos):
			if is_instance_valid(worm):
				var claw_tip_to_use = nyuron.claw_tip if not is_recapture else nyuron.claw_tip_recap
				if "attach_to_claw" in worm:
					worm.attach_to_claw(claw_tip_to_use)
		, CONNECT_ONE_SHOT)

	if nyuron.has_signal("shot_finished"):
		nyuron.shot_finished.connect(func ():
			if not is_instance_valid(worm):
				return
			if "detach_and_go_to_bucket" in worm:
				worm.detach_and_go_to_bucket()
			
			if not is_recapture:
				score += 1
				if sfx_catch:
					sfx_catch.pitch_scale = randf_range(0.9, 1.1)
					sfx_catch.play()
			
			bucket_count += 1
			_update_ui()
		, CONNECT_ONE_SHOT)

func _on_worm_escaped(_worm: Node) -> void:
	if is_paused:
		return

	score = max(0, score - 1)
	_update_ui()
	print_rich("[color=red]Un gusano escapó completamente.[/color]")

# Fin del juego
func _on_game_over() -> void:
	if is_paused:
		return

	$Playfield/Spawner/SpawnTimer.stop()
	escape_timer.stop()

	ui_time.text = "Fin. Puntos: %d" % score

	if score > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			score_manager.save_high_score("worm_catch", score)
			var coins_earned = int(score * 2.5)
			if coins_earned > 0:
				score_manager.add_coins(coins_earned)
				print("Ganaste:", coins_earned, "monedas")
				last_coins_gained = coins_earned

	_show_game_over_panel()

	for worm in $Playfield.get_children():
		if worm is Area2D:
			worm.input_pickable = false

func _show_game_over_panel() -> void:
	game_over_panel.visible = true
	title_lbl.text = "Fin del Juego"
	score_lbl.text = "Puntos: %d" % score
	$UI/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained
	back_btn.visible = true

# Navegación
func _on_back_pressed() -> void:
	if is_paused:
		resume_game()

	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

# UI y feedback
func _update_ui() -> void:
	ui_score.text = "Puntos: %d" % score

	if bucket_sprite:
		match bucket_count:
			0: bucket_sprite.play("balde vacio")
			1: bucket_sprite.play("con 1 gusano")
			2: bucket_sprite.play("con 2 gusano")
			3: bucket_sprite.play("con 3 gusano")
			4: bucket_sprite.play("con 4 gusano")
			_: bucket_sprite.play("balde lleno")
	else:
		print("ERROR: bucket_sprite es null.")

func _start_damage_pulse() -> void:
	if damage_tween:
		damage_tween.kill()
	damage_tween = create_tween().set_loops()
	damage_tween.tween_property(damage_mat, "shader_parameter/intensity", 0.4, 0.2).set_trans(Tween.TRANS_SINE)
	damage_tween.tween_property(damage_mat, "shader_parameter/intensity", 0.0, 0.2).set_trans(Tween.TRANS_SINE)

func _stop_damage_pulse() -> void:
	if damage_tween:
		damage_tween.kill()
		damage_tween = null
	if damage_mat:
		damage_mat.set_shader_parameter("intensity", 0.0)

# Pausa
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not is_paused:
			pause_game()
		else:
			resume_game()

func pause_game():
	print("Pausando juego...")
	is_paused = true

	game_timer.paused = true
	escape_timer.paused = true
	if spawner and spawner.has_node("SpawnTimer"):
		spawner.get_node("SpawnTimer").paused = true

	if nyuron:
		nyuron.process_mode = Node.PROCESS_MODE_DISABLED
		var nyuron_anim := nyuron.get_node_or_null("AnimatedSprite2D")
		if nyuron_anim:
			nyuron_anim.speed_scale = 0.0

	pause_all_worms(true)

	if bucket_sprite:
		bucket_sprite.speed_scale = 0.0

	if damage_tween:
		damage_tween.kill()

	game_over_panel.visible = true
	title_lbl.text = "Pausa"
	score_lbl.text = "Puntos: %d" % score
	back_btn.visible = true

	print("Juego pausado")

func resume_game():
	print("Reanudando juego...")
	is_paused = false

	game_timer.paused = false
	escape_timer.paused = false
	if spawner and spawner.has_node("SpawnTimer"):
		spawner.get_node("SpawnTimer").paused = false

	if nyuron:
		nyuron.process_mode = Node.PROCESS_MODE_INHERIT
		var nyuron_anim := nyuron.get_node_or_null("AnimatedSprite2D")
		if nyuron_anim:
			nyuron_anim.speed_scale = 1.0

	pause_all_worms(false)

	if bucket_sprite:
		bucket_sprite.speed_scale = 1.0

	game_over_panel.visible = false

	print("Juego reanudado")

func _on_backButton_pressed():
	if not is_paused:
		pause_game()
	else:
		resume_game()

# Pausa helpers
func pause_all_worms(pause: bool):
	var worm_count = 0
	for worm in $Playfield.get_children():
		if is_instance_valid(worm) and worm is Area2D:
			if pause:
				worm.process_mode = Node.PROCESS_MODE_DISABLED
				var worm_anim := worm.get_node_or_null("AnimatedSprite2D")
				if worm_anim:
					worm_anim.speed_scale = 0.0
			else:
				worm.process_mode = Node.PROCESS_MODE_INHERIT
				var worm_anim := worm.get_node_or_null("AnimatedSprite2D")
				if worm_anim:
					worm_anim.speed_scale = 1.0
			worm_count += 1
