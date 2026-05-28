extends CanvasLayer
## InventarioUI — Pantalla de inventario (tecla I)

var panel: PanelContainer
var items_container: VBoxContainer
var title_label: Label
var close_btn: Button
var _confirm_popup: PanelContainer = null

func _ready() -> void:
	layer = 30
	
	panel = PanelContainer.new()
	panel.anchor_left = 0.1
	panel.anchor_top = 0.05
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.95
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	title_label = Label.new()
	title_label.text = "🎒 ARSENAL DE LA PLAGA — Nivel %d | EXP: %.0f/%d" % [GameManager.nivel, GameManager.experiencia, GameManager.nivel * 20]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	close_btn = Button.new()
	close_btn.text = "✖"
	close_btn.pressed.connect(_cerrar)
	header.add_child(close_btn)
	
	vbox.add_child(HSeparator.new())
	
	# Scroll container para items
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_container)
	
	_refresh_items()

func _refresh_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	
	# Sección de equipo actual
	var equip_title = Label.new()
	equip_title.text = "⚔️ EQUIPO ACTUAL"
	equip_title.add_theme_font_size_override("font_size", 11)
	equip_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	items_container.add_child(equip_title)
	
	var arma_val = GameManager.stats.get("arma_equipada", 0)
	var armadura_val = GameManager.stats.get("armadura_equipada", 0)
	
	var equip_arma = Label.new()
	equip_arma.text = "  🗡️ Arma: +%d daño" % arma_val if arma_val > 0 else "  🗡️ Arma: (ninguna)"
	equip_arma.add_theme_font_size_override("font_size", 10)
	equip_arma.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if arma_val == 0 else Color(0.9, 0.9, 0.9))
	items_container.add_child(equip_arma)
	
	var equip_armor = Label.new()
	equip_armor.text = "  🛡️ Armadura: +%d defensa" % armadura_val if armadura_val > 0 else "  🛡️ Armadura: (ninguna)"
	equip_armor.add_theme_font_size_override("font_size", 10)
	equip_armor.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if armadura_val == 0 else Color(0.9, 0.9, 0.9))
	items_container.add_child(equip_armor)
	
	items_container.add_child(HSeparator.new())
	
	# Items del inventario
	if GameManager.inventario.is_empty():
		var empty = Label.new()
		empty.text = "Inventario vacío. Sal a cobrar lo que te deben."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		items_container.add_child(empty)
		return
	
	for i in range(GameManager.inventario.size()):
		var item = GameManager.inventario[i]
		var row = HBoxContainer.new()
		
		var label = Label.new()
		label.text = "%s %s [%s]" % [item.get("emoji", "?"), item.get("nombre", "???"), item.get("tier", "?").to_upper()]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 11)
		row.add_child(label)
		
		var tipo = item.get("tipo", "")
		
		# Botón Usar (consumibles) — con confirmación
		if tipo == "consumible":
			var btn_usar = Button.new()
			btn_usar.text = "Usar"
			btn_usar.add_theme_font_size_override("font_size", 9)
			btn_usar.pressed.connect(_confirmar_usar.bind(i))
			row.add_child(btn_usar)
		
		# Botón Equipar (armas y armaduras)
		if tipo in ["arma", "arma_cc", "arma_dist", "armadura"]:
			var btn_equip = Button.new()
			var is_equipped = _is_item_equipped(item)
			if is_equipped:
				btn_equip.text = "✅ Equipado"
				btn_equip.add_theme_font_size_override("font_size", 9)
				btn_equip.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
				btn_equip.disabled = true
			else:
				btn_equip.text = "Equipar"
				btn_equip.add_theme_font_size_override("font_size", 9)
				btn_equip.pressed.connect(_confirmar_equipar.bind(i))
			row.add_child(btn_equip)
		
		# Botón Tirar
		var btn_tirar = Button.new()
		btn_tirar.text = "✖"
		btn_tirar.add_theme_font_size_override("font_size", 9)
		btn_tirar.pressed.connect(_tirar_item.bind(i))
		row.add_child(btn_tirar)
		
		items_container.add_child(row)
	
	# Footer
	var footer = Label.new()
	footer.text = "\n📦 %d/%d items" % [GameManager.inventario.size(), GameManager.INVENTARIO_MAX]
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	items_container.add_child(footer)
	
	# Crafteo
	items_container.add_child(HSeparator.new())
	var craft_title = Label.new()
	craft_title.text = "🔧 CRAFTEO — Anclaje de Fibra"
	craft_title.add_theme_font_size_override("font_size", 11)
	craft_title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9))
	items_container.add_child(craft_title)
	
	var sedas = _contar_material("Seda de Fibra de Carbono")
	var cobres = _contar_material("Nervio de Cobre")
	var hemo_ok = GameManager.hemolinfa_actual >= 15.0
	
	var req_label = Label.new()
	req_label.text = "  🕸️ Seda: %d/3  |  ⚡ Cobre: %d/1  |  💧 Hemolinfa: %s" % [sedas, cobres, "✅" if hemo_ok else "❌ (15)"]
	req_label.add_theme_font_size_override("font_size", 9)
	items_container.add_child(req_label)
	
	var btn_craft = Button.new()
	btn_craft.text = "🔧 Craftear Anclaje de Fibra (FIN DE DEMO)"
	btn_craft.add_theme_font_size_override("font_size", 10)
	btn_craft.disabled = not (sedas >= 3 and cobres >= 1 and hemo_ok)
	btn_craft.pressed.connect(_craftear_anclaje)
	items_container.add_child(btn_craft)
	
	# Fusión de items repetidos
	items_container.add_child(HSeparator.new())
	var fusion_title = Label.new()
	fusion_title.text = "⚗️ FUSIÓN — Combinar items repetidos"
	fusion_title.add_theme_font_size_override("font_size", 11)
	fusion_title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	items_container.add_child(fusion_title)
	
	var fusion_found = false
	for recipe in FUSION_RECIPES:
		var count = _contar_material(recipe["input"])
		if count >= recipe["cantidad"]:
			fusion_found = true
			var btn_fusion = Button.new()
			btn_fusion.text = "⚗️ %dx %s → %s (+%d)" % [recipe["cantidad"], recipe["input"], recipe["output"]["nombre"], recipe["output"].get("bonus_ataque", recipe["output"].get("bonus_defensa", 0))]
			btn_fusion.add_theme_font_size_override("font_size", 9)
			btn_fusion.pressed.connect(_fusionar.bind(recipe))
			items_container.add_child(btn_fusion)
		elif count >= 1:
			var progress_label = Label.new()
			progress_label.text = "  %s %s: %d/%d" % [recipe["output"].get("emoji", "⚗️"), recipe["input"], count, recipe["cantidad"]]
			progress_label.add_theme_font_size_override("font_size", 9)
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			items_container.add_child(progress_label)
	
	if not fusion_found:
		var no_fusion = Label.new()
		no_fusion.text = "  Junta items repetidos para fusionarlos en algo mejor."
		no_fusion.add_theme_font_size_override("font_size", 9)
		no_fusion.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		items_container.add_child(no_fusion)

