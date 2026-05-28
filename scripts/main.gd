extends Node2D
## Main — Construye toda la escena por código
## Plaga: La Descarada — Sin escenas instanciadas para evitar problemas de UID

func _ready() -> void:
	# Inicializar jugador
	GameManager.inicializar_plaga(GameManager.Taxon.ZANCUDO, "Jugador")
	
	# Cargar partida si viene del menú "Cargar"
	if SaveSystem.has_meta("cargar_al_iniciar"):
		SaveSystem.remove_meta("cargar_al_iniciar")
		SaveSystem.cargar()
	
	# Fondo
	var bg = TextureRect.new()
	bg.texture = load("res://assets/sprites/fondo.jpg")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.offset_right = 640
	bg.offset_bottom = 360
	add_child(bg)
	
	# Título de zona
	var title = Label.new()
	title.position = Vector2(10, 5)
	title.text = "🧪 EL LABORATORIO — Territorio Ganado"
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
	add_child(title)
	
	# Objetivo
	var objetivo = Label.new()
	objetivo.position = Vector2(350, 5)
	objetivo.text = "🎯 Craftea el Anclaje de Fibra [I]"
	objetivo.add_theme_font_size_override("font_size", 10)
	objetivo.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9, 0.8))
	add_child(objetivo)
	
	# Player
	_create_player()
	
	# Spots
	_create_spot(Vector2(150, 100), "Monitor Holográfico Roto", "todos", "Un monitor oxidado de la Era de los Titanes. Su pantalla parpadea con datos incomprensibles. Las Cucarachas creen que esta basura es un tesoro.", Color(0.8, 0.6, 0.1))
	_create_spot(Vector2(480, 250), "Vaso de Agua Estancada", "cazar", "Un cráter de cristal sellado por una fina capa de hielo. Donde hay milagros, hay parásitos.", Color(0.2, 0.4, 0.8))
	_create_spot(Vector2(100, 280), "Cable Expuesto", "explorar", "Un nervio muerto de la antigua Santiago. El cobre asoma como un hueso roto.", Color(0.9, 0.3, 0.1))
	
	# HUD
	_create_hud()
	
	# Touch controls (mobile)
	var touch = CanvasLayer.new()
	touch.name = "TouchControls"
	touch.set_script(load("res://scripts/touch_controls.gd"))
	add_child(touch)

func _create_player() -> void:
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(320, 180)
	player.add_to_group("player")
	player.set_script(load("res://scripts/player.gd"))
	
	# Sprite real del Zancudo
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assets/sprites/zancudo_front.png")
	sprite.scale = Vector2(0.5, 0.5)  # Ajustar tamaño si es muy grande
	player.add_child(sprite)
	
	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	col.shape = shape
	player.add_child(col)
	
	# Interaction area
	var area = Area2D.new()
	area.name = "InteractionArea"
	var area_col = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(36, 36)
	area_col.shape = area_shape
	area.add_child(area_col)
	area.area_entered.connect(player._on_interaction_area_area_entered)
	area.area_exited.connect(player._on_interaction_area_area_exited)
	player.add_child(area)
	
	add_child(player)

