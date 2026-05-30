extends Node2D
## Main — Construye toda la escena por código
## Plaga: La Descarada — Sistema de zonas en cruz

const ZONAS := {
	"laboratorio": {
		"mapa":   "res://scripts/iso_map.gd",
		"titulo": "🧪 EL LABORATORIO — Territorio Ganado",
		"color":  Color(0.6, 0.8, 0.6, 1),
		"conexiones": {"norte": "azotea", "sur": "sotano", "este": "pasillo", "oeste": "maquinas"},
		"spots": [
			{"tile": Vector2i(3, 3), "nombre": "Monitor Holográfico Roto", "tipo": "todos",
			 "desc": "Un monitor oxidado de la Era de los Titanes.", "color": Color(0.8, 0.6, 0.1)},
			{"tile": Vector2i(7, 7), "nombre": "Vaso de Agua Estancada",   "tipo": "cazar",
			 "desc": "Donde hay milagros, hay parásitos.",           "color": Color(0.2, 0.4, 0.8)},
			{"tile": Vector2i(2, 8), "nombre": "Cable Expuesto",           "tipo": "explorar",
			 "desc": "El cobre asoma como un hueso roto.",           "color": Color(0.9, 0.3, 0.1)},
		],
	},
	"azotea": {
		"mapa":   "res://scripts/mapa_azotea.gd",
		"titulo": "🌫️ LA AZOTEA — Territorio Expuesto",
		"color":  Color(0.6, 0.7, 0.9, 1),
		"conexiones": {"sur": "laboratorio"},
		"spots": [
			{"tile": Vector2i(4, 2), "nombre": "Antena de Radio", "tipo": "explorar",
			 "desc": "Alguien sigue transmitiendo.",               "color": Color(0.4, 0.6, 0.9)},
			{"tile": Vector2i(2, 6), "nombre": "Caja de Agua",    "tipo": "cazar",
			 "desc": "Agua de lluvia acumulada. Tibia y sospechosa.", "color": Color(0.3, 0.5, 0.7)},
		],
	},
	"sotano": {
		"mapa":   "res://scripts/mapa_sotano.gd",
		"titulo": "🍄 EL SÓTANO — Territorio Infectado",
		"color":  Color(0.3, 0.7, 0.4, 1),
		"conexiones": {"norte": "laboratorio"},
		"spots": [
			{"tile": Vector2i(3, 2), "nombre": "Colonia de Hongos",  "tipo": "cazar",
			 "desc": "Hermosos. Letales. Adictivos.",                 "color": Color(0.2, 0.8, 0.4)},
			{"tile": Vector2i(6, 6), "nombre": "Tubería de Drenaje", "tipo": "explorar",
			 "desc": "Huele a historia.",                             "color": Color(0.4, 0.3, 0.2)},
		],
	},
	"pasillo": {
		"mapa":   "res://scripts/mapa_pasillo.gd",
		"titulo": "🏚️ EL PASILLO — Territorio Hostil",
		"color":  Color(0.8, 0.6, 0.4, 1),
		"conexiones": {"oeste": "laboratorio"},
		"spots": [
			{"tile": Vector2i(4, 3), "nombre": "Tubería Rota",     "tipo": "explorar",
			 "desc": "Huele a óxido y a algo peor.",                "color": Color(0.3, 0.5, 0.7)},
			{"tile": Vector2i(2, 7), "nombre": "Caja de Fusibles", "tipo": "todos",
			 "desc": "Alguien lo saboteó desde adentro.",           "color": Color(0.7, 0.6, 0.1)},
		],
	},
	"maquinas": {
		"mapa":   "res://scripts/mapa_maquinas.gd",
		"titulo": "⚙️ SALA DE MÁQUINAS — Territorio Industrial",
		"color":  Color(0.9, 0.6, 0.3, 1),
		"conexiones": {"este": "laboratorio"},
		"spots": [
			{"tile": Vector2i(4, 4), "nombre": "Panel de Control",  "tipo": "todos",
			 "desc": "Botones que nadie debería presionar.",         "color": Color(0.8, 0.5, 0.1)},
			{"tile": Vector2i(2, 8), "nombre": "Caldera Principal",  "tipo": "explorar",
			 "desc": "El calor aquí es casi agradable. Casi.",       "color": Color(0.9, 0.2, 0.1)},
		],
	},
}

