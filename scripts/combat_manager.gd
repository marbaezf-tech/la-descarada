extends CanvasLayer
## CombatManager — Combate por turnos (UI por código)

signal combat_ended(victory: bool)

enum CombatState { PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }

var state: CombatState = CombatState.PLAYER_TURN
var enemy_name: String = ""
var enemy_hp: float = 0.0
var enemy_hp_max: float = 0.0
var enemy_fuerza: float = 0.0
var enemy_agilidad: float = 0.0
var enemy_defensa: float = 0.0

var enemy_name_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label
var log_label: RichTextLabel
var btn_atacar: Button
var btn_habilidad: Button
var btn_huir: Button

const ENEMY_PHRASES: Dictionary = {
	"Garrapata Salvaje": ["¡Rómpete! ¡Déjame entrar a tu calor!", "¡Dámela, dámela!", "¡Tu caparazón no me detendrá!"],
	"Cucaracha Carroñera": ["¡Dame tus cosas!", "¡Sobreviví al zapatazo divino!", "¡Tu inventario será MÍO!"],
	"Polilla Sedante": ["Shhh... duerme...", "La luz me dijo que te calmara...", "No luches... el sueño es dulce..."],
}

func setup_enemy(p_name: String, hp: float, fuerza: float, agilidad: float, defensa: float) -> void:
	enemy_name = p_name
	enemy_hp = hp
	enemy_hp_max = hp
	enemy_fuerza = fuerza
	enemy_agilidad = agilidad
	enemy_defensa = defensa

func _ready() -> void:
	_build_ui()
	_update_ui()
	_log("⚔️ ¡%s te desafía en TU territorio!" % enemy_name)
	_log("Tu turno. Exige respeto.")

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.anchors_preset = 15
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 40
	panel.offset_top = 20
	panel.offset_right = -40
	panel.offset_bottom = -20
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	enemy_name_label = Label.new()
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(enemy_name_label)
	
	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(0, 16)
	enemy_hp_bar.show_percentage = false
	vbox.add_child(enemy_hp_bar)
	
	enemy_hp_label = Label.new()
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(enemy_hp_label)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 100)
	log_label.scroll_following = true
	vbox.add_child(log_label)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	btn_atacar = Button.new()
	btn_atacar.text = "⚔️ Atacar"
	btn_atacar.pressed.connect(_on_atacar)
	hbox.add_child(btn_atacar)
	
	btn_habilidad = Button.new()
	btn_habilidad.text = "💉 Inyección"
	btn_habilidad.pressed.connect(_on_habilidad)
	hbox.add_child(btn_habilidad)
	
	btn_huir = Button.new()
	btn_huir.text = "🏃 Retirada"
	btn_huir.pressed.connect(_on_huir)
	hbox.add_child(btn_huir)

func _update_ui() -> void:
	enemy_name_label.text = "🎯 %s" % enemy_name
	enemy_hp_bar.max_value = enemy_hp_max
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "HP: %d/%d" % [enemy_hp, enemy_hp_max]

func _set_buttons_enabled(enabled: bool) -> void:
	btn_atacar.disabled = not enabled
	btn_habilidad.disabled = not enabled
	btn_huir.disabled = not enabled

func _log(text: String) -> void:
	log_label.text += text + "\n"

func _on_atacar() -> void:
	if state != CombatState.PLAYER_TURN: return
	state = CombatState.ANIMATING
	_set_buttons_enabled(false)
	var player_fuerza = GameManager.stats.get("fuerza", 5)
	var arma_bonus = GameManager.stats.get("arma_equipada", 0)
	var base_damage = (player_fuerza + arma_bonus) * 2.0 - enemy_defensa
	var damage = maxf(1.0, base_damage * randf_range(0.85, 1.15))
	enemy_hp -= damage
	_log("🗡️ Cortes de precisión. (%.0f daño)" % damage)
	_update_ui()
	_check_enemy_death()

func _on_habilidad() -> void:
	if state != CombatState.PLAYER_TURN: return
	state = CombatState.ANIMATING
	_set_buttons_enabled(false)
	var result = GameManager.usar_habilidad_taxon(enemy_agilidad)
	if not result["exito"]:
		_log("❌ %s" % result["mensaje"])
		state = CombatState.PLAYER_TURN
		_set_buttons_enabled(true)
		return
	_log("💉 Cirugía en progreso. Neuro-bloqueador inyectado.")
	enemy_agilidad *= 0.5
	var damage = GameManager.stats.get("fuerza", 5) * 1.5
	enemy_hp -= damage
	_log("   → Daño: %.0f" % damage)
	_update_ui()
	_check_enemy_death()

func _on_huir() -> void:
	if state != CombatState.PLAYER_TURN: return
	state = CombatState.ANIMATING
	_set_buttons_enabled(false)
	var player_vel = GameManager.calcular_velocidad()
	var enemy_vel = (enemy_agilidad + 5.0) / 2.0
	var chance = clampf((player_vel / enemy_vel) * 0.5, 0.2, 0.95)
	if randf() < chance:
		_log("🏃 Retirada estratégica. Volverás.")
		GameManager.modificar_esencia(-2.0, "Huiste")
		_end_combat(false)
	else:
		_log("❌ ¡No puedes huir!")
		_enemy_turn()

func _check_enemy_death() -> void:
	if enemy_hp <= 0:
		enemy_hp = 0
		_update_ui()
		_log("\n💀 %s cae. Biomasa asegurada." % enemy_name)
		var loot = LootSystem.generar_loot()
		# Arañas siempre dropean Seda de Fibra de Carbono
		if "Araña" in enemy_name or "Polilla" in enemy_name:
			var seda = {"nombre": "Seda de Fibra de Carbono", "emoji": "🕸️", "tipo": "material", "valor": 2, "tier": "raro", "desc": "Robada del cadáver. Material para el Anclaje."}
			GameManager.agregar_item(seda)
			_log("   🕸️ Seda de Fibra de Carbono obtenida!")
		GameManager.agregar_item(loot)
		_log("   📦 %s %s [%s]" % [loot["emoji"], loot["nombre"], loot["tier"].to_upper()])
		GameManager.obtener_recurso(15.0)
		GameManager.ganar_exp(10.0)
		GameManager.accion_quest_pacifica()
		_log("   +15 Recurso | +10 EXP | +5 Esencia")
		_end_combat(true)
	else:
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()

func _enemy_turn() -> void:
	state = CombatState.ENEMY_TURN
	var base_damage = enemy_fuerza * 1.5 - GameManager.stats.get("resistencia", 4) - GameManager.stats.get("armadura_equipada", 0)
	var damage = maxf(1.0, base_damage * randf_range(0.85, 1.15))
	GameManager.recibir_dano(damage)
	var phrases = ENEMY_PHRASES.get(enemy_name, ["¡Muere!"])
	_log("🩸 %s: \"%s\" (%.0f)" % [enemy_name, phrases[randi() % phrases.size()], damage])
	if GameManager.quitina_actual <= 0:
		_log("\n💀 Tu quitina se quiebra. El Charco no perdona.")
		_end_combat(false)
	else:
		await get_tree().create_timer(0.4).timeout
		state = CombatState.PLAYER_TURN
		_set_buttons_enabled(true)
		_log("— Tu turno.")

func _end_combat(victory: bool) -> void:
	state = CombatState.ENDED
	_set_buttons_enabled(false)
	btn_huir.text = "✖ Cerrar"
	btn_huir.disabled = false
	btn_huir.pressed.disconnect(_on_huir)
	btn_huir.pressed.connect(func():
		combat_ended.emit(victory)
		queue_free()
	)
