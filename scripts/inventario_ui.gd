extends CanvasLayer
## InventarioUI — Pantalla de inventario (tecla I)

var panel: PanelContainer
var items_container: VBoxContainer
var title_label: Label
var close_btn: Button

func _ready() -> void:
	layer = 30
	
	panel = PanelContainer.new()
	panel.anchor_left = 0.1
	panel.anchor_top = 0.05
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.95
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
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
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Scroll container para items
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_container)
	
	# Poblar items
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
	
	var sep = HSeparator.new()
	items_container.add_child(sep)
	
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
		
		# Botón Usar (consumibles)
		if tipo == "consumible":
			var btn_usar = Button.new()
			btn_usar.text = "Usar"
			btn_usar.add_theme_font_size_override("font_size", 9)
			btn_usar.pressed.connect(_usar_item.bind(i))
			row.add_child(btn_usar)
		
		# Botón Equipar (armas y armaduras)
		if tipo in ["arma_cc", "arma_dist", "armadura"]:
			var btn_equip = Button.new()
			btn_equip.text = "Equipar"
			btn_equip.add_theme_font_size_override("font_size", 9)
			btn_equip.pressed.connect(_equipar_item.bind(i))
			row.add_child(btn_equip)
		
		# Botón Tirar
		var btn_tirar = Button.new()
		btn_tirar.text = "✖"
		btn_tirar.add_theme_font_size_override("font_size", 9)
		btn_tirar.pressed.connect(_tirar_item.bind(i))
		row.add_child(btn_tirar)
		
		items_container.add_child(row)
	
	# Footer con conteo
	var footer = Label.new()
	footer.text = "\n📦 %d/%d items" % [GameManager.inventario.size(), GameManager.INVENTARIO_MAX]
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	items_container.add_child(footer)
	
	# Botón de Crafteo del Anclaje
	var craft_sep = HSeparator.new()
	items_container.add_child(craft_sep)
	
	var craft_title = Label.new()
	craft_title.text = "🔧 CRAFTEO — Anclaje de Fibra"
	craft_title.add_theme_font_size_override("font_size", 11)
	craft_title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9))
	items_container.add_child(craft_title)
	
	# Contar materiales
	var sedas = _contar_material("Seda de Fibra de Carbono")
	var cobres = _contar_material("Nervio de Cobre")
	var hemo_ok = GameManager.hemolinfa_actual >= 15.0
	
	var req_label = Label.new()
	req_label.text = "  🕸️ Seda: %d/3  |  ⚡ Cobre: %d/1  |  💧 Hemolinfa: %s" % [sedas, cobres, "✅" if hemo_ok else "❌ (necesitas 15)"]
	req_label.add_theme_font_size_override("font_size", 9)
	items_container.add_child(req_label)
	
	var btn_craft = Button.new()
	btn_craft.text = "🔧 Craftear Anclaje de Fibra (FIN DE DEMO)"
	btn_craft.add_theme_font_size_override("font_size", 10)
	btn_craft.disabled = not (sedas >= 3 and cobres >= 1 and hemo_ok)
	btn_craft.pressed.connect(_craftear_anclaje)
	items_container.add_child(btn_craft)

func _cerrar() -> void:
	queue_free()

func _usar_item(index: int) -> void:
	var item = GameManager.inventario[index]
	var nombre = item.get("nombre", "")
	
	# Efectos de consumibles
	match nombre:
		"Hemolinfa Fresca":
			GameManager.hemolinfa_actual = minf(GameManager.hemolinfa_actual + GameManager.hemolinfa_max * 0.2, GameManager.hemolinfa_max)
			GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
		"Gota de Miel":
			GameManager.curar(GameManager.quitina_max * 0.3)
		"Hoja de Menta":
			GameManager.curar(GameManager.quitina_max * 0.1)
		"Cristal de Cafeína":
			GameManager.stats["agilidad"] = GameManager.stats.get("agilidad", 5) + 2
		"Adrenalina de Avispa":
			GameManager.stats["fuerza"] = GameManager.stats.get("fuerza", 5) + 3
		_:
			GameManager.curar(GameManager.quitina_max * 0.15)
	
	print("💊 Usado: %s %s" % [item.get("emoji",""), nombre])
	GameManager.remover_item(index)
	_refresh_items()

func _equipar_item(index: int) -> void:
	var item = GameManager.inventario[index]
	var tipo = item.get("tipo", "")
	var valor = item.get("valor", 0)
	
	if tipo == "arma_cc" or tipo == "arma_dist":
		GameManager.stats["arma_equipada"] = valor
		print("⚔️ Equipado: %s %s (+%d daño)" % [item.get("emoji",""), item.get("nombre",""), valor])
	elif tipo == "armadura":
		GameManager.stats["armadura_equipada"] = valor
		print("🛡️ Equipado: %s %s (+%d defensa)" % [item.get("emoji",""), item.get("nombre",""), valor])
	
	_refresh_items()

func _tirar_item(index: int) -> void:
	var item = GameManager.inventario[index]
	print("🗑️ Descartado: %s %s" % [item.get("emoji",""), item.get("nombre","")])
	GameManager.remover_item(index)
	_refresh_items()

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
	# Consumir materiales
	_remover_material("Seda de Fibra de Carbono", 3)
	_remover_material("Nervio de Cobre", 1)
	GameManager.hemolinfa_actual -= 15.0
	GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
	
	# Cerrar inventario y mostrar pantalla de fin de demo
	queue_free()
	
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
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://menu.tscn"))
	vbox.add_child(btn)
	
	get_tree().current_scene.add_child(fin)