func _is_item_equipped(item: Dictionary) -> bool:
	var tipo = item.get("tipo", "")
	var bonus_atk = item.get("bonus_ataque", item.get("valor", 0))
	var bonus_def = item.get("bonus_defensa", item.get("valor", 0))
	if tipo in ["arma", "arma_cc", "arma_dist"]:
		return GameManager.stats.get("arma_equipada", 0) == bonus_atk
	elif tipo == "armadura":
		return GameManager.stats.get("armadura_equipada", 0) == bonus_def
	return false

# === CONFIRMACIONES ===
func _confirmar_usar(index: int) -> void:
	var item = GameManager.inventario[index]
	_show_confirm(
		"¿Usar %s %s?" % [item.get("emoji",""), item.get("nombre","")],
		item.get("desc", ""),
		func(): _usar_item(index)
	)

func _confirmar_equipar(index: int) -> void:
	var item = GameManager.inventario[index]
	var tipo = item.get("tipo", "")
	var slot = "Arma" if tipo in ["arma", "arma_cc", "arma_dist"] else "Armadura"
	var current = GameManager.stats.get("arma_equipada", 0) if slot == "Arma" else GameManager.stats.get("armadura_equipada", 0)
	var msg = "¿Equipar %s %s?" % [item.get("emoji",""), item.get("nombre","")]
	if current > 0:
		msg = "¿Reemplazar %s actual (+%d) por %s?" % [slot, current, item.get("nombre","")]
	_show_confirm(msg, item.get("desc", ""), func(): _equipar_item(index))

