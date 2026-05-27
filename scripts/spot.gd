extends Node2D
## Spot — Punto de interacción en el mapa
## Cuando el jugador se acerca y presiona Interact, muestra el menú

@export var spot_name: String = "Spot"
@export var spot_type: String = "explorar"  # explorar, cazar, lotear, npc
@export var description: String = "Un lugar interesante del territorio."

@onready var indicator: Sprite2D = $Indicator
@onready var area: Area2D = $Area2D

func _ready() -> void:
	indicator.visible = false
	area.add_to_group("spots")

func show_indicator() -> void:
	indicator.visible = true

func hide_indicator() -> void:
	indicator.visible = false

func interact() -> void:
	hide_indicator()
	# Crear menú por código
	var menu = CanvasLayer.new()
	menu.set_script(load("res://scripts/spot_menu.gd"))
	menu.setup(spot_name, spot_type, description)
	menu.closed.connect(_on_menu_closed)
	get_tree().current_scene.add_child(menu)

func _on_menu_closed() -> void:
	# Devolver control al jugador
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.resume_movement()
