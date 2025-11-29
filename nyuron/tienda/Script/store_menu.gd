extends Control

# UI
@onready var coins_label: Label = $CanvasLayer/UI/VBoxContainer/Monedas
@onready var title_label: Label = $CanvasLayer/UI/VBoxContainer/Titulo

# Botones de items (Grid)
@onready var btn_corona: TextureButton = $CanvasLayer/GridContainer/VBoxContainer/TextureButton
@onready var btn_lentes: TextureButton = $CanvasLayer/GridContainer/VBoxContainer2/TextureButton2
@onready var btn_gorro: TextureButton = $CanvasLayer/GridContainer/VBoxContainer3/TextureButton3
@onready var btn_cadena: TextureButton = $CanvasLayer/GridContainer/VBoxContainer4/TextureButton4
@onready var btn_shell1: TextureButton = $CanvasLayer/GridContainer2/VBoxShell1/TextureButton
@onready var btn_shell2: TextureButton = $CanvasLayer/GridContainer2/VBoxShell2/TextureButton
@onready var btn_shell3: TextureButton = $CanvasLayer/GridContainer2/VBoxShell3/TextureButton
@onready var btn_shell4: TextureButton = $CanvasLayer/GridContainer2/VBoxShell4/TextureButton

@onready var accessories_group = [
	$CanvasLayer/GridContainer/VBoxContainer,
	$CanvasLayer/GridContainer/VBoxContainer2,
	$CanvasLayer/GridContainer/VBoxContainer3,
	$CanvasLayer/GridContainer/VBoxContainer4
]
@onready var shells_group = [
	$CanvasLayer/GridContainer2/VBoxShell1,
	$CanvasLayer/GridContainer2/VBoxShell2,
	$CanvasLayer/GridContainer2/VBoxShell3,
	$CanvasLayer/GridContainer2/VBoxShell4
]

# Panel de información
@onready var info_panel: Panel = $CanvasLayer/InfoPanel
@onready var shop_dim_overlay: ColorRect = $CanvasLayer/ShopDimOverlay
@onready var info_icon: TextureRect = $CanvasLayer/InfoPanel/VBoxContainer/Icon
@onready var info_name: Label = $CanvasLayer/InfoPanel/VBoxContainer/Nombre
@onready var info_price: Label = $CanvasLayer/InfoPanel/VBoxContainer/Precio

# Botones del Panel
@onready var btn_comprar: TextureButton = $CanvasLayer/InfoPanel/VBoxContainer/HBoxContainer/BtnComprar
@onready var btn_cerrar: TextureButton = $CanvasLayer/InfoPanel/VBoxContainer/HBoxContainer/BtnCerrar
# REFERENCIA AL LABEL DENTRO DEL BOTÓN (Ajusta la ruta si tu Label tiene otro nombre)
@onready var label_btn_comprar: Label = $CanvasLayer/InfoPanel/VBoxContainer/HBoxContainer/BtnComprar/Label

# Botones Categoría y Volver
@onready var btn_caparazones: TextureButton = $CanvasLayer/HBoxContainer2/BtnCaparazones
@onready var btn_accesorios: TextureButton = $CanvasLayer/HBoxContainer2/BtnAccesorios
@onready var btn_volver: TextureButton = $CanvasLayer/HBoxContainer/BackButton

# Datos (He añadido la clave 'category' para que funcione el equipamiento)
var accesories = [
	{ name="Corona", category="accesorio", price=25, icon=preload("res://tienda/icons/Corona.png"), preview=preload("res://tienda/icons/Corona.png") },
	{ name="Gafas", category="accesorio", price=15, icon=preload("res://tienda/icons/Lentes.png"), preview=preload("res://tienda/icons/Lentes.png") },
	{ name="Gorro", category="accesorio", price=20, icon=preload("res://tienda/icons/Gorro.png"), preview=preload("res://tienda/icons/Gorro.png") },
	{ name="Cadena", category="accesorio", price=50, icon=preload("res://tienda/icons/Cadena.png"), preview=preload("res://tienda/icons/Cadena.png") }
]

var shells = [
	{ name="Caparazón Azul", category="caparazon", price=10, icon=preload("res://tienda/Images/Skin_Blue.png"), preview=preload("res://tienda/Images/Skin_Blue.png") },
	{ name="Caparazón Verde", category="caparazon", price=10, icon=preload("res://tienda/Images/Skin_Green.png"), preview=preload("res://tienda/Images/Skin_Green.png") },
	{ name="Caparazón Purpura", category="caparazon", price=10, icon=preload("res://tienda/Images/Skin_Purple.png"), preview=preload("res://tienda/Images/Skin_Purple.png") },
	{ name="Caparazón Gris", category="caparazon", price=10, icon=preload("res://tienda/Images/Skin_Gray.png"), preview=preload("res://tienda/Images/Skin_Gray.png") }
]