var _zona_actual: String = "laboratorio"
var _en_transicion: bool = false
var _inventario_abierto: bool = false
var _bestiario_abierto: bool = false

# ── Inicialización ──────────────────────────────────────────────────────────
func _ready() -> void:
	GameManager.inicializar_plaga(GameManager.Taxon.ZANCUDO, "Jugador")

	if SaveSystem.has_meta("cargar_al_iniciar"):
		SaveSystem.remove_meta("cargar_al_iniciar")
		SaveSystem.cargar()

	# Determinar zona de inicio según zona_origen guardada
	var zona_inicio := "laboratorio"
	if GameManager.zona_origen != "":
		zona_inicio = GameManager.zona_origen
		GameManager.zona_origen = ""

	_cargar_zona(zona_inicio)

# ── Carga genérica de zona ──────────────────────────────────────────────────
func _cargar_zona(zona_key: String, desde: String = "") -> void:
	if not ZONAS.has(zona_key):
		push_error("Zona desconocida: " + zona_key)
		return

	_zona_actual = zona_key
	GameManager.zona_actual = ZONAS[zona_key]["titulo"]
	_actualizar_minimapa()

	# Fondo grande (cubre todo el mundo visible con cámara)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06)
	bg.position = Vector2(-4000, -4000)
	bg.size = Vector2(8000, 8000)
	add_child(bg)

	# Mapa
	var mapa := Node2D.new()
	mapa.name = "IsoMap"
	mapa.add_to_group("iso_map")
	mapa.set_script(load(ZONAS[zona_key]["mapa"]))
	add_child(mapa)
	await get_tree().process_frame  # esperar a que _ready() del mapa corra

	# Título en CanvasLayer (no se mueve con la cámara)
	var ui := CanvasLayer.new()
	ui.name = "UIZona"
	ui.layer = 5
	add_child(ui)
	var title := Label.new()
	title.name = "TituloZona"
	title.position = Vector2(10, 5)
	title.text = ZONAS[zona_key]["titulo"]
	title.add_theme_color_override("font_color", ZONAS[zona_key]["color"])
	ui.add_child(title)

	# Objetivo (solo en laboratorio)
	if zona_key == "laboratorio":
		var objetivo := Label.new()
		objetivo.position = Vector2(350, 5)
		objetivo.text = "🎯 Craftea el Anclaje de Fibra [I]"
		objetivo.add_theme_font_size_override("font_size", 10)
		objetivo.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9, 0.8))
		ui.add_child(objetivo)

	# Player
	_create_player(mapa, desde)

	for spot_data in ZONAS[zona_key]["spots"]:
		var tile: Vector2i = spot_data["tile"]
		var pos: Vector2 = mapa.get_tile_pos(tile.x, tile.y)
		_create_spot(pos, spot_data["nombre"], spot_data["tipo"], spot_data["desc"], spot_data["color"])

	# HUD (solo si no existe ya)
	if not get_node_or_null("HUD"):
		_create_hud()
		_actualizar_minimapa()

	# Touch controls (solo si no existe ya)
	if not get_node_or_null("TouchControls"):
		var touch := CanvasLayer.new()
		touch.name = "TouchControls"
		touch.set_script(load("res://scripts/touch_controls.gd"))
		add_child(touch)