func _show_confirm(title: String, desc: String, on_confirm: Callable) -> void:
	if _confirm_popup:
		_confirm_popup.queue_free()
	
	_confirm_popup = PanelContainer.new()
	_confirm_popup.anchor_left = 0.2
	_confirm_popup.anchor_top = 0.35
	_confirm_popup.anchor_right = 0.8
	_confirm_popup.anchor_bottom = 0.65
	add_child(_confirm_popup)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_confirm_popup.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 12)
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(lbl_title)
	
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_font_size_override("font_size", 9)
	lbl_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(lbl_desc)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	var btn_si = Button.new()
	btn_si.text = "✅ Sí"
	btn_si.add_theme_font_size_override("font_size", 11)
	btn_si.pressed.connect(func():
		_confirm_popup.queue_free()
		_confirm_popup = null
		on_confirm.call()
	)
	hbox.add_child(btn_si)
	
	var btn_no = Button.new()
	btn_no.text = "❌ No"
	btn_no.add_theme_font_size_override("font_size", 11)
	btn_no.pressed.connect(func():
		_confirm_popup.queue_free()
		_confirm_popup = null
	)
	hbox.add_child(btn_no)

const FUSION_RECIPES: Array = [
	# === TIER 1 → TIER 2 (items base → items mejorados) ===
	{
		"input": "Espina de Cactus",
		"cantidad": 10,
		"output": {"nombre": "Lanza de Espinas", "emoji": "🌵", "tipo": "arma", "valor": 6, "tier": "raro", "desc": "10 espinas trenzadas. +6 Daño. Duele solo de verla.", "bonus_ataque": 6}
	},
	{
		"input": "Fémur de Grillo",
		"cantidad": 5,
		"output": {"nombre": "Mazo de Huesos", "emoji": "🦴", "tipo": "arma", "valor": 5, "tier": "raro", "desc": "5 fémures atados. +5 Daño. Suena a xilófono de guerra.", "bonus_ataque": 5}
	},
	{
		"input": "Capa de Hoja Seca",
		"cantidad": 8,
		"output": {"nombre": "Manto de Hojarasca", "emoji": "🍂", "tipo": "armadura", "valor": 5, "tier": "raro", "desc": "8 capas comprimidas. +5 Defensa. Cruje al caminar.", "bonus_defensa": 5}
	},
	{
		"input": "Placa de Élitro",
		"cantidad": 4,
		"output": {"nombre": "Coraza de Élitros Blindada", "emoji": "🪲", "tipo": "armadura", "valor": 6, "tier": "epico", "desc": "4 alas de escarabajo soldadas. +6 Defensa. Casi impenetrable.", "bonus_defensa": 6}
	},
	{
		"input": "Hemolinfa Fresca",
		"cantidad": 5,
		"output": {"nombre": "Ampolla de Hemolinfa Pura", "emoji": "🩸", "tipo": "consumible", "valor": 4, "tier": "raro", "desc": "+80 Turgencia. Sangre concentrada.", "efecto": "turgencia", "cantidad": 80}
	},
	{
		"input": "Gota de Miel",
		"cantidad": 5,
		"output": {"nombre": "Jalea Real Concentrada", "emoji": "🍯", "tipo": "consumible", "valor": 4, "tier": "raro", "desc": "+100% Turgencia. Restauración total.", "efecto": "turgencia", "cantidad": 100}
	},
	{
		"input": "Hoja de Menta",
		"cantidad": 5,
		"output": {"nombre": "Bálsamo de Menta Concentrado", "emoji": "🌿", "tipo": "consumible", "valor": 3, "tier": "poco_comun", "desc": "+40 Turgencia + cura veneno.", "efecto": "turgencia", "cantidad": 40}
	},
	# === TIER 2 → TIER 3 (items mejorados → items épicos) ===
	{
		"input": "Lanza de Espinas",
		"cantidad": 3,
		"output": {"nombre": "Tridente del Charco", "emoji": "🔱", "tipo": "arma", "valor": 12, "tier": "epico", "desc": "3 lanzas forjadas en una. +12 Daño. El Charco tiembla.", "bonus_ataque": 12}
	},
	{
		"input": "Mazo de Huesos",
		"cantidad": 3,
		"output": {"nombre": "Martillo de Exoesqueletos", "emoji": "🔨", "tipo": "arma", "valor": 10, "tier": "epico", "desc": "Huesos de 15 grillos. +10 Daño. Aplasta quitina.", "bonus_ataque": 10}
	},
	{
		"input": "Manto de Hojarasca",
		"cantidad": 3,
		"output": {"nombre": "Armadura del Bosque Muerto", "emoji": "🌲", "tipo": "armadura", "valor": 10, "tier": "epico", "desc": "24 capas fosilizadas. +10 Defensa. Eres un tanque.", "bonus_defensa": 10}
	},
	{
		"input": "Coraza de Élitros Blindada",
		"cantidad": 2,
		"output": {"nombre": "Exoesqueleto del Progenitor", "emoji": "👑", "tipo": "armadura", "valor": 14, "tier": "legendario", "desc": "Armadura digna de Arthropleura. +14 Defensa. Inmovible.", "bonus_defensa": 14}
	},
]

