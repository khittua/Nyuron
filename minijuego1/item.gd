extends Area2D
class_name FallingItem
@export var textures: Array[Texture2D]   
@export var fall_speed: float = 150.0
@export var is_trash: bool = false

@export var min_spin_deg: float = 15.0
@export var max_spin_deg: float = 45.0
var spin_deg: float = 0.0

static var global_speed_multiplier: float = 1.0

signal resolved(is_trash: bool)  # true si era basura, false si comida
@onready var sprite: Sprite2D = $Sprite2D
func _ready():
	area_entered.connect(_on_area_entered)
	# Elegir sprite al azar
	if textures.size() > 0:
		sprite.texture = textures[randi() % textures.size()]
	else:
		push_warning("No hay texturas asignadas en 'textures' para %s" % name)
		
	var s := randf_range(min_spin_deg, max_spin_deg)
	spin_deg = s if randf() < 0.5 else -s
	
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta):
	rotation_degrees += spin_deg * delta        # ← giro
	position.y += fall_speed * global_speed_multiplier * delta
	if position.y > get_viewport_rect().size.y + 100.0:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		emit_signal("resolved", is_trash)
		queue_free()
 
