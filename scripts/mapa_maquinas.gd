extends Node2D
## Mapa: Sala de Máquinas — Industrial, caliente
## Solo conexión: Este → Laboratorio

const TILE_W := 64
const TILE_H := 32
const PARED_H := 20

# tile 7 = puerta este (al Laboratorio)
const MAPA := [
	[2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
	[2, 1, 1, 1, 1, 1, 1, 1, 1, 2],
	[2, 1, 4, 4, 1, 1, 4, 4, 1, 2],   # peligro: calderas
	[2, 1, 4, 4, 1, 1, 4, 4, 1, 2],
	[2, 1, 1, 1, 3, 3, 1, 1, 1, 2],   # acento: engranajes
	[2, 1, 1, 2, 1, 1, 2, 1, 1, 2],
	[2, 1, 1, 2, 3, 1, 2, 1, 1, 2],   # acento: panel de control
	[2, 1, 1, 1, 1, 1, 1, 1, 1, 2],
	[2, 1, 4, 4, 1, 1, 4, 4, 1, 2],   # peligro: más calderas
	[2, 1, 1, 1, 1, 1, 1, 1, 1, 7],   # fila 9 col 9 — puerta este
]

const DESTINOS := {7: "este"}
const LABELS   := {7: "➡️ Laboratorio"}

# Colores naranja-rojo: metal caliente, óxido
const C_PISO    := [Color(0.18,0.14,0.10), Color(0.12,0.09,0.06), Color(0.08,0.06,0.04)]
const C_PARED   := [Color(0.28,0.20,0.14), Color(0.18,0.13,0.09), Color(0.12,0.09,0.06)]
const C_ACENTO  := [Color(0.70,0.45,0.10), Color(0.45,0.28,0.06), Color(0.32,0.20,0.04)]
const C_PELIGRO := [Color(0.65,0.20,0.05), Color(0.42,0.13,0.03), Color(0.30,0.09,0.02)]
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
			if LABELS.has(v):
				var lbl := Label.new()
				lbl.text = LABELS[v]
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

func get_tile_pos(gx: int, gy: int) -> Vector2:
	return _to_iso(gx, gy) + _offset

func get_posicion_tile(gx: int, gy: int) -> Vector2:
	return _to_iso(gx, gy) + _offset

func get_spawn_pos(gx: int, gy: int) -> Vector2:
	return _to_iso(gx, gy) + _offset

func get_spawn_desde(_desde: String) -> Vector2:
	return get_tile_pos(7, 5)

func pantalla_a_grid(world_pos: Vector2) -> Vector2i:
	var local := world_pos - _offset
	var gx := (local.x / (TILE_W / 2.0) + local.y / (TILE_H / 2.0)) / 2.0
	var gy := (local.y / (TILE_H / 2.0) - local.x / (TILE_W / 2.0)) / 2.0
	return Vector2i(int(round(gx)), int(round(gy)))

func es_caminable_pos(world_pos: Vector2) -> bool:
	var g := pantalla_a_grid(world_pos)
	if g.y < 0 or g.y >= MAPA.size(): return false
	if g.x < 0 or g.x >= MAPA[g.y].size(): return false
	var v: int = MAPA[g.y][g.x]
	return v != 0 and v != 2

func es_puerta(world_pos: Vector2) -> String:
	var g := pantalla_a_grid(world_pos)
	if g.y < 0 or g.y >= MAPA.size(): return ""
	if g.x < 0 or g.x >= MAPA[g.y].size(): return ""
	var v: int = MAPA[g.y][g.x]
	return DESTINOS.get(v, "") as String

func get_z_for_pos(world_pos: Vector2) -> int:
	var local := world_pos - _offset
	return int(local.y / (TILE_H / 2.0)) * 2 + 1

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
