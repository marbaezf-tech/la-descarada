extends Control
## Creación de Personaje — Plaga: La Descarada
## Selección de Taxón + Nombre + Ficha + Avatar Preview

var taxon_seleccionado: GameManager.Taxon = GameManager.Taxon.ZANCUDO
var nombre_input: LineEdit
var ficha_label: RichTextLabel
var btn_confirmar: Button
var taxon_buttons: Array = []
var avatar_sprite: TextureRect
var avatar_placeholder: ColorRect
var avatar_name_label: Label

# Mapa de imágenes por taxón (cuando existan las 2d_*)
const AVATAR_MAP: Dictionary = {
	# Se reemplazarán con "res://imagenes/2d_zancudo.png" etc.
}

# Colores placeholder por taxón
const TAXON_COLORS: Dictionary = {
	0: Color(0.2, 0.8, 0.3),   # Zancudo - verde
	1: Color(0.5, 0.3, 0.1),   # Cucaracha - marrón
	2: Color(0.9, 0.8, 0.0),   # Avispa - amarillo
	3: Color(0.6, 0.1, 0.1),   # Garrapata - rojo oscuro
	4: Color(0.7, 0.4, 0.6),   # Chinche - rosa
	5: Color(0.9, 0.5, 0.9),   # Mariposa - magenta
	6: Color(0.3, 0.3, 0.3),   # Araña - gris oscuro
	7: Color(0.8, 0.4, 0.0),   # Escorpión - naranja
	8: Color(0.4, 0.0, 0.0),   # Vinchuca - rojo sangre
	9: Color(0.2, 0.4, 0.2),   # Mosca - verde oscuro
	10: Color(0.3, 0.0, 0.5),  # Sanguijuela - púrpura
	11: Color(0.6, 0.6, 0.8),  # Polilla - lavanda
	12: Color(0.9, 0.9, 0.2),  # Pulga - amarillo eléctrico
	13: Color(0.4, 0.7, 0.7),  # Típula - cyan
}

