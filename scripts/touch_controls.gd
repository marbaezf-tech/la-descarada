extends CanvasLayer
## TouchControls — Joystick virtual + botones para Android/Mobile

var joystick_center: Vector2
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_direction: Vector2 = Vector2.ZERO

var outer_circle: Control
var inner_circle: ColorRect
var btn_action: Button
var btn_inventory: Button

const JOYSTICK_RADIUS: float = 40.0

func _ready() -> void:
	layer = 5
	
	# Solo mostrar en mobile/touch
	if not _is_touch_device():
		queue_free()
		return
	
	_create_joystick()
	_create_buttons()

func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web") or DisplayServer.is_touchscreen_available()

func _create_joystick() -> void:
	# Outer circle (base del joystick)
	outer_circle = Control.new()
	outer_circle.position = Vector2(70, 240)
	outer_circle.custom_minimum_size = Vector2(80, 80)
	add_child(outer_circle)
	
	var outer_bg = ColorRect.new()
	outer_bg.offset_left = -40
	outer_bg.offset_top = -40
	outer_bg.offset_right = 40
	outer_bg.offset_bottom = 40
	outer_bg.color = Color(0.3, 0.3, 0.3, 0.4)
	outer_circle.add_child(outer_bg)
	
	# Inner circle (el stick)
	inner_circle = ColorRect.new()
	inner_circle.offset_left = -15
	inner_circle.offset_top = -15
	inner_circle.offset_right = 15
	inner_circle.offset_bottom = 15
	inner_circle.color = Color(0.8, 0.8, 0.8, 0.7)
	outer_circle.add_child(inner_circle)
	
	joystick_center = outer_circle.position

func _create_buttons() -> void:
	# Botón de Acción (Espacio/Interact)
	btn_action = Button.new()
	btn_action.text = "⚡"
	btn_action.position = Vector2(550, 260)
	btn_action.custom_minimum_size = Vector2(50, 50)
	btn_action.add_theme_font_size_override("font_size", 20)
	btn_action.pressed.connect(_on_action_pressed)
	add_child(btn_action)
	
	# Botón de Inventario
	btn_inventory = Button.new()
	btn_inventory.text = "🎒"
	btn_inventory.position = Vector2(550, 200)
	btn_inventory.custom_minimum_size = Vector2(40, 40)
	btn_inventory.add_theme_font_size_override("font_size", 16)
	btn_inventory.pressed.connect(_on_inventory_pressed)
	add_child(btn_inventory)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touch is in joystick area (left side)
			if event.position.x < 200 and event.position.y > 180:
				joystick_active = true
				joystick_touch_index = event.index
		else:
			if event.index == joystick_touch_index:
				joystick_active = false
				joystick_touch_index = -1
				joystick_direction = Vector2.ZERO
				inner_circle.position = Vector2.ZERO
	
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index and joystick_active:
			var diff = event.position - joystick_center
			if diff.length() > JOYSTICK_RADIUS:
				diff = diff.normalized() * JOYSTICK_RADIUS
			inner_circle.position = diff
			joystick_direction = diff / JOYSTICK_RADIUS

func get_direction() -> Vector2:
	return joystick_direction

func _on_action_pressed() -> void:
	# Simular tecla de interacción
	var ev = InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	# Release
	var ev2 = InputEventAction.new()
	ev2.action = "interact"
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _on_inventory_pressed() -> void:
	var ev = InputEventAction.new()
	ev.action = "inventario"
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 = InputEventAction.new()
	ev2.action = "inventario"
	ev2.pressed = false
	Input.parse_input_event(ev2)