func _fusionar(recipe: Dictionary) -> void:
	_remover_material(recipe["input"], recipe["cantidad"])
	var output = recipe["output"].duplicate()
	output["tier"] = output.get("tier", "raro")
	GameManager.agregar_item(output)
	_show_notification("⚗️ ¡Fusión! %s %s creado" % [output.get("emoji",""), output["nombre"]], Color(0.9, 0.6, 0.2))
	_refresh_items()

# === ACCIONES ===
func _usar_item(index: int) -> void:
	var item = GameManager.inventario[index]
	var nombre = item.get("nombre", "")
	var efecto = item.get("efecto", "")
	var cantidad = item.get("cantidad", 0)
	
	match efecto:
		"hemolinfa":
			GameManager.hemolinfa_actual = minf(GameManager.hemolinfa_actual + cantidad, GameManager.hemolinfa_max)
			GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
		"turgencia":
			GameManager.curar(cantidad)
		"buff_total":
			GameManager.stats["torax"] = GameManager.stats.get("torax", 5) + 2
			GameManager.stats["ganglios"] = GameManager.stats.get("ganglios", 5) + 2
			GameManager.curar(cantidad)
		_:
			# Fallback por nombre (items viejos)
			match nombre:
				"Hemolinfa Fresca":
					GameManager.hemolinfa_actual = minf(GameManager.hemolinfa_actual + GameManager.hemolinfa_max * 0.2, GameManager.hemolinfa_max)
					GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
				"Gota de Miel":
					GameManager.curar(GameManager.turgencia_max * 0.3)
				"Hoja de Menta":
					GameManager.curar(GameManager.turgencia_max * 0.1)
				_:
					GameManager.curar(GameManager.turgencia_max * 0.15)
	
	_show_notification("💊 %s usado" % nombre, Color(0.3, 0.8, 1.0))
	GameManager.remover_item(index)
	_refresh_items()

