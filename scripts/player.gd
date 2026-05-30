extends CharacterBody2D
## Player — El Zancudo protagonista
## Movimiento top-down con z-index dinámico para perspectiva isométrica

signal entrar_zona(zona: String)

const SPEED: float = 128.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

var can_move: bool = true
var nearby_spot: Node = null
var facing: String = "down"
var last_horizontal: String = "right"

# Texturas por dirección
var tex_front: Texture2D
var tex_back_left: Texture2D
var tex_back_right: Texture2D
var tex_left: Texture2D
var tex_right: Texture2D

# Referencia al mapa para z-index y límites
var _iso_map: Node2D = null

func _ready() -> void:
	tex_front      = load("res://assets/sprites/zancudo_front.png")
	tex_back_left  = load("res://assets/sprites/zancudo_back_left.png")
	tex_back_right = load("res://assets/sprites/zancudo_back_right.png")
	tex_left       = load("res://assets/sprites/zancudo_left.png")
	tex_right      = load("res://assets/sprites/zancudo_right.png")
	z_as_relative = false
	# Buscar IsoMap — puede ser hijo directo de la escena o de Main
	call_deferred("_buscar_iso_map")

func _buscar_iso_map() -> void:
	_iso_map = get_tree().current_scene.get_node_or_null("IsoMap")
	if not _iso_map:
		# Buscar en todo el árbol
		var nodos := get_tree().get_nodes_in_group("iso_map")
		if nodos.size() > 0:
			_iso_map = nodos[0]

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Reintentar encontrar el mapa si no está
	if not _iso_map:
		_iso_map = get_tree().current_scene.get_node_or_null("IsoMap")

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	# Joystick virtual (Android)
	var touch = get_tree().current_scene.get_node_or_null("TouchControls")
	if touch and touch.has_method("get_direction"):
		var touch_dir = touch.get_direction()
		if touch_dir.length() > 0.2:
			input_dir = touch_dir

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		_actualizar_sprite(input_dir)

		# Mover siempre — sin chequeo de caminable (el mapa usa offset de pantalla)
		velocity = input_dir * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Detectar puerta
	if _iso_map and _iso_map.has_method("es_puerta"):
		var zona_destino: String = _iso_map.es_puerta(position)
		if zona_destino != "":
			entrar_zona.emit(zona_destino)

	# Z-index dinámico
	if _iso_map and _iso_map.has_method("get_z_for_pos"):
		z_index = _iso_map.get_z_for_pos(position)
	else:
		z_index = int(position.y / 8)

func _actualizar_sprite(input_dir: Vector2) -> void:
	if abs(input_dir.x) > abs(input_dir.y):
		if input_dir.x < 0:
			facing = "left"
			last_horizontal = "left"
			sprite.texture = tex_left
		else:
			facing = "right"
			last_horizontal = "right"
			sprite.texture = tex_right
	else:
		if input_dir.y < 0:
			facing = "up"
			sprite.texture = tex_back_left if last_horizontal == "left" else tex_back_right
		else:
			facing = "down"
			sprite.texture = tex_front

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_spot:
		_interact_with_spot()

func _interact_with_spot() -> void:
	if nearby_spot and nearby_spot.has_method("interact"):
		can_move = false
		sprite.texture = tex_back_left if last_horizontal == "left" else tex_back_right
		nearby_spot.interact()

func resume_movement() -> void:
	can_move = true
	sprite.texture = tex_front

func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("spots"):
		nearby_spot = area.get_parent()
		if nearby_spot.has_method("show_indicator"):
			nearby_spot.show_indicator()

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("spots"):
		if nearby_spot and nearby_spot.has_method("hide_indicator"):
			nearby_spot.hide_indicator()
		nearby_spot = null