# ── Transición entre zonas ──────────────────────────────────────────────────
func _on_entrar_zona(destino_raw: String) -> void:
	if _en_transicion: return
	_en_transicion = true

	# Resolver destino usando las conexiones de la zona ACTUAL
	var conexiones_actuales: Dictionary = ZONAS[_zona_actual].get("conexiones", {})
	var zona_destino: String = conexiones_actuales.get(destino_raw, "") as String

	if zona_destino == "" or not ZONAS.has(zona_destino):
		push_error("Destino desconocido desde %s: %s" % [_zona_actual, destino_raw])
		_en_transicion = false
		return

	# Fade out
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.offset_right = 640
	fade.offset_bottom = 360
	fade.z_index = 999
	add_child(fade)

	var tw := create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 1), 0.3)
	await tw.finished

	# Limpiar escena (excepto CanvasLayers: HUD, TouchControls)
	var a_borrar: Array = []
	for child in get_children():
		if child != fade and not child is CanvasLayer:
			a_borrar.append(child)
	for n in a_borrar:
		n.queue_free()
	await get_tree().process_frame

	# Cargar nueva zona — "desde" indica de dónde viene el jugador para spawn correcto
	_cargar_zona(zona_destino, _zona_actual)

	# Reconectar señal del nuevo player
	var new_player := get_tree().get_first_node_in_group("player")
	if new_player and not new_player.entrar_zona.is_connected(_on_entrar_zona):
		new_player.entrar_zona.connect(_on_entrar_zona)

	# Fade in
	var tw2 := create_tween()
	tw2.tween_property(fade, "color", Color(0, 0, 0, 0), 0.3)
	await tw2.finished
	fade.queue_free()
	_en_transicion = false

# ── Crear player ────────────────────────────────────────────────────────────
func _create_player(mapa: Node2D, desde: String = "") -> void:
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # top-down, sin gravedad
	player.set_script(load("res://scripts/player.gd"))

	# Spawn: si viene de otra zona usar get_spawn_desde, sino tile (4,4)
	if desde != "" and mapa.has_method("get_spawn_desde"):
		player.position = mapa.get_spawn_desde(desde)
	elif mapa.has_method("get_posicion_tile"):
		player.position = mapa.get_posicion_tile(4, 4)
	elif mapa.has_method("get_spawn_pos"):
		player.position = mapa.get_spawn_pos(1, 1)
	else:
		player.position = Vector2(320, 180)

	# Sprite
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assets/sprites/zancudo_front.png")
	sprite.scale = Vector2(0.5, 0.5)
	player.add_child(sprite)

	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	col.shape = shape
	player.add_child(col)

	# Interaction area
	var area := Area2D.new()
	area.name = "InteractionArea"
	var area_col := CollisionShape2D.new()
	var area_shape := RectangleShape2D.new()
	area_shape.size = Vector2(36, 36)
	area_col.shape = area_shape
	area.add_child(area_col)
	area.area_entered.connect(player._on_interaction_area_area_entered)
	area.area_exited.connect(player._on_interaction_area_area_exited)
	player.add_child(area)

	add_child(player)
	player.entrar_zona.connect(_on_entrar_zona)

	# Cámara centrada en el player con zoom 2x
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(2.0, 2.0)
	player.add_child(cam)

# ── Crear spot ──────────────────────────────────────────────────────────────
func _create_spot(pos: Vector2, spot_name: String, spot_type: String, desc: String, color: Color) -> void:
	var spot := Node2D.new()
	spot.position = pos
	spot.z_as_relative = false
	spot.z_index = int(pos.y / 8.0) * 2 + 2
	spot.set_script(load("res://scripts/spot.gd"))
	spot.spot_name = spot_name
	spot.spot_type = spot_type
	spot.description = desc

	var area := Area2D.new()
	area.name = "Area2D"
	area.add_to_group("spots")
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	area.add_child(col)
	spot.add_child(area)

	# Visual — imagen real si existe, sino ColorRect
	var img_map := {
		"Monitor Holográfico Roto": "res://assets/sprites/monitorroto.png",
		"Vaso de Agua Estancada":   "res://assets/sprites/vasoaguapodrida.png",
		"Cable Expuesto":           "res://assets/sprites/cableroto.png",
	}
	if img_map.has(spot_name) and ResourceLoader.exists(img_map[spot_name]):
		var spr := Sprite2D.new()
		spr.texture = load(img_map[spot_name])
		spr.scale = Vector2(0.45, 0.45)
		spot.add_child(spr)
	else:
		var visual := ColorRect.new()
		visual.offset_left  = -12
		visual.offset_top   = -12
		visual.offset_right = 12
		visual.offset_bottom= 12
		visual.color = color
		spot.add_child(visual)

	# Indicator
	var indicator := Sprite2D.new()
	indicator.name = "Indicator"
	indicator.position = Vector2(0, -20)
	indicator.modulate = Color(1, 0, 0, 1)
	var ind_tex := PlaceholderTexture2D.new()
	ind_tex.size = Vector2(10, 10)
	indicator.texture = ind_tex
	indicator.visible = false
	spot.add_child(indicator)

	add_child(spot)

