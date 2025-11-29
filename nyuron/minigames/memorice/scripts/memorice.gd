extends Node2D

@onready var musica_fondo = $MusicaFondo
@onready var almejas_container = $Almejas
@onready var puntos_label = $UI/PuntosLabel
@onready var panel: Panel         = $UI/GameOverPanel
@onready var title: Label         = $UI/GameOverPanel/Title
@onready var score_lbl: Label     = $UI/GameOverPanel/score
@onready var back_btn: TextureButton     = $UI/GameOverPanel/Buttons/BackButton
@onready var retry_btn: TextureButton = $UI/GameOverPanel/Buttons/RetryButton
@onready var sfx_abrir = $SFX_AbrirAlmeja
@onready var sfx_acierto = $SFX_Acierto
@onready var sfx_error = $SFX_Error
@onready var sfx_menos_puntos = $SFX_menos_puntos
@onready var sfx_mas_puntos = $SFX_mas_puntos
@onready var backButton: Button = $UI/backButton
@onready var intro_panel: Control = $intro_panel
@onready var intro_button: Button = $intro_panel/Button

var juego_iniciado := false
var is_paused := false

var texto_flotante_escena = preload("res://minigames/memorice/scenes/texto.tscn")

var primera_seleccion = null
var segunda_seleccion = null
var comparando = false
var puntos = 100
signal back_to_menu
var last_coins_gained: int = 0
func _ready():
	DisplayServer.window_set_size(Vector2i(480, 800))
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	intro_panel.visible = true
	juego_iniciado = false
	bloquear_todas(true)  # No permitir tocar almejas
	intro_button.pressed.connect(_on_intro_button_pressed)

	panel.visible = false
	back_btn.pressed.connect(_on_back_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	actualizar_puntaje()

	#  configurar sistema de pausa
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	retry_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	#  Conectar botón de pausa
	if backButton:
		backButton.pressed.connect(_on_backButton_pressed)

	var escenas = [
		preload("res://minigames/memorice/scenes/almeja_camaron.tscn"),
		preload("res://minigames/memorice/scenes/almeja_zapatilla.tscn"),
		preload("res://minigames/memorice/scenes/almeja_lata.tscn"),
		preload("res://minigames/memorice/scenes/almeja_gusano.tscn"),
		preload("res://minigames/memorice/scenes/almeja_alga.tscn"),
		preload("res://minigames/memorice/scenes/almeja_plastico.tscn"),
		preload("res://minigames/memorice/scenes/almeja_botella.tscn"),
		preload("res://minigames/memorice/scenes/almeja_basura.tscn"),
		preload("res://minigames/memorice/scenes/almeja_salmon.tscn"),
		preload("res://minigames/memorice/scenes/almeja_perla.tscn")
	]

	var lista_instancias = []
	for escena in escenas:
		lista_instancias.append(escena.instantiate())
		lista_instancias.append(escena.instantiate())

	lista_instancias.shuffle()

	var columnas = 4
	var separacion = Vector2(65, 60)

	var filas = ceil(float(lista_instancias.size()) / columnas)
	var ancho_tablero = columnas * separacion.x
	var alto_tablero = filas * separacion.y

	var pantalla_centro = get_viewport_rect().size / 2
	var inicio = pantalla_centro - Vector2(ancho_tablero / 2, alto_tablero / 2)
	inicio += Vector2(30, 100)

	for i in range(lista_instancias.size()):
		var almeja = lista_instancias[i]
		var fila = i / columnas
		var col = i % columnas
		almeja.position = inicio + Vector2(col * separacion.x, fila * separacion.y)
		almejas_container.add_child(almeja)


	conectar_almejas()
	
	
func _on_intro_button_pressed():
	intro_panel.visible = false
	juego_iniciado = true

	# Desbloquear interacción
	bloquear_todas(false)

	# Iniciar la fase de memorización
	mostrar_y_cerrar_inicialmente(almejas_container.get_children())



# Fase de memorización
func mostrar_y_cerrar_inicialmente(almejas):
	bloquear_todas(true)

	for almeja in almejas:
		if almeja.has_method("abrir"):
			almeja.anim_sprite.play("abrir")
			almeja.abierta = true

	await get_tree().create_timer(5.0).timeout

	for almeja in almejas:
		if almeja.has_method("cerrar"):
			almeja.cerrar()

	bloquear_todas(false)


func conectar_almejas():
	for almeja in almejas_container.get_children():
		almeja.connect("almeja_abierta", Callable(self, "_on_almeja_abierta"))

func _on_almeja_abierta(almeja):
	if not juego_iniciado or is_paused:
		return
	if comparando or is_paused:
		return
	sfx_abrir.play()

	if primera_seleccion == null:
		primera_seleccion = almeja
	elif segunda_seleccion == null and almeja != primera_seleccion:
		segunda_seleccion = almeja
		comparando = true
		bloquear_todas(true, [primera_seleccion, segunda_seleccion])
		_verificar_pareja()


func _verificar_pareja():
	bloquear_todas(true)
	await get_tree().create_timer(0.1).timeout

	if primera_seleccion.objeto_id == segunda_seleccion.objeto_id:
		sfx_acierto.play()
		await get_tree().create_timer(0.6).timeout
		sfx_mas_puntos.play()

		var texto = texto_flotante_escena.instantiate()
		add_child(texto)
		texto.mostrar(primera_seleccion.global_position, "+100", Color(0, 1, 0))

		puntos += 100
		actualizar_puntaje()
		await get_tree().create_timer(0.8).timeout

		if is_instance_valid(primera_seleccion):
			primera_seleccion.queue_free()
		if is_instance_valid(segunda_seleccion):
			segunda_seleccion.queue_free()

		# Espera un frame antes de verificar si ganaste
		await get_tree().process_frame

		if almejas_container.get_child_count() == 0:
			mostrar_victoria()

	else:
		sfx_error.play()
		await get_tree().create_timer(0.4).timeout
		sfx_menos_puntos.play()

		var texto = texto_flotante_escena.instantiate()
		add_child(texto)
		texto.mostrar(primera_seleccion.global_position, "-50", Color(1, 0, 0))

		puntos = max(puntos - 50, 0)
		actualizar_puntaje()
		await get_tree().create_timer(1.0).timeout

		if is_instance_valid(primera_seleccion):
			await primera_seleccion.cerrar()
		if is_instance_valid(segunda_seleccion):
			await segunda_seleccion.cerrar()
		await get_tree().create_timer(0.8).timeout

		if puntos == 0:
			mostrar_game_over()

	# Reset
	primera_seleccion = null
	segunda_seleccion = null
	comparando = false
	bloquear_todas(false)


func bloquear_todas(bloquear: bool, except: Array = []):
	for almeja in almejas_container.get_children():
		if almeja in except:
			continue
		almeja.bloqueada = bloquear


func actualizar_puntaje():
	if puntos_label:
		puntos_label.text = "Puntos: " + str(puntos)


func mostrar_game_over():
	$UI/GameOverPanel/Title.text = "¡Fin del Juego!"
	$UI/GameOverPanel/score.text = "Puntos: %d" % puntos
	$UI/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained
	back_btn.visible = true
	panel.visible = true
	
	if puntos > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			score_manager.save_high_score("memorice", puntos)
		# monedas: 10% del puntaje final ---
		var coins_earned = int(puntos * 0.5)
		if coins_earned > 0 and score_manager:
			score_manager.add_coins(coins_earned)
			print("Ganaste:", coins_earned, "monedas")
			last_coins_gained = coins_earned


func mostrar_victoria():
	
	back_btn.visible = true
	panel.visible = true
	if puntos > 0:
		var score_manager = get_node("/root/ScoreManager")
		if score_manager:
			score_manager.save_high_score("memorice", puntos)
		# --- monedas: 10% del puntaje final ---
		var coins_earned = int(puntos * 0.5)
		if coins_earned > 0 and score_manager:
			score_manager.add_coins(coins_earned)
			print("Ganaste:", coins_earned, "monedas")
			last_coins_gained = coins_earned

	$UI/GameOverPanel/Title.text = "¡Ganaste!"
	$UI/GameOverPanel/score.text = "Puntos: %d" % puntos
	$UI/GameOverPanel/CoinsEarned.text = "Monedas obtenidas: +%d" % last_coins_gained


func _on_back_pressed():
	# Reanudar si estaba en pausa
	if is_paused:
		resume_game()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


# Sistema de pausa
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not is_paused:
			pause_game()
		else:
			resume_game()

func pause_game():
	print("Pausando memorice...")
	is_paused = true
	
	# 1. Pausar música y sonidos
	musica_fondo.stream_paused = true
	sfx_abrir.stream_paused = true
	sfx_acierto.stream_paused = true
	sfx_error.stream_paused = true
	sfx_menos_puntos.stream_paused = true
	sfx_mas_puntos.stream_paused = true
	
	# 2. Pausar todas las almejas
	bloquear_todas(true)
	
	# 3. Detener comparaciones
	comparando = true
	
	# 4. Mostrar panel de pausa
	panel.visible = true
	title.text = "Pausa"
	score_lbl.text = "Puntos: %d" % puntos
	back_btn.visible = true
	
	print("Memorice pausado")

func resume_game():
	print("Reanudando memorice...")
	is_paused = false
	
	# 1. Reanudar música y sonidos
	musica_fondo.stream_paused = false
	sfx_abrir.stream_paused = false
	sfx_acierto.stream_paused = false
	sfx_error.stream_paused = false
	sfx_menos_puntos.stream_paused = false
	sfx_mas_puntos.stream_paused = false
	
	# 2. Reanudar almejas (solo si el juego no ha terminado)
	if almejas_container.get_child_count() > 0:
		bloquear_todas(false)
	
	# 3. Permitir comparaciones nuevamente
	comparando = false
	
	# 4. Ocultar panel
	panel.visible = false
	
	print("Memorice reanudado")

func _on_backButton_pressed():
	if not is_paused:
		pause_game()
	else:
		resume_game()
