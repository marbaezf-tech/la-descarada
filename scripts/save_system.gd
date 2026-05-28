extends Node
## SaveSystem — Guardar y cargar progreso
## Tecla F5 para guardar, F9 para cargar

const SAVE_PATH: String = "user://save_data.json"

func guardar() -> void:
	var data: Dictionary = {
		"nivel": GameManager.nivel,
		"experiencia": GameManager.experiencia,
		"turgencia_actual": GameManager.turgencia_actual,
		"turgencia_max": GameManager.turgencia_max,
		"hemolinfa_actual": GameManager.hemolinfa_actual,
		"hemolinfa_max": GameManager.hemolinfa_max,
		"esencia": GameManager.esencia,
		"recurso_taxon": GameManager.recurso_taxon,
		"inventario": GameManager.inventario,
		"reputacion": GameManager.reputacion,
		"zona_actual": GameManager.zona_actual,
		"zonas_descubiertas": GameManager.zonas_descubiertas,
		"taxon_actual": GameManager.taxon_actual,
		"nombre_plaga": GameManager.nombre_plaga,
		"stats": GameManager.stats,
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("💾 Partida guardada.")
	_mostrar_notificacion("💾 Conquistas registradas")

func cargar() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("❌ No hay partida guardada.")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()
	
	if result != OK:
		print("❌ Error al cargar partida.")
		return false
	
	var data: Dictionary = json.data
	
	GameManager.nivel = int(data.get("nivel", 1))
	GameManager.experiencia = float(data.get("experiencia", 0))
	GameManager.turgencia_actual = float(data.get("turgencia_actual", 100))
	GameManager.turgencia_max = float(data.get("turgencia_max", 100))
	GameManager.hemolinfa_actual = float(data.get("hemolinfa_actual", 50))
	GameManager.hemolinfa_max = float(data.get("hemolinfa_max", 50))
	GameManager.esencia = float(data.get("esencia", 100))
	GameManager.recurso_taxon = float(data.get("recurso_taxon", 50))
	GameManager.inventario = data.get("inventario", [])
	GameManager.reputacion = data.get("reputacion", {"La Colmena": 0, "El Enjambre Negro": 0, "Los Sueltos": 0, "Los Parásitos Libres": 0})
	GameManager.zona_actual = data.get("zona_actual", "El Laboratorio")
	GameManager.zonas_descubiertas = data.get("zonas_descubiertas", [])
	GameManager.nombre_plaga = data.get("nombre_plaga", "Jugador")
	GameManager.stats = data.get("stats", {})
	
	# Emitir señales para actualizar HUD
	GameManager.turgencia_changed.emit(GameManager.turgencia_actual, GameManager.turgencia_max)
	GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
	GameManager.esencia_changed.emit(GameManager.esencia)
	
	print("📂 Partida cargada. Nivel %d. Bienvenido de vuelta." % GameManager.nivel)
	_mostrar_notificacion("📂 Conquista cargada — Nv.%d" % GameManager.nivel)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			guardar()
		elif event.keycode == KEY_F9:
			cargar()

func _mostrar_notificacion(texto: String) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 50
	
	var label = Label.new()
	label.text = texto
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.offset_left = -220
	label.offset_right = -10
	label.offset_top = 10
	label.offset_bottom = 35
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.5))
	canvas.add_child(label)
	
	get_tree().current_scene.add_child(canvas)
	
	# Desaparecer después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	canvas.queue_free()