# ── HUD ─────────────────────────────────────────────────────────────────────
func _create_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	hud.set_script(load("res://scripts/hud.gd"))

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.offset_left   = 5
	panel.offset_top    = 30
	panel.offset_right  = 135
	panel.offset_bottom = 110
	hud.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)

	for cfg in [
		["TurgenciaLabel",  "🛡️ Turgencia: --",   "TurgenciaBar",  100, 9],
		["HemolinfaLabel",  "💧 Hemolinfa: --",    "HemolinfaBar",   50, 9],
		["EsenciaLabel",    "🍄 Esencia: --",       "EsenciaBar",    100, 9],
		["ExpLabel",        "⭐ Nv.1 — EXP: 0/20", "ExpBar",         20, 9],
	]:
		var lbl := Label.new()
		lbl.name = cfg[0]
		lbl.text = cfg[1]
		lbl.add_theme_font_size_override("font_size", cfg[4])
		vbox.add_child(lbl)
		var bar := ProgressBar.new()
		bar.name = cfg[2]
		bar.custom_minimum_size = Vector2(0, 8 if cfg[2] != "ExpBar" else 6)
		bar.max_value = cfg[3]
		bar.value = cfg[3]
		bar.show_percentage = false
		vbox.add_child(bar)

	# ── Minimapa ──────────────────────────────────────────────────────────
	var mini := _crear_minimapa()
	mini.name = "Minimapa"
	hud.add_child(mini)

	add_child(hud)

func _crear_minimapa() -> Control:
	# Contenedor del minimapa — esquina superior derecha
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	c.offset_left  = -72
	c.offset_top   = 4
	c.offset_right = -4
	c.offset_bottom= 86

	# Fondo semitransparente
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)

	# Layout de la cruz: 5 celdas (norte, sur, este, oeste, centro)
	# Cada celda: 20×20 px, separadas 2px
	# Centro en (34, 34) del control 68×68
	var celdas := {
		"laboratorio": Vector2(24, 24),  # centro
		"azotea":      Vector2(24,  2),  # norte
		"sotano":      Vector2(24, 46),  # sur
		"pasillo":     Vector2(46, 24),  # este
		"maquinas":    Vector2( 2, 24),  # oeste
	}
	var nombres := {
		"laboratorio": "LAB", "azotea": "AZO",
		"sotano": "SOT", "pasillo": "PAS", "maquinas": "MAQ"
	}
	var colores_zona := {
		"laboratorio": Color(0.3, 0.7, 0.3),
		"azotea":      Color(0.4, 0.6, 0.9),
		"sotano":      Color(0.2, 0.6, 0.3),
		"pasillo":     Color(0.7, 0.5, 0.3),
		"maquinas":    Color(0.8, 0.5, 0.2),
	}

	for zona_id in celdas:
		var rect := ColorRect.new()
		rect.name = "Mini_" + zona_id
		rect.position = celdas[zona_id]
		rect.size = Vector2(20, 20)
		rect.color = colores_zona[zona_id].darkened(0.5)
		c.add_child(rect)

		var lbl := Label.new()
		lbl.name = "MiniLbl_" + zona_id
		lbl.position = celdas[zona_id] + Vector2(1, 4)
		lbl.size = Vector2(18, 12)
		lbl.text = nombres[zona_id]
		lbl.add_theme_font_size_override("font_size", 6)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		c.add_child(lbl)

	# Líneas de conexión (norte-sur y este-oeste)
	var linea_v := ColorRect.new()
	linea_v.name = "LineaV"
	linea_v.position = Vector2(32, 22)
	linea_v.size = Vector2(4, 24)
	linea_v.color = Color(0.4, 0.4, 0.4, 0.6)
	c.add_child(linea_v)

	var linea_h := ColorRect.new()
	linea_h.name = "LineaH"
	linea_h.position = Vector2(22, 32)
	linea_h.size = Vector2(24, 4)
	linea_h.color = Color(0.4, 0.4, 0.4, 0.6)
	c.add_child(linea_h)

	# Punto del jugador (se actualiza en _actualizar_minimapa)
	var punto := ColorRect.new()
	punto.name = "PuntoJugador"
	punto.size = Vector2(6, 6)
	punto.color = Color(1, 1, 0)
	c.add_child(punto)

	# Label de zona actual bajo el minimapa
	var lbl_zona := Label.new()
	lbl_zona.name = "LblZona"
	lbl_zona.position = Vector2(0, 70)
	lbl_zona.size = Vector2(68, 12)
	lbl_zona.text = "Laboratorio"
	lbl_zona.add_theme_font_size_override("font_size", 7)
	lbl_zona.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	lbl_zona.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(lbl_zona)

	return c

