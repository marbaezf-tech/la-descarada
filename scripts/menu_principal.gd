extends Control
## Menú Principal — Plaga: La Descarada

func _ready() -> void:
	# Fondo
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.05, 0.07, 0.09, 1)
	add_child(bg)
	
	# Container central
	var center = VBoxContainer.new()
	center.anchor_left = 0.5
	center.anchor_top = 0.3
	center.anchor_right = 0.5
	center.offset_left = -120
	center.offset_right = 120
	center.add_theme_constant_override("separation", 12)
	add_child(center)
	
	# Título
	var title = Label.new()
	title.text = "🦟 PLAGA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	center.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "La Descarada"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	center.add_child(subtitle)
	
	# Espacio
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)
	
	# Botón Nueva Partida
	var btn_nueva = Button.new()
	btn_nueva.text = "⚔️ Nueva Conquista"
	btn_nueva.pressed.connect(_nueva_partida)
	center.add_child(btn_nueva)
	
	# Botón Cargar
	var btn_cargar = Button.new()
	btn_cargar.text = "📂 Cargar Conquista"
	btn_cargar.pressed.connect(_cargar_partida)
	# Deshabilitar si no hay save
	if not FileAccess.file_exists("user://save_data.json"):
		btn_cargar.disabled = true
		btn_cargar.text = "📂 (Sin partida guardada)"
	center.add_child(btn_cargar)
	
	# Botón Salir
	var btn_salir = Button.new()
	btn_salir.text = "✖ Abandonar el Charco"
	btn_salir.pressed.connect(_salir)
	center.add_child(btn_salir)
	
	# Crédito
	var credit = Label.new()
	credit.text = "\n\"El Charco no perdona la debilidad.\""
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 9)
	credit.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	center.add_child(credit)

func _nueva_partida() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _cargar_partida() -> void:
	# Marcar que debe cargar al iniciar
	SaveSystem.set_meta("cargar_al_iniciar", true)
	get_tree().change_scene_to_file("res://main.tscn")

func _salir() -> void:
	get_tree().quit()