func _ready() -> void:
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.04, 0.05, 0.07, 1)
	add_child(bg)
	
	# Layout principal: HBox con avatar izquierda + ficha derecha
	var main_hbox = HBoxContainer.new()
	main_hbox.anchor_right = 1.0
	main_hbox.anchor_bottom = 1.0
	main_hbox.offset_left = 10
	main_hbox.offset_top = 10
	main_hbox.offset_right = -10
	main_hbox.offset_bottom = -10
	main_hbox.add_theme_constant_override("separation", 10)
	add_child(main_hbox)
	
	# === COLUMNA IZQUIERDA: Avatar ===
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(140, 0)
	left_vbox.add_theme_constant_override("separation", 5)
	main_hbox.add_child(left_vbox)
	
	# Título avatar
	var avatar_title = Label.new()
	avatar_title.text = "📸 AVATAR"
	avatar_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_title.add_theme_font_size_override("font_size", 10)
	avatar_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	left_vbox.add_child(avatar_title)
	
	# Container del avatar (placeholder o imagen)
	var avatar_container = PanelContainer.new()
	avatar_container.custom_minimum_size = Vector2(130, 130)
	left_vbox.add_child(avatar_container)
	
	# Placeholder cuadrado de color
	avatar_placeholder = ColorRect.new()
	avatar_placeholder.custom_minimum_size = Vector2(120, 120)
	avatar_placeholder.color = TAXON_COLORS[0]
	avatar_container.add_child(avatar_placeholder)
	
	# TextureRect para cuando haya imagen real
	avatar_sprite = TextureRect.new()
	avatar_sprite.custom_minimum_size = Vector2(120, 120)
	avatar_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_sprite.visible = false
	avatar_container.add_child(avatar_sprite)
	
	# Nombre del taxón bajo el avatar
	avatar_name_label = Label.new()
	avatar_name_label.text = "🦟 Zancudo"
	avatar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_name_label.add_theme_font_size_override("font_size", 12)
	avatar_name_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	left_vbox.add_child(avatar_name_label)
	
	# Facción
	var faccion_label = Label.new()
	faccion_label.name = "FaccionLabel"
	faccion_label.text = ""
	faccion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faccion_label.add_theme_font_size_override("font_size", 9)
	faccion_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	left_vbox.add_child(faccion_label)
	
	# === COLUMNA DERECHA: Selección + Ficha ===
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_scroll)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 6)
	right_scroll.add_child(right_vbox)
	
	# Título
	var title = Label.new()
	title.text = "🧬 INOCULACIÓN — Elige tu Taxón"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	right_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "\"No eliges tu linaje. Tu linaje te elige a ti.\""
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 8)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(subtitle)
	
	# Grid de Taxones (3 columnas para que quepan mejor)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	right_vbox.add_child(grid)
	
	# Crear botón por cada taxón
	for taxon_id in GameManager.TAXON_DATA.keys():
		var data = GameManager.TAXON_DATA[taxon_id]
		var btn = Button.new()
		btn.text = "%s %s" % [data["emoji"], data["nombre"]]
		btn.add_theme_font_size_override("font_size", 9)
		btn.custom_minimum_size = Vector2(95, 22)
		btn.pressed.connect(_on_taxon_selected.bind(taxon_id))
		grid.add_child(btn)
		taxon_buttons.append(btn)
	
	# Nombre del personaje
	var name_hbox = HBoxContainer.new()
	right_vbox.add_child(name_hbox)
	
	var name_label = Label.new()
	name_label.text = "Nombre: "
	name_label.add_theme_font_size_override("font_size", 10)
	name_hbox.add_child(name_label)
	
	nombre_input = LineEdit.new()
	nombre_input.placeholder_text = "Tu alias en el Charco..."
	nombre_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre_input.add_theme_font_size_override("font_size", 10)
	name_hbox.add_child(nombre_input)
	
	# Ficha preview
	ficha_label = RichTextLabel.new()
	ficha_label.custom_minimum_size = Vector2(0, 100)
	ficha_label.bbcode_enabled = true
	ficha_label.add_theme_font_size_override("normal_font_size", 9)
	right_vbox.add_child(ficha_label)
	
	# Botón confirmar
	btn_confirmar = Button.new()
	btn_confirmar.text = "⚔️ INOCULAR — Comenzar Conquista"
	btn_confirmar.add_theme_font_size_override("font_size", 11)
	btn_confirmar.pressed.connect(_on_confirmar)
	right_vbox.add_child(btn_confirmar)
	
	# Botón volver
	var btn_volver = Button.new()
	btn_volver.text = "← Volver al Menú"
	btn_volver.add_theme_font_size_override("font_size", 9)
	btn_volver.pressed.connect(func(): get_tree().change_scene_to_file("res://menu.tscn"))
	right_vbox.add_child(btn_volver)
	
	# Seleccionar Zancudo por defecto
	_on_taxon_selected(GameManager.Taxon.ZANCUDO)