func _create_spot(pos: Vector2, spot_name: String, spot_type: String, desc: String, color: Color) -> void:
	var spot = Node2D.new()
	spot.position = pos
	spot.set_script(load("res://scripts/spot.gd"))
	spot.spot_name = spot_name
	spot.spot_type = spot_type
	spot.description = desc
	
	# Area2D
	var area = Area2D.new()
	area.name = "Area2D"
	area.add_to_group("spots")
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	area.add_child(col)
	spot.add_child(area)
	
	# Visual — usar imagen si existe, sino ColorRect
	var img_map = {
		"Monitor Holográfico Roto": "res://assets/sprites/monitorroto.png",
		"Vaso de Agua Estancada": "res://assets/sprites/vasoaguapodrida.png",
		"Cable Expuesto": "res://assets/sprites/cableroto.png",
	}
	
	if img_map.has(spot_name) and ResourceLoader.exists(img_map[spot_name]):
		var spr = Sprite2D.new()
		spr.texture = load(img_map[spot_name])
		spr.scale = Vector2(0.45, 0.45)  # Ajustar según tamaño de imagen
		spot.add_child(spr)
	else:
		var visual = ColorRect.new()
		visual.offset_left = -12
		visual.offset_top = -12
		visual.offset_right = 12
		visual.offset_bottom = 12
		visual.color = color
		spot.add_child(visual)
	
	# Indicator
	var indicator = Sprite2D.new()
	indicator.name = "Indicator"
	indicator.position = Vector2(0, -20)
	indicator.modulate = Color(1, 0, 0, 1)
	var ind_tex = PlaceholderTexture2D.new()
	ind_tex.size = Vector2(10, 10)
	indicator.texture = ind_tex
	indicator.visible = false
	spot.add_child(indicator)
	
	add_child(spot)

func _create_hud() -> void:
	var hud = CanvasLayer.new()
	hud.layer = 10
	hud.set_script(load("res://scripts/hud.gd"))
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.offset_left = 5
	panel.offset_top = 30
	panel.offset_right = 135
	panel.offset_bottom = 110
	hud.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	# Turgencia
	var q_label = Label.new()
	q_label.name = "TurgenciaLabel"
	q_label.text = "🛡️ Turgencia: --"
	q_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(q_label)
	
	var q_bar = ProgressBar.new()
	q_bar.name = "TurgenciaBar"
	q_bar.custom_minimum_size = Vector2(0, 8)
	q_bar.max_value = 100
	q_bar.value = 100
	q_bar.show_percentage = false
	vbox.add_child(q_bar)
	
	# Hemolinfa
	var h_label = Label.new()
	h_label.name = "HemolinfaLabel"
	h_label.text = "💧 Hemolinfa: --"
	h_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(h_label)
	
	var h_bar = ProgressBar.new()
	h_bar.name = "HemolinfaBar"
	h_bar.custom_minimum_size = Vector2(0, 8)
	h_bar.max_value = 50
	h_bar.value = 50
	h_bar.show_percentage = false
	vbox.add_child(h_bar)
	
	# Esencia
	var e_label = Label.new()
	e_label.name = "EsenciaLabel"
	e_label.text = "🍄 Esencia: --"
	e_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(e_label)
	
	var e_bar = ProgressBar.new()
	e_bar.name = "EsenciaBar"
	e_bar.custom_minimum_size = Vector2(0, 8)
	e_bar.max_value = 100
	e_bar.value = 100
	e_bar.show_percentage = false
	vbox.add_child(e_bar)
	
	# EXP
	var x_label = Label.new()
	x_label.name = "ExpLabel"
	x_label.text = "⭐ Nv.1 — EXP: 0/20"
	x_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(x_label)
	
	var x_bar = ProgressBar.new()
	x_bar.name = "ExpBar"
	x_bar.custom_minimum_size = Vector2(0, 6)
	x_bar.max_value = 20
	x_bar.value = 0
	x_bar.show_percentage = false
	vbox.add_child(x_bar)
	
	add_child(hud)


var _inventario_abierto: bool = false
var _bestiario_abierto: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario") and not _inventario_abierto and not _bestiario_abierto:
		_inventario_abierto = true
		var inv = CanvasLayer.new()
		inv.set_script(load("res://scripts/inventario_ui.gd"))
		inv.tree_exited.connect(func(): _inventario_abierto = false)
		add_child(inv)
	elif event.is_action_pressed("bestiario") and not _bestiario_abierto and not _inventario_abierto:
		_bestiario_abierto = true
		var best = CanvasLayer.new()
		best.set_script(load("res://scripts/bestiario_ui.gd"))
		best.tree_exited.connect(func(): _bestiario_abierto = false)
		add_child(best)