# Configuracion Inicial
func _ready():
	show_accessories()
	title_label.text = "¡Bienvenido a la Tienda!"
	update_coins()

	# Conexiones de Categorías y Navegación
	btn_accesorios.pressed.connect(func():
		$SFX_Back.play()
		_on_btn_accesorios_pressed()
	)
	btn_caparazones.pressed.connect(func():
		$SFX_Back.play()
		_on_btn_caparazones_pressed()
	)
	btn_cerrar.pressed.connect(func():
		$SFX_Volver.play()
		_close_info()
	)
	btn_volver.pressed.connect(_on_volver_pressed)

	# Conexiones de Items de la Tienda
	btn_corona.pressed.connect(func(): _show_item_info(accesories[0]))
	btn_lentes.pressed.connect(func(): _show_item_info(accesories[1]))
	btn_gorro.pressed.connect(func(): _show_item_info(accesories[2]))
	btn_cadena.pressed.connect(func(): _show_item_info(accesories[3]))
	btn_shell1.pressed.connect(func(): _show_item_info(shells[0]))
	btn_shell2.pressed.connect(func(): _show_item_info(shells[1]))
	btn_shell3.pressed.connect(func(): _show_item_info(shells[2]))
	btn_shell4.pressed.connect(func(): _show_item_info(shells[3]))

	# --- LÓGICA VISUAL DEL BOTÓN COMPRAR (Mover texto al presionar) ---
	btn_comprar.button_down.connect(_on_btn_comprar_down)
	btn_comprar.button_up.connect(_on_btn_comprar_up)
	# Por si el mouse sale del botón mientras está presionado (safety check)
	# btn_comprar.mouse_exited.connect(_on_btn_comprar_up) 

	info_panel.visible = false
	shop_dim_overlay.visible = false
	
	print("Inventario cargado:", ScoreManager.get_inventory())

# Monedas
func update_coins():
	coins_label.text = "Monedas: %s" % ScoreManager.get_coins()

# Efecto visual: Bajar texto
func _on_btn_comprar_down():
	if label_btn_comprar:
		label_btn_comprar.position.y += 2 # Baja 2 pixeles

# Efecto visual: Subir texto (restaurar)
func _on_btn_comprar_up():
	if label_btn_comprar:
		# Corregimos la posición restando lo que sumamos. 
		# Nota: Si usas una posición fija en el inspector, sería mejor: label.position.y = POSICION_ORIGINAL
		label_btn_comprar.position.y -= 2

# Mostrar info y configurar botón
func _show_item_info(item: Dictionary):
	info_panel.visible = true
	shop_dim_overlay.visible = true

	var tween = create_tween()
	tween.tween_property(shop_dim_overlay, "color:a", 0.6, 0.25)

	info_icon.texture = item.preview
	info_name.text = item.name
	info_price.text = "Precio: %s monedas" % item.price

	# Limpiamos conexiones previas del botón comprar para no acumular acciones
	for c in btn_comprar.pressed.get_connections():
		btn_comprar.pressed.disconnect(c.callable)

	# --- Lógica de Estados del Botón ---
	var tengo_item = ScoreManager.get_inventory().has(item.name)
	var esta_equipado = ScoreManager.is_equipped(item.name)

	if esta_equipado:
		# ESTADO 1: YA EQUIPADO
		btn_comprar.disabled = true
		btn_comprar.modulate = Color(0.5, 0.5, 0.5)
		label_btn_comprar.text = "EQUIPADO"
		
	elif tengo_item:
		# ESTADO 2: EN INVENTARIO (PERMITE EQUIPAR)
		btn_comprar.disabled = false
		btn_comprar.modulate = Color(1, 1, 1)
		label_btn_comprar.text = "EQUIPAR"
		btn_comprar.pressed.connect(func(): _on_equip_item(item))
		
	else:
		# ESTADO 3: NO SE TIENE (PERMITE COMPRAR)
		btn_comprar.disabled = false
		btn_comprar.modulate = Color(1, 1, 1)
		label_btn_comprar.text = "COMPRAR" # O mostrar el precio: str(item.price)
		btn_comprar.pressed.connect(func(): _on_buy_item(item))

# Lógica de Compra
func _on_buy_item(item: Dictionary):
	if ScoreManager.get_coins() >= item.price:
		ScoreManager.add_to_inventory(item.name)
		ScoreManager.add_coins(-item.price)
		
		update_coins()
		print("Comprado:", item.name)
		$SFX_Boton.play()
		
		# Refrescamos la info para que el botón cambie a "EQUIPAR" inmediatamente
		_show_item_info(item)
	else:
		print("No tienes monedas suficientes")
		$SFX_Incorrect.play()

# Lógica de Equipar
func _on_equip_item(item: Dictionary):
	ScoreManager.equip_item(item.category, item.name)
	$SFX_Boton.play()
	print("Equipado:", item.name)
	
	# Refrescamos la info para que el botón cambie a "EQUIPADO"
	_show_item_info(item)

# Cerrar panel
func _close_info():
	info_panel.visible = false
	var tween = create_tween()
	tween.tween_property(shop_dim_overlay, "color:a", 0.0, 0.25)
	tween.finished.connect(func(): shop_dim_overlay.visible = false)

# Categorias
func show_accessories():
	for node in accessories_group:
		node.visible = true
	for node in shells_group:
		node.visible = false

func show_shells():
	for node in accessories_group:
		node.visible = false
	for node in shells_group:
		node.visible = true

func _on_btn_accesorios_pressed():
	show_accessories()

func _on_btn_caparazones_pressed():
	show_shells()

# Volver
func _on_volver_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