func _equipar_item(index: int) -> void:
	var item = GameManager.inventario[index]
	var tipo = item.get("tipo", "")
	var bonus_atk = item.get("bonus_ataque", item.get("valor", 0))
	var bonus_def = item.get("bonus_defensa", item.get("valor", 0))
	
	if tipo in ["arma", "arma_cc", "arma_dist"]:
		GameManager.stats["arma_equipada"] = bonus_atk
		_show_notification("⚔️ %s equipado (+%d daño)" % [item.get("nombre",""), bonus_atk], Color(0.2, 1.0, 0.4))
	elif tipo == "armadura":
		GameManager.stats["armadura_equipada"] = bonus_def
		_show_notification("🛡️ %s equipado (+%d defensa)" % [item.get("nombre",""), bonus_def], Color(0.2, 1.0, 0.4))
	
	_refresh_items()

func _tirar_item(index: int) -> void:
	var item = GameManager.inventario[index]
	_show_notification("🗑️ %s descartado" % item.get("nombre",""), Color(0.8, 0.3, 0.3))
	GameManager.remover_item(index)
	_refresh_items()

func _show_notification(text: String, color: Color) -> void:
	var notif = Label.new()
	notif.text = text
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 11)
	notif.add_theme_color_override("font_color", color)
	notif.anchor_left = 0.2
	notif.anchor_right = 0.8
	notif.anchor_top = 0.92
	add_child(notif)
	get_tree().create_timer(1.5).timeout.connect(func(): if is_instance_valid(notif): notif.queue_free())

func _cerrar() -> void:
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		_cerrar()

func _contar_material(nombre: String) -> int:
	var count = 0
	for item in GameManager.inventario:
		if item.get("nombre", "") == nombre:
			count += 1
	return count

func _remover_material(nombre: String, cantidad: int) -> void:
	var removed = 0
	var i = GameManager.inventario.size() - 1
	while i >= 0 and removed < cantidad:
		if GameManager.inventario[i].get("nombre", "") == nombre:
			GameManager.inventario.remove_at(i)
			removed += 1
		i -= 1

func _craftear_anclaje() -> void:
	_remover_material("Seda de Fibra de Carbono", 3)
	_remover_material("Nervio de Cobre", 1)
	GameManager.hemolinfa_actual -= 15.0
	GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
	
	# Crear pantalla de fin ANTES de liberar el inventario
	var fin = CanvasLayer.new()
	fin.layer = 50
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0, 0, 0, 0.9)
	fin.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.3
	vbox.anchor_right = 0.5
	vbox.offset_left = -200
	vbox.offset_right = 200
	vbox.add_theme_constant_override("separation", 15)
	fin.add_child(vbox)
	
	var t1 = Label.new()
	t1.text = "🔧 ANCLAJE DE FIBRA CRAFTEADO"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 18)
	t1.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9))
	vbox.add_child(t1)
	
	var t2 = Label.new()
	t2.text = "El Charco se queda atrás.\nLo que viene es peor.\nPero tú ya no eres el mismo insecto que llegó aquí."
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD
	t2.add_theme_font_size_override("font_size", 12)
	vbox.add_child(t2)
	
	var t3 = Label.new()
	t3.text = "\n— FIN DE LA DEMO —\nGracias por jugar Plaga: La Descarada"
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_theme_font_size_override("font_size", 14)
	t3.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	vbox.add_child(t3)
	
	var btn = Button.new()
	btn.text = "Volver al Menú"
	btn.pressed.connect(func():
		GameManager.reset()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(btn)
	
	get_tree().current_scene.add_child(fin)
	
	# Liberar inventario DESPUÉS de agregar la pantalla de fin
	queue_free()
