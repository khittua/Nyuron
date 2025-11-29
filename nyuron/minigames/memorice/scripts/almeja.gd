extends Area2D

signal almeja_abierta(almeja)

@export var objeto_id: int = 0
var abierta := false
var bloqueada := false


@onready var anim_sprite := $AnimatedSprite2D

func _ready():
	anim_sprite.play("cerrar") # comienza cerrada

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# solo permitir clic si no está abierta ni bloqueada
		if not bloqueada and not abierta:
			abrir()

func abrir():
	abierta = true
	emit_signal("almeja_abierta", self)
	anim_sprite.play("abrir")
	await anim_sprite.animation_finished

func cerrar():
	anim_sprite.play("cerrar")
	await anim_sprite.animation_finished
	abierta = false


func cerrar_inicial():
	anim_sprite.play("cerrar")
	await anim_sprite.animation_finished
	abierta = false
