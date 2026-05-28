extends Control
## Menú Principal — Plaga: La Descarada
## Si existe assets/video/intro.ogv, reproduce intro antes del menú

var _intro_playing: bool = false

func _ready() -> void:
	# Intentar reproducir intro si existe (verificar archivo en disco)
	var has_video = FileAccess.file_exists("res://video/video Trailer torneo 1.ogv") or FileAccess.file_exists("res://video/video Trailer torneo 1.mp4") or FileAccess.file_exists("res://assets/video/intro.ogv")
	if has_video:
		_play_intro()
	else:
		_build_menu()

func _play_intro() -> void:
	_intro_playing = true
	_play_video_sequence()

var _video_queue: Array = []
var _current_video_player: VideoStreamPlayer = null

func _play_video_sequence() -> void:
	# Buscar videos en orden: trailer 1, pantalla intermedia, trailer 2
	_video_queue = []
	
	# Priorizar OGV (nativo Godot), fallback a MP4
	var videos_v1 = [
		"res://video/video Trailer torneo 1.ogv",
		"res://video/video Trailer torneo 1.mp4",
		"res://assets/video/intro.ogv",
	]
	
	# Video 1
	for v in videos_v1:
		if FileAccess.file_exists(v):
			_video_queue.append({"tipo": "video", "path": v})
			break
	
	# Pantalla intermedia
	_video_queue.append({"tipo": "texto", "msg": "🦂 El Escorpión rompió el balance en v0.2.0\n\n\"Invicto. 100% winrate. 2600 victorias.\nLos desarrolladores están trabajando en un nerf.\"\n\n— Ramazzottius, bostezando"})
	
	# Video 2
	var videos_v2 = [
		"res://video/video Trailer torneo 2.ogv",
		"res://video/video Trailer torneo 2.mp4",
	]
	for v in videos_v2:
		if FileAccess.file_exists(v):
			_video_queue.append({"tipo": "video", "path": v})
			break
	
	_play_next_in_queue()

func _play_next_in_queue() -> void:
	if _video_queue.is_empty():
		_on_intro_finished()
		return
	
	var item = _video_queue.pop_front()
	
	if item["tipo"] == "video":
		_current_video_player = VideoStreamPlayer.new()
		_current_video_player.name = "IntroVideo"
		# Cargar OGV directamente con VideoStreamTheora (no requiere reimportar)
		var vpath = item["path"] as String
		if vpath.ends_with(".ogv"):
			var stream = VideoStreamTheora.new()
			stream.file = vpath
			_current_video_player.stream = stream
		else:
			_current_video_player.stream = load(vpath)
		_current_video_player.anchor_right = 1.0
		_current_video_player.anchor_bottom = 1.0
		_current_video_player.expand = true
		_current_video_player.finished.connect(_on_video_piece_finished)
		add_child(_current_video_player)
		_current_video_player.play()
	elif item["tipo"] == "texto":
		var panel = ColorRect.new()
		panel.name = "IntroVideo"
		panel.anchor_right = 1.0
		panel.anchor_bottom = 1.0
		panel.color = Color(0.02, 0.02, 0.04, 1)
		add_child(panel)
		
		var label = Label.new()
		label.text = item["msg"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_left = 0.1
		label.anchor_top = 0.2
		label.anchor_right = 0.9
		label.anchor_bottom = 0.8
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		panel.add_child(label)
		
		# Auto-avanzar después de 4 segundos
		get_tree().create_timer(4.0).timeout.connect(_on_video_piece_finished)

func _on_video_piece_finished() -> void:
	var old = get_node_or_null("IntroVideo")
	if old: old.queue_free()
	_play_next_in_queue()

func _on_intro_finished() -> void:
	_intro_playing = false
	# Limpiar video
	var video = get_node_or_null("IntroVideo")
	if video: video.queue_free()
	var skip = get_node_or_null("SkipLabel")
	if skip: skip.queue_free()
	_build_menu()

func _unhandled_input(event: InputEvent) -> void:
	if _intro_playing and event is InputEventKey and event.pressed:
		_on_intro_finished()

func _build_menu() -> void:
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
	GameManager.reset()
	get_tree().change_scene_to_file("res://creacion.tscn")

func _cargar_partida() -> void:
	# Marcar que debe cargar al iniciar
	SaveSystem.set_meta("cargar_al_iniciar", true)
	get_tree().change_scene_to_file("res://main.tscn")

func _salir() -> void:
	get_tree().quit()
