extends Control

# UI Principal
@onready var menu_panel := $CanvasLayer/MenuSlidePanel
@onready var turtle_button := $CanvasLayer/MenuSlidePanel/TarjetaGeneral/HBox_Main/Card_Turtlerun/TurtleButton
@onready var worm_button := $CanvasLayer/MenuSlidePanel/TarjetaGeneral/HBox_Main/Card_Worm/WormButton
@onready var food_button := $CanvasLayer/MenuSlidePanel/TarjetaGeneral/HBox_Main/Card_Food/FoodButton
@onready var memorice_button := $CanvasLayer/MenuSlidePanel/TarjetaGeneral/HBox_Main/Card_Memorice/MemoriceButton
@onready var counting_button := $CanvasLayer/MenuSlidePanel/TarjetaGeneral/HBox_Main/Card_Counting/CountingButton
@onready var color_button := $CanvasLayer/MenuSlidePanel/TarjetaGeneral/HBox_Main/Card_Color/ColorButton
@onready var coin_label: Label = $CanvasLayer/CoinDisplay/HBoxContainer/CoinLabel
@onready var tienda_button := $CanvasLayer/HBoxContainer/Tienda

# UI Progreso
@onready var main_ui_buttons := $CanvasLayer/HBoxContainer
@onready var progress_button := $CanvasLayer/BotonProgreso
@onready var panel_progreso: Control = $CanvasLayer/PanelProgreso
@onready var dim_overlay: ColorRect = $CanvasLayer/FondoOscuro
@onready var toggle_button := $CanvasLayer/HBoxContainer/Juegos
@onready var nyuron_visual: AnimatedSprite2D = $NyuronVisual

# Variables de estado
var current_game: Node = null
var panel_visible := false
var menu_color_codes = {
	"default": "",
	"caparazon": "",
	"Caparazón Azul": "_blue",
	"Caparazón Verde": "_green",
	"Caparazón Purpura": "_purple",
	"Caparazón Gris": "_gray"
}

var menu_accessory_codes = {
	"none": "",
	"ninguno": "",
	"Corona": "_corona",
	"Gafas": "_lentes",
	"Gorro": "_gorro",
	"Cadena": "_cadena"
}

# Configuración Gaviotas
@export var gaviota_scene: PackedScene
@onready var spawn_timer: Timer = $SpawnTimer
@export var altura_min := 40.0
@export var altura_max := 200.0

# Inicialización
func _ready() -> void:
	if not has_seen_intro():
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		get_tree().root.set_content_scale_size(Vector2i(270, 480))
		get_tree().change_scene_to_file("res://scenes/intro.tscn")
		return

	load_and_update_coins()
	update_menu_skin()
	
	for node in [
		$CanvasLayer/HBoxContainer/Juegos,
		$CanvasLayer/HBoxContainer/Tienda,
		$CanvasLayer/BotonProgreso
	]:
		node.add_to_group("ui")
		node.modulate.a = 0.0
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if TransitionBlocks.visible:
		TransitionBlocks.transition_finished.connect(func(): fade_in_ui())
	else:
		fade_in_ui()

	spawn_timer.timeout.connect(_spawn_gaviota)

	menu_panel.visible = false

	turtle_button.pressed.connect(_on_turtle_pressed)
	color_button.pressed.connect(_on_color_pressed)
	counting_button.pressed.connect(_on_counting_pressed)
	memorice_button.pressed.connect(_on_memorice_pressed)
	worm_button.pressed.connect(_on_worm_pressed)
	food_button.pressed.connect(_on_food_pressed)
	tienda_button.pressed.connect(_on_tienda_pressed)
	toggle_button.pressed.connect(_toggle_menu)

	panel_progreso.visible = false
	progress_button.pressed.connect(_on_progress_button_pressed)

	if panel_progreso.has_signal("back_pressed"):
		panel_progreso.back_pressed.connect(_on_progress_hud_closed)
	if panel_progreso.has_signal("play_game_pressed"):
		panel_progreso.play_game_pressed.connect(_on_progress_hud_play_game)

	dim_overlay.gui_input.connect(_on_dim_overlay_clicked)

# Actualizar skin del menú
func update_menu_skin():
	var id_cuerpo = ScoreManager.get_equipped_item("caparazon")
	var id_accesorio = ScoreManager.get_equipped_item("accesorio")
	
	var color_suffix = menu_color_codes.get(id_cuerpo, "")
	var acc_suffix = menu_accessory_codes.get(id_accesorio, "")
	
	var folder_path = "res://Accesorios/global/"
	var base_filename = "spr_rest" 
	
	var final_path = folder_path + base_filename + color_suffix + acc_suffix + ".png"
	
	if ResourceLoader.exists(final_path):
		var new_texture = load(final_path)
		_apply_texture_to_menu_anim(new_texture)
		print("Skin Menú aplicada: ", final_path)
	else:
		print("ERROR: No se encontró skin de menú: ", final_path)

