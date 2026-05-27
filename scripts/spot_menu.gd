extends CanvasLayer
## SpotMenu — Menú de interacción (construido por código)

signal closed

var title_label: Label
var desc_label: Label
var btn_explorar: Button
var btn_cazar: Button
var btn_lotear: Button
var btn_cerrar: Button

var _spot_name: String = ""
var _spot_type: String = ""
var _description: String = ""

func setup(spot_name: String, spot_type: String, description: String) -> void:
	_spot_name = spot_name
	_spot_type = spot_type
	_description = description

func _ready() -> void:
	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150
	panel.offset_top = -100
	panel.offset_right = 150
	panel.offset_bottom = 100
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	title_label = Label.new()
	title_label.text = _spot_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	desc_label = Label.new()
	desc_label.text = _description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(280, 60)
	vbox.add_child(desc_label)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	btn_explorar = Button.new()
	btn_explorar.text = "🔍 Inspeccionar"
	btn_explorar.visible = _spot_type in ["explorar", "todos"]
	btn_explorar.pressed.connect(_on_explorar)
	hbox.add_child(btn_explorar)
	
	btn_cazar = Button.new()
	btn_cazar.text = "🩸 Diezmo"
	btn_cazar.visible = _spot_type in ["cazar", "todos"]
	btn_cazar.pressed.connect(_on_cazar)
	hbox.add_child(btn_cazar)
	
	btn_lotear = Button.new()
	btn_lotear.text = "💰 Cobrar"
	btn_lotear.visible = _spot_type in ["lotear", "todos"]
	btn_lotear.pressed.connect(_on_lotear)
	hbox.add_child(btn_lotear)
	
	btn_cerrar = Button.new()
	btn_cerrar.text = "✖ Cerrar"
	btn_cerrar.pressed.connect(_on_cerrar)
	vbox.add_child(btn_cerrar)

func _on_explorar() -> void:
	var textos = {
		"Monitor Holográfico Roto": "Un monitor oxidado de la Era de los Titanes. Su pantalla parpadea con datos incomprensibles. Quizás contenga coordenadas. Quizás solo basura digital.",
		"Vaso de Agua Estancada": "Un cráter de cristal sellado por una fina capa de hielo. Prepara la aguja.",
		"Cable Expuesto": "Un nervio muerto de la antigua Santiago. Aún retiene un fantasma de estática."
	}
	desc_label.text = textos.get(_spot_name, "Inspeccionas el territorio ganado.")
	GameManager.accion_quest_pacifica()
	# El Cable Expuesto da Nervio de Cobre al inspeccionar
	if _spot_name == "Cable Expuesto":
		var cobre = {"nombre": "Nervio de Cobre", "emoji": "⚡", "tipo": "material", "valor": 3, "tier": "raro", "desc": "Vibra con estática. Material para el Anclaje."}
		if GameManager.agregar_item(cobre):
			desc_label.text += "\n\n⚡ ¡Obtuviste Nervio de Cobre!"

func _on_cazar() -> void:
	var enemies = [
		{"name": "Garrapata Salvaje", "hp": 30.0, "fue": 4.0, "agi": 3.0, "def": 2.0},
		{"name": "Cucaracha Carroñera", "hp": 20.0, "fue": 3.0, "agi": 5.0, "def": 1.0},
		{"name": "Polilla Sedante", "hp": 15.0, "fue": 2.0, "agi": 4.0, "def": 0.0},
	]
	var enemy = enemies[randi() % enemies.size()]
	closed.emit()
	var combat = CanvasLayer.new()
	combat.layer = 20
	combat.set_script(load("res://scripts/combat_manager.gd"))
	combat.setup_enemy(enemy["name"], enemy["hp"], enemy["fue"], enemy["agi"], enemy["def"])
	combat.combat_ended.connect(_on_combat_ended)
	get_tree().current_scene.add_child(combat)
	queue_free()

func _on_combat_ended(victory: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.resume_movement()

func _on_lotear() -> void:
	var loot = LootSystem.generar_loot()
	var added = GameManager.agregar_item(loot)
	if added:
		desc_label.text = "%s %s [%s]\n%s" % [loot["emoji"], loot["nombre"], loot["tier"].to_upper(), loot["desc"]]
	else:
		desc_label.text = "Inventario lleno. Suelta algo primero."
	GameManager.hemolinfa_actual = minf(GameManager.hemolinfa_actual + 5.0, GameManager.hemolinfa_max)
	GameManager.hemolinfa_changed.emit(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)

func _on_cerrar() -> void:
	closed.emit()
	queue_free()
