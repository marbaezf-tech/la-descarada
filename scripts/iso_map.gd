extends Node2D
## IsoMap — Mapa isométrico generado por código
## Tiles: 0=vacío 1=piso 2=pared 3=acento 4=peligro
## Puertas: 5=norte 6=sur 7=este 8=oeste

const TILE_W := 64
const TILE_H := 32
const PARED_H := 20

# Mapa del Laboratorio con 4 puertas
const MAPA := [
	[2, 2, 2, 2, 5, 2, 2, 2, 2, 2, 2, 2],  # fila 0  — puerta norte col 4
	[2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
	[2, 1, 2, 2, 1, 1, 1, 1, 2, 1, 1, 2],
	[2, 1, 2, 1, 1, 3, 1, 1, 2, 1, 1, 2],
	[2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2],
	[2, 1, 1, 1, 2, 1, 4, 1, 1, 1, 1, 2],
	[2, 1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 2],
	[2, 1, 1, 1, 1, 1, 1, 3, 1, 2, 1, 2],
	[2, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2],
	[2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 2],
	[8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7],  # fila 10 — oeste col 0, este col 11
	[2, 2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2],  # fila 11 — puerta sur col 5
]

# Destinos de cada tipo de puerta
const DESTINOS := {5: "norte", 6: "sur", 7: "este", 8: "oeste"}
const LABELS   := {5: "⬆️ Azotea", 6: "⬇️ Sótano", 7: "➡️ Pasillo", 8: "⬅️ Máquinas"}

const C_PISO    := [Color(0.14,0.17,0.19), Color(0.09,0.11,0.13), Color(0.07,0.09,0.11)]
const C_PARED   := [Color(0.24,0.30,0.26), Color(0.15,0.19,0.17), Color(0.10,0.13,0.11)]
const C_ACENTO  := [Color(0.10,0.45,0.28), Color(0.07,0.28,0.18), Color(0.05,0.20,0.13)]
const C_PELIGRO := [Color(0.45,0.12,0.09), Color(0.28,0.08,0.06), Color(0.20,0.06,0.04)]
const C_PUERTA  := [Color(0.55,0.40,0.10), Color(0.35,0.25,0.06), Color(0.25,0.18,0.04)]

var _offset := Vector2.ZERO

func _ready() -> void:
	z_as_relative = false
	_calcular_offset()
	_generar()

func _calcular_offset() -> void:
	var filas := MAPA.size()
	var cols  := MAPA[0].size()
	var iso_cx := _to_iso(cols / 2, filas / 2)
	_offset = Vector2(320.0 - iso_cx.x, 160.0 - iso_cx.y)

func _generar() -> void:
	var filas := MAPA.size()
	var cols  := MAPA[0].size()
	for gy in range(filas):
		for gx in range(cols):
			var v: int = MAPA[gy][gx]
			if v == 0: continue
			var es_pared := (v == 2)
			var c: Array = _colores(v)
			var pos := _to_iso(gx, gy) + _offset
			var z := (gx + gy) * 2 + (1 if es_pared else 0)
			_crear_tile(pos, c[0], c[1], c[2], es_pared, z)
			if v >= 5:
				var lbl := Label.new()
				lbl.text = LABELS.get(v, "🚪") as String
				lbl.position = pos + Vector2(-28, -18)
				lbl.z_as_relative = false
				lbl.z_index = z + 4
				lbl.add_theme_font_size_override("font_size", 8)
				lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
				add_child(lbl)

func _colores(v: int) -> Array:
	match v:
		1: return C_PISO
		2: return C_PARED
		3: return C_ACENTO
		4: return C_PELIGRO
		_: return C_PUERTA

func _to_iso(gx: int, gy: int) -> Vector2:
	return Vector2((gx - gy) * (TILE_W / 2.0), (gx + gy) * (TILE_H / 2.0))

func get_spawn_pos(gx: int, gy: int) -> Vector2:
	return _to_iso(gx, gy) + _offset

func get_tile_pos(gx: int, gy: int) -> Vector2:
	return _to_iso(gx, gy) + _offset

func get_posicion_tile(gx: int, gy: int) -> Vector2:
	return _to_iso(gx, gy) + _offset

## Spawn según de dónde viene el jugador (puerta opuesta)
func get_spawn_desde(desde: String) -> Vector2:
	var opuesto: String = {"norte":"sur","sur":"norte","este":"oeste","oeste":"este"}.get(desde, "")
	var tile_v: int = {"norte":5,"sur":6,"este":7,"oeste":8}.get(opuesto, 0)
	var filas := MAPA.size()
	var cols  := MAPA[0].size()
	for gy in range(filas):
		for gx in range(cols):
			if MAPA[gy][gx] == tile_v:
				# Spawn 1 tile adentro de la puerta
				var dx := 0; var dy := 0
				match opuesto:
					"norte": dy = 1
					"sur":   dy = -1
					"este":  dx = -1
					"oeste": dx = 1
				return get_tile_pos(gx + dx, gy + dy)
	return get_tile_pos(4, 4)

func pantalla_a_grid(world_pos: Vector2) -> Vector2i:
	var local := world_pos - _offset
	var gx := (local.x / (TILE_W / 2.0) + local.y / (TILE_H / 2.0)) / 2.0
	var gy := (local.y / (TILE_H / 2.0) - local.x / (TILE_W / 2.0)) / 2.0
	return Vector2i(int(round(gx)), int(round(gy)))

func es_caminable_pos(world_pos: Vector2) -> bool:
	var g := pantalla_a_grid(world_pos)
	return _es_caminable_grid(g.x, g.y)

func _es_caminable_grid(gx: int, gy: int) -> bool:
	if gy < 0 or gy >= MAPA.size(): return false
	if gx < 0 or gx >= MAPA[gy].size(): return false
	var v: int = MAPA[gy][gx]
	return v != 0 and v != 2

func es_puerta(world_pos: Vector2) -> String:
	var g := pantalla_a_grid(world_pos)
	if g.y < 0 or g.y >= MAPA.size(): return ""
	if g.x < 0 or g.x >= MAPA[g.y].size(): return ""
	var v: int = MAPA[g.y][g.x]
	return DESTINOS.get(v, "") as String

func get_z_for_pos(world_pos: Vector2) -> int:
	var local := world_pos - _offset
	var sum_grid := local.y / (TILE_H / 2.0)
	return int(sum_grid) * 2 + 1

func _crear_tile(pos: Vector2, ct: Color, ci: Color, cd: Color, pared: bool, z: int) -> void:
	var img := _dibujar(ct, ci, cd, pared)
	var tex := ImageTexture.create_from_image(img)
	var sp  := Sprite2D.new()
	sp.texture = tex; sp.position = pos
	sp.centered = false; sp.offset = Vector2(-TILE_W / 2.0, 0.0)
	sp.z_index = z
	add_child(sp)

func _dibujar(ct: Color, ci: Color, cd: Color, pared: bool) -> Image:
	var h := TILE_H + (PARED_H if pared else 0)
	var img := Image.create(TILE_W, h, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for py in range(TILE_H):
		var t := float(py) / float(TILE_H - 1)
		var hw := int((0.5 - abs(t - 0.5)) * 2.0 * (TILE_W / 2.0))
		var cx := TILE_W / 2
		for px in range(cx - hw, cx + hw + 1):
			if px < 0 or px >= TILE_W: continue
			img.set_pixel(px, py, ct.lightened(0.04 * (1.0 - t)))
	if not pared: return img
	for py in range(PARED_H):
		var t := float(py) / float(PARED_H)
		var x0 := int(t * (TILE_W / 2.0))
		for px in range(x0, TILE_W / 2 + 1):
			img.set_pixel(px, TILE_H + py, ci.darkened(0.1 * t))
	for py in range(PARED_H):
		var t := float(py) / float(PARED_H)
		var x1 := TILE_W - int(t * (TILE_W / 2.0))
		for px in range(TILE_W / 2, x1):
			if px >= TILE_W: continue
			img.set_pixel(px, TILE_H + py, cd.darkened(0.18 * t))
	return img
