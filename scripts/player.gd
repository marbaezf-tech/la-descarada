extends CharacterBody2D
## Player — El Zancudo protagonista
## Movimiento top-down 4 direcciones estilo RPG Maker

const SPEED: float = 128.0  # 4 tiles/segundo (tiles de 32px)

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

var can_move: bool = true
var nearby_spot: Node = null
var facing: String = "down"
var last_horizontal: String = "right"  # Recuerda si fue izquierda o derecha

# Texturas por dirección
var tex_front: Texture2D
var tex_back_left: Texture2D
var tex_back_right: Texture2D
var tex_left: Texture2D
var tex_right: Texture2D

func _ready() -> void:
	tex_front = load("res://assets/sprites/zancudo_front.png")
	tex_back_left = load("res://assets/sprites/zancudo_back_left.png")
	tex_back_right = load("res://assets/sprites/zancudo_back_right.png")
	tex_left = load("res://assets/sprites/zancudo_left.png")
	tex_right = load("res://assets/sprites/zancudo_right.png")

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * SPEED
		# Cambiar sprite según dirección
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
				# Mostrar back-L o back-R según última dirección horizontal
				if last_horizontal == "left":
					sprite.texture = tex_back_left
				else:
					sprite.texture = tex_back_right
			else:
				facing = "down"
				sprite.texture = tex_front
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_spot:
		_interact_with_spot()

func _interact_with_spot() -> void:
	if nearby_spot and nearby_spot.has_method("interact"):
		can_move = false
		# Cambiar a sprite de espalda al interactuar (según último lado)
		if last_horizontal == "left":
			sprite.texture = tex_back_left
		else:
			sprite.texture = tex_back_right
		nearby_spot.interact()

func resume_movement() -> void:
	can_move = true
	sprite.texture = tex_front

func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("spots"):
		nearby_spot = area.get_parent()
		# Mostrar indicador de interacción
		if nearby_spot.has_method("show_indicator"):
			nearby_spot.show_indicator()

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("spots"):
		if nearby_spot and nearby_spot.has_method("hide_indicator"):
			nearby_spot.hide_indicator()
		nearby_spot = null
