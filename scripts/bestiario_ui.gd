extends CanvasLayer
## BestiarioUI — Pokédex de enemigos vencidos (tecla L)

var panel: PanelContainer
var items_container: VBoxContainer

# Registro de enemigos vencidos (se guarda en GameManager)
const ENEMY_DATA: Dictionary = {
	"Garrapata Salvaje": {
		"emoji": "🕷️",
		"hp": 30,
		"fuerza": 4,
		"agilidad": 3,
		"defensa": 2,
		"zona": "El Laboratorio",
		"comportamiento": "Salta desde estanterías. Ataque sorpresa.",
		"loot": "Hemolinfa Fresca, Espina de Cactus, Fémur de Grillo, Seda de Fibra",
		"aparicion": "33%",
	},
	"Cucaracha Carroñera": {
		"emoji": "🪳",
		"hp": 20,
		"fuerza": 3,
		"agilidad": 5,
		"defensa": 1,
		"zona": "El Laboratorio",
		"comportamiento": "Intenta robar items. Rápida pero frágil.",
		"loot": "Hoja de Menta, Capa de Hoja Seca, Gota de Miel, Placa de Élitro",
		"aparicion": "33%",
	},
	"Polilla Sedante": {
		"emoji": "🌙",
		"hp": 15,
		"fuerza": 2,
		"agilidad": 4,
		"defensa": 0,
		"zona": "El Laboratorio",
		"comportamiento": "Pasiva. Usa polvo sedante que reduce Velocidad.",
		"loot": "Hemolinfa Fresca, Seda de Fibra de Carbono, Rocío Matutino Puro",
		"aparicion": "33%",
	},
}

func _ready() -> void:
	layer = 30
	
	panel = PanelContainer.new()
	panel.anchor_left = 0.05
	panel.anchor_top = 0.05
	panel.anchor_right = 0.95
	panel.anchor_bottom = 0.95
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "📕 BESTIARIO DEL GRAN CHARCO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	header.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "✖"
	close_btn.pressed.connect(func(): queue_free())
	header.add_child(close_btn)
	
	vbox.add_child(HSeparator.new())
	
	# Scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.add_theme_constant_override("separation", 10)
	scroll.add_child(items_container)
	
	_refresh()

func _refresh() -> void:
	var enemigos_vencidos = GameManager.get_meta("enemigos_vencidos", []) as Array
	
	if enemigos_vencidos.is_empty():
		var empty = Label.new()
		empty.text = "\n🔒 No has vencido a ningún enemigo todavía.\n\nSal a cazar para llenar el bestiario."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.add_theme_font_size_override("font_size", 11)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(empty)
		return
	
	var count_label = Label.new()
	count_label.text = "📊 %d/%d especies registradas" % [enemigos_vencidos.size(), ENEMY_DATA.size()]
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	items_container.add_child(count_label)
	
	for enemy_name in ENEMY_DATA.keys():
		var data = ENEMY_DATA[enemy_name]
		var discovered = enemy_name in enemigos_vencidos
		
		var card = VBoxContainer.new()
		items_container.add_child(card)
		
		if discovered:
			# Nombre
			var name_label = Label.new()
			name_label.text = "%s %s" % [data["emoji"], enemy_name]
			name_label.add_theme_font_size_override("font_size", 12)
			name_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			card.add_child(name_label)
			
			# Stats
			var stats_label = Label.new()
			stats_label.text = "  ❤️ HP: %d  |  ⚔️ Fue: %d  |  💨 Agi: %d  |  🛡️ Def: %d" % [data["hp"], data["fuerza"], data["agilidad"], data["defensa"]]
			stats_label.add_theme_font_size_override("font_size", 9)
			card.add_child(stats_label)
			
			# Zona + aparición
			var zona_label = Label.new()
			zona_label.text = "  📍 %s  |  📊 Aparición: %s" % [data["zona"], data["aparicion"]]
			zona_label.add_theme_font_size_override("font_size", 9)
			zona_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			card.add_child(zona_label)
			
			# Comportamiento
			var behav_label = Label.new()
			behav_label.text = "  🎯 %s" % data["comportamiento"]
			behav_label.add_theme_font_size_override("font_size", 9)
			behav_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
			card.add_child(behav_label)
			
			# Loot
			var loot_label = Label.new()
			loot_label.text = "  🎁 Loot: %s" % data["loot"]
			loot_label.add_theme_font_size_override("font_size", 9)
			loot_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			card.add_child(loot_label)
		else:
			# No descubierto
			var locked = Label.new()
			locked.text = "🔒 ??? — No descubierto"
			locked.add_theme_font_size_override("font_size", 11)
			locked.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			card.add_child(locked)
		
		var sep = HSeparator.new()
		items_container.add_child(sep)
	
	# Footer
	var footer = Label.new()
	footer.text = "\n\"Cada bicho que matas te enseña algo.\"\n— Ramazzottius"
	footer.add_theme_font_size_override("font_size", 9)
	footer.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_container.add_child(footer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bestiario"):
		queue_free()
