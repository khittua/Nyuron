extends Area2D
class_name BonusItem

@export var fall_speed: float = 140.0
signal resolved_bonus(points: int)

@export var min_spin_deg: float = 5.0
@export var max_spin_deg: float = 15.0
var spin_deg: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# Si quieres darle un brillo distinto:
	sprite.modulate = Color(1.2, 1.1, 0.5)
	area_entered.connect(_on_area_entered)
	var s := randf_range(min_spin_deg, max_spin_deg)
	spin_deg = s if randf() < 0.5 else -s

func _process(delta):
	rotation_degrees += spin_deg * delta
	position.y += fall_speed * delta
	if position.y > get_viewport_rect().size.y + 100.0:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		emit_signal("resolved_bonus", 50)
		queue_free()
