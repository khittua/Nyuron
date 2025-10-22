extends Node2D

@onready var musica_fondo = $MusicaFondo
@onready var almejas_container = $Almejas
@onready var puntos_label = $UI/PuntosLabel
@onready var panel: Panel         = $UI/GameOverPanel
@onready var title: Label         = $UI/GameOverPanel/Title
@onready var score_lbl: Label     = $UI/GameOverPanel/score
@onready var retry_btn: TextureButton    = $UI/GameOverPanel/Buttons/Retrybutton
@onready var back_btn: TextureButton     = $UI/GameOverPanel/Buttons/BackButton
@onready var sfx_abrir = $SFX_AbrirAlmeja
@onready var sfx_acierto = $SFX_Acierto
@onready var sfx_error = $SFX_Error
@onready var sfx_menos_puntos = $SFX_menos_puntos
@onready var sfx_mas_puntos = $SFX_mas_puntos


var texto_flotante_escena = preload("res://scenes/texto.tscn")

var primera_seleccion = null
var segunda_seleccion = null
var comparando = false
var puntos = 100


func _ready():
	panel.visible = false
	retry_btn.pressed.connect(_on_retry_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	actualizar_puntaje()

	var escenas = [
		preload("res://scenes/almeja_camaron.tscn"),
		preload("res://scenes/almeja_zapatilla.tscn"),
		preload("res://scenes/almeja_lata.tscn"),
		preload("res://scenes/almeja_gusano.tscn"),
		preload("res://scenes/almeja_alga.tscn"),
		preload("res://scenes/almeja_plastico.tscn"),
		preload("res://scenes/almeja_botella.tscn"),
		preload("res://scenes/almeja_basura.tscn"),
		preload("res://scenes/almeja_salmon.tscn"),
		preload("res://scenes/almeja_perla.tscn")
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

	mostrar_y_cerrar_inicialmente(lista_instancias)
	conectar_almejas()


# 🧠 Fase de memorización
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
	if comparando:
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
		# ✅ Correctas
		sfx_acierto.play()
		await get_tree().create_timer(0.6).timeout
		sfx_mas_puntos.play()

		# Crear texto +100 en la posición de la primera almeja
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
		# ❌ Incorrectas
		sfx_error.play()
		await get_tree().create_timer(0.4).timeout
		sfx_menos_puntos.play()

		# Crear texto -50 en la posición de la primera almeja
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
	panel.visible = true


func mostrar_victoria():
	$UI/GameOverPanel/Title.text = "¡Ganaste!"
	$UI/GameOverPanel/score.text = "Puntos: %d" % puntos
	panel.visible = true



func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_back_pressed():
	get_tree().paused = false
	# get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	get_tree().reload_current_scene()  

func _on_tienda_pressed():
	get_tree().change_scene_to_file("res://scenes/tienda.tscn")