# Aplicar textura a la animación
func _apply_texture_to_menu_anim(new_texture: Texture2D):
	if nyuron_visual == null:
		print("ERROR: No encuentro el nodo AnimatedSprite2D en el menú.")
		return

	var frames = nyuron_visual.sprite_frames
	var anim_name = "default" 
	
	if frames.has_animation(anim_name):
		var frame_count = frames.get_frame_count(anim_name)
		for i in range(frame_count):
			var frame_texture = frames.get_frame_texture(anim_name, i)
			
			if frame_texture is AtlasTexture:
				frame_texture.atlas = new_texture
	
		nyuron_visual.stop()
		nyuron_visual.play(anim_name)
	else:
		print("Error: Falta animación '", anim_name, "'")

# Menú lateral
func _toggle_menu() -> void:
	menu_panel.visible = not menu_panel.visible

	if menu_panel.visible:
		if panel_progreso.visible:
			_on_progress_hud_closed()

		main_ui_buttons.visible = false
		progress_button.visible = false

		dim_overlay.visible = true
		create_tween().tween_property(dim_overlay, "color:a", 0.6, 0.25)

	else:
		if not panel_progreso.visible:
			main_ui_buttons.visible = true
			progress_button.visible = true

			var tween = create_tween()
			tween.tween_property(dim_overlay, "color:a", 0.0, 0.25)
			tween.finished.connect(func(): dim_overlay.visible = false)

# Lógica Panel Progreso
func _on_progress_button_pressed():
	if menu_panel.visible:
		menu_panel.visible = false

	if panel_progreso.has_method("update_info"):
		panel_progreso.update_info()
	if panel_progreso.has_method("update_logros"):
		panel_progreso.update_logros()

	panel_progreso.visible = true
	main_ui_buttons.visible = false
	progress_button.visible = false

	dim_overlay.visible = true
	create_tween().tween_property(dim_overlay, "color:a", 0.6, 0.40)

func _on_progress_hud_closed():
	panel_progreso.visible = false
	main_ui_buttons.visible = true
	progress_button.visible = true

	if not menu_panel.visible:
		var tween = create_tween()
		tween.tween_property(dim_overlay, "color:a", 0.0, 0.25)
		tween.tween_callback(func(): dim_overlay.visible = false)

func _on_progress_hud_play_game(game_key: String):
	panel_progreso.visible = false
	main_ui_buttons.visible = true
	progress_button.visible = true
	dim_overlay.visible = false

	match game_key:
		"turtle_runner": _on_turtle_pressed()
		"worm_catch": _on_worm_pressed()
		"food_catch": _on_food_pressed()
		"memorice": _on_memorice_pressed()
		"counting_animals": _on_counting_pressed()
		"nyuron_color": _on_color_pressed()

# Lanzadores de minijuegos
func _on_turtle_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	get_tree().root.set_content_scale_size(Vector2i(480, 270))
	get_tree().change_scene_to_file("res://minigames/turtle_run/scenes/main.tscn")

func _on_worm_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://minigames/worm_bucket/Scenes/main.tscn")

func _on_food_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://minigames/food_catch/scenes/Main.tscn")

func _on_memorice_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://minigames/memorice/scenes/minijuego_memorice.tscn")

func _on_counting_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	get_tree().root.set_content_scale_size(Vector2i(480, 270))
	get_tree().change_scene_to_file("res://minigames/counting_animals/scenes/Main.tscn")

func _on_color_pressed():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	get_tree().root.set_content_scale_size(Vector2i(270, 480))
	get_tree().change_scene_to_file("res://minigames/nyuron_color/scenes/Main.tscn")

# Funciones auxiliares
func _spawn_gaviota():
	if gaviota_scene == null:
		return

	var gaviota = gaviota_scene.instantiate()
	var viewport_size = get_viewport_rect().size

	var izquierda_a_derecha = randi() % 2 == 0
	var y := randf_range(altura_min, altura_max)

	gaviota.position = Vector2(
		-100 if izquierda_a_derecha else viewport_size.x + 100,
		y
	)

	gaviota.direction.x = 1 if izquierda_a_derecha else -1
	if not izquierda_a_derecha:
		gaviota.scale.x = -1

	add_child(gaviota)

func has_seen_intro() -> bool:
	var config := ConfigFile.new()
	var err := config.load("user://player_data.cfg")
	if err != OK:
		return false
	return config.get_value("player", "intro_seen", false)

func fade_in_ui(duration := 0.45):
	for node in get_tree().get_nodes_in_group("ui"):
		var tween := create_tween()
		tween.tween_property(node, "modulate:a", 1.0, duration)
		node.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_dim_overlay_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if panel_progreso.visible:
			_on_progress_hud_closed()
		if menu_panel.visible:
			_toggle_menu()

func load_and_update_coins():
	var current_coins = ScoreManager.get_coins()
	coin_label.text = format_number(current_coins)

func format_number(number: int) -> String:
	if number >= 1_000_000:
		var millions = number / 1_000_000.0
		return str(snapped(millions, 0.1)) + "M"
	elif number >= 1_000:
		var thousands = number / 1_000.0
		return str(snapped(thousands, 0.1)) + "K"
	return str(number)

func _on_volver_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_tienda_pressed():
	get_tree().change_scene_to_file("res://tienda/scenes/StoreMenu.tscn")