func _actualizar_minimapa() -> void:
	var hud := get_node_or_null("HUD")
	if not hud: return
	var mini := hud.get_node_or_null("Minimapa")
	if not mini: return

	var colores_zona := {
		"laboratorio": Color(0.3, 0.7, 0.3),
		"azotea":      Color(0.4, 0.6, 0.9),
		"sotano":      Color(0.2, 0.6, 0.3),
		"pasillo":     Color(0.7, 0.5, 0.3),
		"maquinas":    Color(0.8, 0.5, 0.2),
	}
	var celdas_pos := {
		"laboratorio": Vector2(24, 24), "azotea": Vector2(24, 2),
		"sotano": Vector2(24, 46), "pasillo": Vector2(46, 24), "maquinas": Vector2(2, 24),
	}

	for zona_id in colores_zona:
		var rect := mini.get_node_or_null("Mini_" + zona_id)
		if rect:
			if zona_id == _zona_actual:
				rect.color = colores_zona[zona_id]  # brillante = zona actual
			else:
				rect.color = colores_zona[zona_id].darkened(0.5)  # oscuro = otras

	# Mover punto del jugador al centro de la celda actual
	var punto := mini.get_node_or_null("PuntoJugador")
	if punto and celdas_pos.has(_zona_actual):
		punto.position = celdas_pos[_zona_actual] + Vector2(7, 7)

	# Actualizar label de zona
	var nombres_zona := {
		"laboratorio": "Laboratorio", "azotea": "La Azotea",
		"sotano": "El Sótano", "pasillo": "El Pasillo", "maquinas": "Sala Máquinas"
	}
	var lbl_zona := mini.get_node_or_null("LblZona")
	if lbl_zona:
		lbl_zona.text = nombres_zona.get(_zona_actual, _zona_actual) as String

# ── Input ────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario") and not _inventario_abierto and not _bestiario_abierto:
		_inventario_abierto = true
		var inv := CanvasLayer.new()
		inv.set_script(load("res://scripts/inventario_ui.gd"))
		inv.tree_exited.connect(func(): _inventario_abierto = false)
		add_child(inv)
	elif event.is_action_pressed("bestiario") and not _bestiario_abierto and not _inventario_abierto:
		_bestiario_abierto = true
		var best := CanvasLayer.new()
		best.set_script(load("res://scripts/bestiario_ui.gd"))
		best.tree_exited.connect(func(): _bestiario_abierto = false)
		add_child(best)
