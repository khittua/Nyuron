extends Control

@onready var panel1 = $Panel1
@onready var panel2 = $Panel2
@onready var panel3 = $Panel3

@onready var name_input: LineEdit = $Panel2/LineEdit
@onready var panel3_label: Label = $Panel3/Label

var player_name := ""

func _ready():
	show_panel(1)

	# Ocultar los botones al inicio
	$Panel1/Button.visible = false
	$Panel2/Button.visible = false
	$Panel3/Button.visible = false

	# --- PANEL 1 ---
	var label1 := $Panel1/Label
	label1.finished.connect(func():
		fade_in_button($Panel1/Button)
	)

	# --- PANEL 2 ---
	var label2 := $Panel2/Label
	label2.finished.connect(func():
		fade_in_button($Panel2/Button)
		$Panel2/LineEdit.visible = true
	)

	# --- PANEL 3 ---
	var label3 := $Panel3/Label
	label3.finished.connect(func():
		fade_in_button($Panel3/Button)
	)

	# Conectar botones
	$Panel1/Button.pressed.connect(_on_panel1_continue)
	$Panel2/Button.pressed.connect(_on_panel2_continue)
	$Panel3/Button.pressed.connect(_on_panel3_start)


func show_panel(num: int):
	panel1.visible = num == 1
	panel2.visible = num == 2
	panel3.visible = num == 3


func _on_panel1_continue():
	$Panel2/Button.visible = false
	$Panel2/Button.modulate.a = 0.0
	$Panel2/LineEdit.visible = false
	show_panel(2)
	$Panel2/Label.start() # <-- ahora sí se mostrará correctamente


func _on_panel2_continue():
	player_name = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Jugador"

	# Aseguramos que el botón esté oculto ANTES de mostrar Panel3
	$Panel3/Button.visible = false
	$Panel3/Button.modulate.a = 0.0

	# Cambiar panel primero
	show_panel(3)

	# Aplicar texto dinámico CON efecto de typewriter
	panel3_label.start("¡Un gusto conocerte, %s!\nAcompáñame a explorar el océano, jugar, aprender y entrenar tu mente con minijuegos divertidos.\n ¿Estás Listo?" % player_name)

	# Guardar el nombre
	save_player_name(player_name)


func _on_panel3_start():
	TransitionBlocks.wipe_to("res://scenes/main_menu.tscn")


func save_player_name(name: String):
	var config = ConfigFile.new()
	config.set_value("player", "name", name)
	config.set_value("player", "intro_seen", true)
	config.save("user://player_data.cfg")
	
	
	
func fade_in_button(button: Button, duration := 0.4):
	button.visible = true
	button.modulate.a = 0.0  # empieza invisible

	var tween := create_tween()
	tween.tween_property(button, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