func _on_taxon_selected(taxon_id: GameManager.Taxon) -> void:
	taxon_seleccionado = taxon_id
	var data = GameManager.TAXON_DATA[taxon_id]
	var stats = data["stats_base"]
	
	# Actualizar avatar
	_update_avatar(taxon_id, data)
	
	# Highlight botón seleccionado
	for i in range(taxon_buttons.size()):
		var btn = taxon_buttons[i]
		if i == taxon_id:
			btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			btn.remove_theme_color_override("font_color")
	
	# Calcular stats derivados
	var turgencia_max_val = 80.0 + stats["quitina_base"] * 4.0
	var hemolinfa_max_val = 30.0 + stats["sensilios"] * 4.0
	var velocidad = (stats["ganglios"] + stats["sensilios"]) / 2.0
	
	# Atavismos por taxón
	var atavismos_map = {
		GameManager.Taxon.ZANCUDO: "Vicisitud / Antenas Ancestrales / Llamada del Enjambre",
		GameManager.Taxon.CUCARACHA: "Camuflaje Adaptativo / Exoesqueleto Ancestral / Llamada del Enjambre",
		GameManager.Taxon.AVISPA: "Aleteo Frenético / Mandíbula de Acero / Feromona Dominante",
		GameManager.Taxon.GARRAPATA: "Exoesqueleto Ancestral / Metamorfosis / Llamada del Enjambre",
		GameManager.Taxon.CHINCHE: "Feromona Dominante / Parásito Neural / Exoesqueleto Ancestral",
		GameManager.Taxon.MARIPOSA: "Aleteo Frenético / Feromona Dominante / Antenas Ancestrales",
		GameManager.Taxon.ARANA: "Tejeduría de Éter / Antenas Ancestrales / Parásito Neural",
		GameManager.Taxon.ESCORPION: "Sombra de Pinza / Mandíbula de Acero / Parásito Neural",
		GameManager.Taxon.VINCHUCA: "Veneno Silencioso / Aleteo Frenético / Camuflaje Adaptativo",
		GameManager.Taxon.MOSCA: "Necro-Larva / Exoesqueleto Ancestral / Antenas Ancestrales",
		GameManager.Taxon.SANGUIJUELA: "Camuflaje Adaptativo / Feromona Dominante / Metamorfosis",
		GameManager.Taxon.POLILLA: "Antenas Ancestrales / Camuflaje Adaptativo / Parásito Neural",
		GameManager.Taxon.PULGA: "Espejismo de Alas / Exoesqueleto Ancestral / Aleteo Frenético",
	}
	var atavismos = atavismos_map.get(taxon_id, "Ocelo Ancestral / Exoesqueleto Ancestral / Antenas Ancestrales")
	
	# Construir ficha
	var ficha = ""
	ficha += "[b]%s %s[/b]\n" % [data["emoji"], data["nombre"]]
	ficha += "[color=gray]Facción: %s[/color]\n" % data["faccion"]
	ficha += "[color=gray]Recurso: %s[/color]\n" % data["recurso_nombre"]
	ficha += "[color=gray]Defecto: %s[/color]\n\n" % data["defecto_nombre"]
	ficha += "[color=cyan]— ATRIBUTOS PRIMORDIALES —[/color]\n"
	ficha += "TOR: %d | GAN: %d | QUI: %d\n" % [stats["torax"], stats["ganglios"], stats["quitina_base"]]
	ficha += "SEN: %d | CRI: %d | FER: %d\n\n" % [stats["sensilios"], stats["cripsis"], stats["feromonas"]]
	ficha += "[color=red]Turgencia: %.0f[/color] | " % turgencia_max_val
	ficha += "[color=dodgerblue]Hemolinfa: %.0f[/color] | " % hemolinfa_max_val
	ficha += "[color=yellow]Velocidad: %.1f[/color]\n\n" % velocidad
	ficha += "[color=green]— ATAVISMOS —[/color]\n"
	ficha += "%s\n" % atavismos
	
	ficha_label.text = ficha

func _update_avatar(taxon_id: GameManager.Taxon, data: Dictionary) -> void:
	# Intentar cargar imagen 2d_ si existe
	var img_path = "res://imagenes/2d_%s.png" % data["nombre"].to_lower().replace(" ", "_").replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u")
	
	if ResourceLoader.exists(img_path):
		avatar_sprite.texture = load(img_path)
		avatar_sprite.visible = true
		avatar_placeholder.visible = false
	else:
		# Usar placeholder de color
		avatar_placeholder.color = TAXON_COLORS.get(taxon_id, Color(0.3, 0.3, 0.3))
		avatar_placeholder.visible = true
		avatar_sprite.visible = false
	
	# Actualizar nombre bajo avatar
	avatar_name_label.text = "%s %s" % [data["emoji"], data["nombre"]]
	
	# Actualizar facción
	var faccion_node = get_node_or_null("*/*/FaccionLabel")
	# Buscar el label de facción directamente
	for child in avatar_name_label.get_parent().get_children():
		if child.name == "FaccionLabel":
			child.text = data["faccion"]

func _on_confirmar() -> void:
	var nombre = nombre_input.text.strip_edges()
	if nombre.is_empty():
		nombre = "Plaga Anónima"
	
	# Inicializar el juego con el taxón elegido
	GameManager.reset()
	GameManager.inicializar_plaga(taxon_seleccionado, nombre)
	
	# Ir a la escena principal
	get_tree().change_scene_to_file("res://main.tscn")
