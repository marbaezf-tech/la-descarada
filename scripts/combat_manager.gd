extends CanvasLayer
## CombatManager — Combate por turnos estilo Pokémon
## Prota de espalda abajo-izquierda, Enemigo de frente arriba-derecha
##
## DOCUMENTACIÓN:
## - Fórmulas de combate: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html
## - Spawn table: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html#spawn
## - Bestiario: https://marbaezf-tech.github.io/plaga-wiki/bestiario.html
## - Trazabilidad: https://marbaezf-tech.github.io/plaga-wiki/trazabilidad.html

signal combat_ended(victory: bool)

enum CombatState { PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }

var state: CombatState = CombatState.PLAYER_TURN
var enemy_name: String = ""
var enemy_hp: float = 0.0
var enemy_hp_max: float = 0.0
var enemy_fuerza: float = 0.0
var enemy_agilidad: float = 0.0
var enemy_defensa: float = 0.0

# Tracking de socialización en este combate
var _turnos_sin_social: int = 0  # Si llega a 3, pierde antena

var enemy_name_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label
var player_hp_bar: ProgressBar
var player_hp_label: Label
var player_name_label: Label
var log_label: RichTextLabel
var btn_atacar: Button
var btn_habilidad: Button
var btn_danza: Button
var btn_huir: Button

# Avatares
var player_avatar: Control
var enemy_avatar: Control

const ENEMY_PHRASES: Dictionary = {
	"Garrapata Salvaje": ["¡Rómpete! ¡Déjame entrar a tu calor!", "¡Dámela, dámela!", "¡Tu caparazón no me detendrá!"],
	"Cucaracha Carroñera": ["¡Dame tus cosas!", "¡Sobreviví al zapatazo divino!", "¡Tu inventario será MÍO!"],
	"Polilla Sedante": ["Shhh... duerme...", "La luz me dijo que te calmara...", "No luches... el sueño es dulce..."],
}

# Colores de enemigos para placeholder
const ENEMY_COLORS: Dictionary = {
	"Garrapata Salvaje": Color(0.6, 0.1, 0.1),
	"Cucaracha Carroñera": Color(0.5, 0.3, 0.1),
	"Polilla Sedante": Color(0.6, 0.6, 0.8),
}

func setup_enemy(p_name: String, hp: float, fuerza: float, agilidad: float, defensa: float, fer: float = -1.0, cri: float = -1.0, sen: float = -1.0) -> void:
	enemy_name = p_name
	enemy_hp = hp
	enemy_hp_max = hp
	enemy_fuerza = fuerza
	enemy_agilidad = agilidad
	enemy_defensa = defensa
	# Stats sociales: usar valores explícitos o generar automáticamente
	if fer >= 0:
		enemy_feromonas = fer
		enemy_cripsis = cri
		enemy_sensilios = sen
	else:
		enemy_feromonas = clampf(fuerza * 0.4 + randf_range(1, 3), 2, 8)
		enemy_cripsis = clampf(agilidad * 0.6 + randf_range(0, 2), 2, 8)
		enemy_sensilios = clampf((fuerza + agilidad) * 0.3 + randf_range(1, 2), 2, 8)

func _ready() -> void:
	_build_ui()
	_update_ui()
	_log("⚔️ ¡%s te desafía en TU territorio!" % enemy_name)
	_log("Tu turno. Exige respeto.")

func _build_ui() -> void:
	# === FONDO OSCURO SEMI-TRANSPARENTE ===
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.02, 0.03, 0.05, 0.95)
	add_child(bg)
	
	# === ZONA DE BATALLA (arriba ~60% de pantalla) ===
	var battle_zone = Control.new()
	battle_zone.anchor_right = 1.0
	battle_zone.offset_bottom = 200
	add_child(battle_zone)
	
	# --- ENEMIGO: imagen de fondo centrada ---
	enemy_avatar = _create_avatar_fullscreen(enemy_name)
	battle_zone.add_child(enemy_avatar)
	
	# --- Log de combate: arriba-izquierda ---
	log_label = RichTextLabel.new()
	log_label.position = Vector2(10, 10)
	log_label.size = Vector2(250, 100)
	log_label.scroll_following = true
	log_label.scroll_active = false
	log_label.add_theme_font_size_override("normal_font_size", 9)
	battle_zone.add_child(log_label)
	
	# --- Stats enemigo: arriba-derecha ---
	var enemy_container = VBoxContainer.new()
	enemy_container.position = Vector2(460, 10)
	enemy_container.custom_minimum_size = Vector2(170, 0)
	battle_zone.add_child(enemy_container)
	
	enemy_name_label = Label.new()
	enemy_name_label.text = "🎯 %s" % enemy_name
	enemy_name_label.add_theme_font_size_override("font_size", 11)
	enemy_name_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	enemy_container.add_child(enemy_name_label)
	
	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(150, 10)
	enemy_hp_bar.max_value = enemy_hp_max
	enemy_hp_bar.value = enemy_hp
	enemy_hp_bar.show_percentage = false
	enemy_container.add_child(enemy_hp_bar)
	
	enemy_hp_label = Label.new()
	enemy_hp_label.text = "HP: %d/%d" % [enemy_hp, enemy_hp_max]
	enemy_hp_label.add_theme_font_size_override("font_size", 9)
	enemy_container.add_child(enemy_hp_label)
	
	# --- Jugador: abajo-izquierda (foto + HP + equipo + atavismos) ---
	var player_panel = PanelContainer.new()
	player_panel.anchor_top = 0.6
	player_panel.anchor_left = 0.0
	player_panel.anchor_right = 0.55
	player_panel.anchor_bottom = 1.0
	player_panel.offset_left = 10
	player_panel.offset_bottom = -10
	add_child(player_panel)
	
	var player_hbox = HBoxContainer.new()
	player_hbox.add_theme_constant_override("separation", 8)
	player_panel.add_child(player_hbox)
	
	player_avatar = _create_player_avatar()
	player_hbox.add_child(player_avatar)
	
	var player_info_vbox = VBoxContainer.new()
	player_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_info_vbox.add_theme_constant_override("separation", 2)
	player_hbox.add_child(player_info_vbox)
	
	# Nombre + HP
	player_name_label = Label.new()
	var taxon_data = GameManager.TAXON_DATA[GameManager.taxon_actual]
	player_name_label.text = "%s %s" % [taxon_data["emoji"], GameManager.nombre_plaga]
	player_name_label.add_theme_font_size_override("font_size", 10)
	player_name_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
	player_info_vbox.add_child(player_name_label)
	
	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(100, 8)
	player_hp_bar.max_value = GameManager.turgencia_max
	player_hp_bar.value = GameManager.turgencia_actual
	player_hp_bar.show_percentage = false
	player_info_vbox.add_child(player_hp_bar)
	
	player_hp_label = Label.new()
	player_hp_label.text = "HP: %d/%d" % [GameManager.turgencia_actual, GameManager.turgencia_max]
	player_hp_label.add_theme_font_size_override("font_size", 8)
	player_info_vbox.add_child(player_hp_label)
	
	# Equipo actual
	var arma_val = GameManager.stats.get("arma_equipada", 0)
	var armadura_val = GameManager.stats.get("armadura_equipada", 0)
	var equip_label = Label.new()
	equip_label.text = "🗡️+%d  🛡️+%d" % [arma_val, armadura_val]
	equip_label.add_theme_font_size_override("font_size", 8)
	equip_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	player_info_vbox.add_child(equip_label)
	
	# Atavismos disponibles
	var atavismos_label = Label.new()
	atavismos_label.text = "🧬 Micro-Inyección (3 Hemo)"
	atavismos_label.add_theme_font_size_override("font_size", 8)
	atavismos_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	player_info_vbox.add_child(atavismos_label)
	
	# Hemolinfa actual
	var hemo_label = Label.new()
	hemo_label.text = "💧 Hemolinfa: %d/%d" % [GameManager.hemolinfa_actual, GameManager.hemolinfa_max]
	hemo_label.add_theme_font_size_override("font_size", 8)
	hemo_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	player_info_vbox.add_child(hemo_label)
	
	# Antenas Sociales
	var antenas_text = ""
	for i in range(GameManager.ANTENAS_MAX):
		if i < GameManager.antenas:
			antenas_text += "🐜"
		else:
			antenas_text += "·"
	var antenas_label = Label.new()
	antenas_label.text = antenas_text + " (%d/%d)" % [GameManager.antenas, GameManager.ANTENAS_MAX]
	antenas_label.add_theme_font_size_override("font_size", 7)
	if GameManager.antenas <= 2:
		antenas_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.1))
	elif GameManager.antenas >= 8:
		antenas_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	else:
		antenas_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
	player_info_vbox.add_child(antenas_label)
	
	# === ZONA DE BOTONES (abajo-derecha) ===
	var btn_panel = PanelContainer.new()
	btn_panel.anchor_top = 0.6
	btn_panel.anchor_left = 0.55
	btn_panel.anchor_right = 1.0
	btn_panel.anchor_bottom = 1.0
	btn_panel.offset_left = 10
	btn_panel.offset_right = -10
	btn_panel.offset_bottom = -10
	add_child(btn_panel)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 6)
	btn_panel.add_child(btn_vbox)
	
	btn_atacar = Button.new()
	btn_atacar.text = "⚔️ Atacar"
	btn_atacar.custom_minimum_size = Vector2(0, 30)
	btn_atacar.add_theme_font_size_override("font_size", 11)
	btn_atacar.pressed.connect(_on_atacar)
	btn_vbox.add_child(btn_atacar)
	
	btn_habilidad = Button.new()
	btn_habilidad.text = "🧬 Atavismo"
	btn_habilidad.custom_minimum_size = Vector2(0, 30)
	btn_habilidad.add_theme_font_size_override("font_size", 11)
	btn_habilidad.pressed.connect(_on_habilidad)
	btn_vbox.add_child(btn_habilidad)
	
	var btn_danza = Button.new()
	btn_danza.text = "🐜 Danza de Antenas"
	btn_danza.custom_minimum_size = Vector2(0, 30)
	btn_danza.add_theme_font_size_override("font_size", 11)
	btn_danza.pressed.connect(_on_danza)
	btn_vbox.add_child(btn_danza)
	
	btn_huir = Button.new()
	btn_huir.text = "🏃 Retirada"
	btn_huir.custom_minimum_size = Vector2(0, 30)
	btn_huir.add_theme_font_size_override("font_size", 11)
	btn_huir.pressed.connect(_on_huir)
	btn_vbox.add_child(btn_huir)

func _create_avatar_fullscreen(char_name: String) -> TextureRect:
	var img_name = char_name.to_lower().replace(" ", "_").replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u").replace("ñ","n")
	var paths_to_try = [
		"res://imagenes/Enemigos/2d_%s.png" % img_name,
		"res://imagenes/2d_%s.png" % img_name,
	]
	var sprite = TextureRect.new()
	for img_path in paths_to_try:
		if ResourceLoader.exists(img_path):
			sprite.texture = load(img_path)
			break
	sprite.anchor_right = 1.0
	sprite.anchor_bottom = 1.0
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	return sprite

func _create_avatar(char_name: String, is_enemy: bool) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(48, 48)
	
	# Intentar cargar imagen del enemigo
	var img_name = char_name.to_lower().replace(" ", "_").replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u").replace("ñ","n")
	var paths_to_try = [
		"res://imagenes/Enemigos/2d_%s.png" % img_name,
		"res://imagenes/2d_%s.png" % img_name,
		"res://imagenes/%s.png" % img_name,
	]
	
	var loaded = false
	for img_path in paths_to_try:
		if ResourceLoader.exists(img_path):
			var sprite = TextureRect.new()
			sprite.texture = load(img_path)
			sprite.size = Vector2(48, 48)
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			container.add_child(sprite)
			loaded = true
			break
	
	if not loaded:
		var rect = ColorRect.new()
		rect.size = Vector2(48, 48)
		rect.color = ENEMY_COLORS.get(char_name, Color(0.4, 0.2, 0.2))
		container.add_child(rect)
		
		var emoji_label = Label.new()
		emoji_label.text = "👾" if is_enemy else "🦟"
		emoji_label.position = Vector2(10, 8)
		emoji_label.add_theme_font_size_override("font_size", 20)
		container.add_child(emoji_label)
	
	return container

func _create_player_avatar() -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(80, 80)
	
	# Intentar cargar imagen de espalda del protagonista
	var paths_to_try = [
		"res://imagenes/2d_prota_back.png",
		"res://imagenes/zancudo masked back.png",
		"res://imagenes/zancudo masked 1 chibi back - copia.png",
		"res://assets/sprites/zancudo_back.png"
	]
	
	var loaded = false
	for img_path in paths_to_try:
		if ResourceLoader.exists(img_path):
			var sprite = TextureRect.new()
			sprite.texture = load(img_path)
			sprite.custom_minimum_size = Vector2(80, 80)
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(sprite)
			loaded = true
			break
	
	if not loaded:
		# Placeholder verde (prota de espalda)
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(80, 80)
		rect.size = Vector2(80, 80)
		rect.color = Color(0.1, 0.4, 0.2)
		container.add_child(rect)
		
		var emoji_label = Label.new()
		var taxon_data = GameManager.TAXON_DATA[GameManager.taxon_actual]
		emoji_label.text = taxon_data["emoji"]
		emoji_label.position = Vector2(25, 20)
		emoji_label.add_theme_font_size_override("font_size", 28)
		container.add_child(emoji_label)
	
	return container

func _update_ui() -> void:
	enemy_name_label.text = "🎯 %s" % enemy_name
	enemy_hp_bar.max_value = enemy_hp_max
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "HP: %d/%d" % [enemy_hp, enemy_hp_max]
	player_hp_bar.max_value = GameManager.turgencia_max
	player_hp_bar.value = GameManager.turgencia_actual
	player_hp_label.text = "HP: %d/%d" % [GameManager.turgencia_actual, GameManager.turgencia_max]

func _set_buttons_enabled(enabled: bool) -> void:
	btn_atacar.disabled = not enabled
	btn_habilidad.disabled = not enabled
	btn_danza.disabled = not enabled
	btn_huir.disabled = not enabled

func _log(text: String) -> void:
	log_label.text += text + "\n"

func _on_atacar() -> void:
	if state != CombatState.PLAYER_TURN: return
	state = CombatState.ANIMATING
	_set_buttons_enabled(false)
	var player_fuerza = GameManager.stats.get("torax", 5)
	var arma_bonus = GameManager.stats.get("arma_equipada", 0)
	var player_ganglios = GameManager.stats.get("ganglios", 5)
	var player_sensilios = GameManager.stats.get("sensilios", 5)
	# Evasión enemiga: GAN×3.5% + CRI×2.5% (cap 55%)
	var enemy_evasion = minf(0.55, enemy_agilidad * 0.035 + enemy_cripsis * 0.025)
	# Precisión del jugador reduce evasión: SEN×2%
	var precision_bonus = player_sensilios * 0.02
	var evasion_final = maxf(0.05, enemy_evasion - precision_bonus)
	
	# Check evasión
	if randf() < evasion_final:
		_log("💨 ¡%s esquivó tu ataque!" % enemy_name)
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()
		return
	
	var base_damage = (player_fuerza + arma_bonus) * 2.0 - enemy_defensa * 0.5
	var damage = maxf(1.0, base_damage * randf_range(0.85, 1.15))
	# Bonus de Danza de Antenas (Mimetismo victoria = crítico)
	if GameManager.get_meta("danza_critico", false):
		damage *= 2.0
		GameManager.set_meta("danza_critico", false)
		_log("🗡️💃 ¡GOLPE FANTASMA! Desde las sombras. (%.0f daño CRÍTICO)" % damage)
	else:
		_log("🗡️ Cortes de precisión. (%.0f daño)" % damage)
	enemy_hp -= damage
	# Violencia sin socializar = antenas bajan
	_turnos_sin_social += 1
	if _turnos_sin_social >= 3:
		_turnos_sin_social = 0
		GameManager.perder_antena("3 turnos de violencia pura")
		_log("   🐜 -1 Antena. El hongo nota tu brutalidad.")
	_update_ui()
	_check_enemy_death()

func _on_habilidad() -> void:
	if state != CombatState.PLAYER_TURN: return
	# Mostrar submenú de atavismos
	_show_atavismo_menu()

func _show_atavismo_menu() -> void:
	var atavismos = GameManager.obtener_atavismos()
	if atavismos.is_empty():
		_log("❌ No tienes atavismos disponibles.")
		return
	
	_set_buttons_enabled(false)
	
	var popup = PanelContainer.new()
	popup.name = "AtavismoPopup"
	popup.anchor_left = 0.1
	popup.anchor_top = 0.3
	popup.anchor_right = 0.5
	popup.anchor_bottom = 0.7
	add_child(popup)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "🧬 Elige Atavismo:"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)
	
	for atav in atavismos:
		var btn = Button.new()
		var can_use = GameManager.hemolinfa_actual >= atav["costo"]
		btn.text = "%s (%d 💧) — %s" % [atav["nombre"], atav["costo"], atav["desc"]]
		btn.add_theme_font_size_override("font_size", 9)
		btn.disabled = not can_use
		btn.pressed.connect(_ejecutar_atavismo.bind(atav, popup))
		vbox.add_child(btn)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "← Cancelar"
	btn_cancel.add_theme_font_size_override("font_size", 9)
	btn_cancel.pressed.connect(func():
		popup.queue_free()
		_set_buttons_enabled(true)
	)
	vbox.add_child(btn_cancel)

func _ejecutar_atavismo(atav: Dictionary, popup: PanelContainer) -> void:
	popup.queue_free()
	state = CombatState.ANIMATING
	
	if not GameManager.gastar_hemolinfa(atav["costo"]):
		_log("❌ Hemolinfa insuficiente.")
		state = CombatState.PLAYER_TURN
		_set_buttons_enabled(true)
		return
	
	_log("🧬 %s activado." % atav["nombre"])
	
	# Efecto en antenas según naturaleza del atavismo
	match atav["efecto"]:
		"confuso", "revelar", "stun":
			# Social/encantador → sube antenas
			_turnos_sin_social = 0
			GameManager.ganar_antena("Encantamiento: %s" % atav["nombre"])
			_log("   🐜 +1 Antena. Diplomacia biológica.")
		"miedo":
			# Intimidar → baja antenas (violencia psicológica)
			GameManager.perder_antena("Intimidación: %s" % atav["nombre"])
			_log("   🐜 -1 Antena. El terror es violencia.")
		"veneno", "drenar", "critico", "penetrar", "multi", "robar", "larva", "agravado":
			# Melee oscuro → baja antenas
			GameManager.perder_antena("Violencia: %s" % atav["nombre"])
			_log("   🐜 -1 Antena. Brutalidad pura.")
		"evasion", "esquiva", "armadura", "inmune", "regen", "golem", "sigilo", "terror_heal":
			# Utilidad/evasión → neutral, no afecta
			_turnos_sin_social = 0  # Al menos no es violencia
		"aleatorio":
			pass  # La moneda no cuenta
		_:
			pass
	
	var damage: float = 0.0
	match atav["efecto"]:
		"paralisis":
			enemy_agilidad *= atav["valor"]
			_log("   → Enemigo paralizado. -50%% Agilidad.")
		"mutacion":
			damage = GameManager.stats.get("torax", 5) * atav["valor"]
			enemy_hp -= damage
			enemy_defensa = maxf(enemy_defensa - 1, 0)
			_log("   → Mutación grotesca. %.0f daño. -1 Defensa." % damage)
		"enjambre":
			GameManager.stats["torax"] = GameManager.stats.get("torax", 5) + int(atav["valor"])
			GameManager.modificar_esencia(-3.0, "Llamada del Enjambre")
			_log("   → +3 Tórax. El enjambre responde. -3%% Esencia.")
		"inmune":
			_log("   → Caparazón activado. Inmune este turno.")
		"armadura":
			GameManager.stats["armadura_equipada"] = GameManager.stats.get("armadura_equipada", 0) + int(atav["valor"])
			_log("   → +%d Defensa temporal." % int(atav["valor"]))
		"regen":
			var heal_amount = GameManager.turgencia_max * atav["valor"]
			GameManager.curar(heal_amount)
			_log("   → Regenera %.0f Turgencia." % heal_amount)
		"multi":
			for i in range(3):
				var hit = GameManager.stats.get("torax", 5) * atav["valor"] * randf_range(0.85, 1.15)
				enemy_hp -= hit
				damage += hit
			_log("   → 3 golpes. %.0f daño total." % damage)
		"penetrar":
			damage = GameManager.stats.get("torax", 5) * atav["valor"] * 2.0
			enemy_hp -= damage
			_log("   → Ignora armadura. %.0f daño." % damage)
		"miedo":
			_log("   → Enemigo aterrorizado. Pierde próximo turno.")
		"drenar":
			damage = enemy_hp_max * atav["valor"]
			enemy_hp -= damage
			GameManager.curar(damage)
			_log("   → Drena %.0f HP del enemigo." % damage)
		"critico":
			damage = GameManager.stats.get("torax", 5) * atav["valor"] * 2.0
			enemy_hp -= damage
			_log("   → ¡CRÍTICO! %.0f daño devastador." % damage)
		"veneno":
			damage = atav["valor"] * 3.0
			enemy_hp -= damage
			_log("   → Veneno inyectado. %.0f daño inmediato." % damage)
		"stun":
			_log("   → Enemigo aturdido. Pierde turno.")
		"robar":
			damage = GameManager.stats.get("torax", 5) * atav["valor"]
			enemy_hp -= damage
			_log("   → Mordida silenciosa. %.0f daño." % damage)
		"revelar":
			_log("   → Stats: HP:%d/%d | Fue:%d | Agi:%d | Def:%d" % [enemy_hp, enemy_hp_max, enemy_fuerza, enemy_agilidad, enemy_defensa])
		"esquiva":
			_log("   → Esquiva garantizada para el próximo ataque.")
		"evasion":
			_log("   → Evasión aumentada. Enemigo fallará más.")
		"aleatorio":
			if randf() > 0.5:
				damage = GameManager.stats.get("torax", 5) * atav["valor"] * 2.0
				enemy_hp -= damage
				_log("   → ¡JACKPOT! %.0f daño." % damage)
			else:
				_log("   → ¡Fallo total! La moneda cayó mal.")
		"terror_heal":
			var heal_amount = GameManager.turgencia_max * atav["valor"]
			GameManager.curar(heal_amount)
			_log("   → Absorbe miedo. +%.0f Turgencia." % heal_amount)
		"sigilo":
			_log("   → Invisible. Próximo ataque será crítico.")
		"velocidad":
			_log("   → Velocidad extrema. Casi intocable.")
		"confuso":
			damage = enemy_fuerza * 2.0
			enemy_hp -= damage
			_log("   → Enemigo confuso. Se golpea solo. %.0f daño." % damage)
		"larva":
			damage = atav["valor"] * 3.0
			enemy_hp -= damage
			_log("   → Larva invocada. Ataca por %.0f daño." % damage)
		"golem":
			GameManager.curar(atav["valor"])
			_log("   → Gólem de basura absorbe daño. +%.0f escudo." % atav["valor"])
		"metamorfosis":
			GameManager.stats["torax"] = GameManager.stats.get("torax", 5) + int(atav["valor"])
			GameManager.stats["ganglios"] = GameManager.stats.get("ganglios", 5) + int(atav["valor"])
			_log("   → Metamorfosis. +%d a todos los stats." % int(atav["valor"]))
		"agravado":
			damage = GameManager.stats.get("torax", 5) * atav["valor"] * 1.5
			enemy_hp -= damage
			_log("   → Daño agravado. %.0f. No se regenera." % damage)
		_:
			damage = GameManager.stats.get("torax", 5) * 1.5
			enemy_hp -= damage
			_log("   → Efecto aplicado. %.0f daño." % damage)
	
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

# ===== DANZA DE ANTENAS — SISTEMA SOCIAL =====
# Piedra-papel-tijera con 4 posturas químicas
# Acecho > Exposición > Vibración > Mimetismo > Acecho (ciclo)

const POSTURAS: Dictionary = {
	"acecho": {"emoji": "🦷", "nombre": "Acecho", "stat": "torax", "desc": "Intimidar con fuerza bruta"},
	"exposicion": {"emoji": "💐", "nombre": "Exposición", "stat": "feromonas", "desc": "Manipular con carisma"},
	"mimetismo": {"emoji": "🫥", "nombre": "Mimetismo", "stat": "cripsis", "desc": "Evadir y observar"},
	"vibracion": {"emoji": "📡", "nombre": "Vibración", "stat": "sensilios", "desc": "Leer y detectar"},
}

# Ventajas: key es fuerte contra value
const POSTURA_VENTAJA: Dictionary = {
	"acecho": "exposicion",
	"exposicion": "vibracion",
	"mimetismo": "acecho",
	"vibracion": "mimetismo",
}

# Stats sociales del enemigo (basados en sus stats de combate)
var enemy_feromonas: float = 3.0
var enemy_cripsis: float = 4.0
var enemy_sensilios: float = 5.0

func _on_danza() -> void:
	if state != CombatState.PLAYER_TURN: return
	_show_danza_menu()

func _show_danza_menu() -> void:
	_set_buttons_enabled(false)
	
	var popup = PanelContainer.new()
	popup.name = "DanzaPopup"
	popup.anchor_left = 0.05
	popup.anchor_top = 0.15
	popup.anchor_right = 0.55
	popup.anchor_bottom = 0.85
	add_child(popup)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "💃 DANZA DE ANTENAS"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "Elige tu postura química. Si ganas, el enemigo\npierde turno + sufre penalización."
	desc.add_theme_font_size_override("font_size", 8)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	
	for key in POSTURAS:
		var postura = POSTURAS[key]
		var stat_val = GameManager.stats.get(postura["stat"], 5)
		var btn = Button.new()
		btn.text = "%s %s (%s: %d) — %s" % [postura["emoji"], postura["nombre"], postura["stat"].to_upper().left(3), stat_val, postura["desc"]]
		btn.add_theme_font_size_override("font_size", 9)
		btn.pressed.connect(_ejecutar_danza.bind(key, popup))
		vbox.add_child(btn)
	
	# Opción de gastar Instinto
	if GameManager.instinto_actual > 0:
		var instinto_label = Label.new()
		instinto_label.text = "⚡ Instinto disponible: %d/%d (+3 al stat elegido)" % [GameManager.instinto_actual, GameManager.instinto_max]
		instinto_label.add_theme_font_size_override("font_size", 8)
		instinto_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
		vbox.add_child(instinto_label)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "← Cancelar"
	btn_cancel.add_theme_font_size_override("font_size", 9)
	btn_cancel.pressed.connect(func():
		popup.queue_free()
		_set_buttons_enabled(true)
	)
	vbox.add_child(btn_cancel)

func _ejecutar_danza(postura_key: String, popup: PanelContainer) -> void:
	popup.queue_free()
	state = CombatState.ANIMATING
	
	var postura = POSTURAS[postura_key]
	var player_stat = GameManager.stats.get(postura["stat"], 5)
	
	# Enemigo elige postura aleatoria (con tendencia a su stat más alto)
	var enemy_postura_key = _enemy_choose_postura()
	var enemy_postura = POSTURAS[enemy_postura_key]
	var enemy_stat_val = _get_enemy_social_stat(enemy_postura["stat"])
	
	_log("\n💃 ¡DANZA DE ANTENAS!")
	_log("   Tú: %s %s (%s: %d)" % [postura["emoji"], postura["nombre"], postura["stat"].left(3).to_upper(), player_stat])
	_log("   %s: %s %s (%s: %d)" % [enemy_name, enemy_postura["emoji"], enemy_postura["nombre"], enemy_postura["stat"].left(3).to_upper(), enemy_stat_val])
	
	# Resolver ventaja/desventaja
	var ventaja_player = POSTURA_VENTAJA.get(postura_key, "") == enemy_postura_key
	var ventaja_enemy = POSTURA_VENTAJA.get(enemy_postura_key, "") == postura_key
	
	var bonus_player: int = 0
	var bonus_enemy: int = 0
	
	if ventaja_player:
		bonus_player = 3
		_log("   ✨ ¡Ventaja! Tu %s aplasta su %s. (+3)" % [postura["nombre"], enemy_postura["nombre"]])
	elif ventaja_enemy:
		bonus_enemy = 3
		_log("   ⚠️ Desventaja. Su %s contrarresta tu %s. (+3 enemigo)" % [enemy_postura["nombre"], postura["nombre"]])
	else:
		_log("   ⚖️ Posturas neutrales. Puro stat vs stat.")
	
	# Tirada: stat + bonus + variación aleatoria (±2)
	var roll_player = player_stat + bonus_player + randi_range(-2, 2)
	var roll_enemy = int(enemy_stat_val) + bonus_enemy + randi_range(-2, 2)
	
	_log("   🎲 Tirada: %d vs %d" % [roll_player, roll_enemy])
	
	if roll_player >= roll_enemy:
		# Victoria social
		_log("   🏆 ¡VICTORIA SOCIAL!")
		_apply_danza_victory(postura_key)
	else:
		# Derrota social
		_log("   💀 Derrota social.")
		_apply_danza_defeat(enemy_postura_key)
	
	_update_ui()
	
	# Después de la danza, turno del enemigo (si no fue aturdido)
	if roll_player >= roll_enemy:
		# Enemigo pierde turno por la danza
		await get_tree().create_timer(0.8).timeout
		state = CombatState.PLAYER_TURN
		_set_buttons_enabled(true)
		_log("— Tu turno. El enemigo está desconcertado.")
	else:
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()

func _apply_danza_victory(postura_key: String) -> void:
	# Socializar sube antenas y resetea contador de violencia
	_turnos_sin_social = 0
	GameManager.ganar_antena("Victoria en Danza de Antenas")
	_log("   🐜 +1 Antena. La diplomacia te fortalece.")
	match postura_key:
		"acecho":
			var dmg = GameManager.stats.get("torax", 5) * 0.5
			enemy_hp -= dmg
			_log("   → Intimidación brutal. %.0f daño psíquico. Enemigo tiembla." % dmg)
		"exposicion":
			enemy_fuerza = maxf(enemy_fuerza - 2, 1)
			enemy_defensa = maxf(enemy_defensa - 1, 0)
			_log("   → Manipulación exitosa. -2 Fuerza, -1 Defensa al enemigo.")
		"mimetismo":
			_log("   → Desapareces de su percepción. Próximo ataque = crítico.")
			# Marcar próximo ataque como crítico
			GameManager.set_meta("danza_critico", true)
		"vibracion":
			_log("   → Lees su frecuencia. Stats: HP:%d/%d | Fue:%d | Agi:%d | Def:%d" % [enemy_hp, enemy_hp_max, enemy_fuerza, enemy_agilidad, enemy_defensa])
			var heal = GameManager.turgencia_max * 0.1
			GameManager.curar(heal)
			_log("   → La calma te regenera. +%.0f Turgencia." % heal)
	GameManager.modificar_esencia(2.0, "Victoria social — la diplomacia fortalece")

func _apply_danza_defeat(enemy_postura_key: String) -> void:
	match enemy_postura_key:
		"acecho":
			var dmg = enemy_fuerza * 0.8
			GameManager.recibir_dano(dmg)
			_log("   → Te intimida. %.0f daño por estrés. Tu quitina cruje." % dmg)
		"exposicion":
			GameManager.modificar_esencia(-3.0, "Manipulado socialmente")
			_log("   → Te manipuló. -3%% Esencia. El verde se alimenta de tu vergüenza.")
		"mimetismo":
			enemy_agilidad += 2
			_log("   → Se escabulle. +2 Agilidad enemiga. Más difícil de golpear.")
		"vibracion":
			_log("   → Lee tus debilidades. Próximo ataque enemigo = crítico.")

func _enemy_choose_postura() -> String:
	# El enemigo elige basándose en su stat más alto
	var stats_map = {
		"acecho": enemy_fuerza,
		"exposicion": enemy_feromonas,
		"mimetismo": enemy_cripsis,
		"vibracion": enemy_sensilios,
	}
	
	# 60% elige su mejor stat, 40% aleatorio
	if randf() < 0.6:
		var best_key = "acecho"
		var best_val = 0.0
		for key in stats_map:
			if stats_map[key] > best_val:
				best_val = stats_map[key]
				best_key = key
		return best_key
	else:
		var keys = stats_map.keys()
		return keys[randi() % keys.size()]

func _get_enemy_social_stat(stat_name: String) -> float:
	match stat_name:
		"torax": return enemy_fuerza
		"feromonas": return enemy_feromonas
		"cripsis": return enemy_cripsis
		"sensilios": return enemy_sensilios
	return 5.0

func _check_enemy_death() -> void:
	if enemy_hp <= 0:
		enemy_hp = 0
		_update_ui()
		_log("\n💀 %s cae. Biomasa asegurada." % enemy_name)
		# Registrar en bestiario
		var vencidos = GameManager.get_meta("enemigos_vencidos", []) as Array
		if not enemy_name in vencidos:
			vencidos.append(enemy_name)
			GameManager.set_meta("enemigos_vencidos", vencidos)
			_log("   📕 ¡Nueva entrada en el Bestiario!")
		var loot = LootSystem.generar_loot()
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
	
	# El enemigo decide: atacar (físico) o provocar (social)
	# Probabilidad de provocar = FER / (FER + TOR) — enemigos sociales provocan más
	var chance_provocar = enemy_feromonas / (enemy_feromonas + enemy_fuerza + 0.1)
	
	if randf() < chance_provocar:
		# TURNO SOCIAL del enemigo
		_enemy_provocar()
		return
	
	# TURNO FÍSICO del enemigo
	# Evasión del jugador: GAN×3.5% + CRI×2.5% (cap 55%)
	var player_gan = GameManager.stats.get("ganglios", 5)
	var player_cri = GameManager.stats.get("cripsis", 5)
	var player_evasion = minf(0.55, player_gan * 0.035 + player_cri * 0.025)
	# Precisión enemiga reduce evasión
	var enemy_precision = enemy_sensilios * 0.02
	var evasion_final = maxf(0.05, player_evasion - enemy_precision)
	
	if randf() < evasion_final:
		var phrases = ENEMY_PHRASES.get(enemy_name, ["¡Muere!"])
		_log("💨 Esquivaste el ataque de %s." % enemy_name)
		await get_tree().create_timer(0.4).timeout
		state = CombatState.PLAYER_TURN
		_set_buttons_enabled(true)
		_log("— Tu turno.")
		return
	
	var base_damage = enemy_fuerza * 1.5 - GameManager.stats.get("quitina_base", 4) * 0.5 - GameManager.stats.get("armadura_equipada", 0)
	var damage = maxf(1.0, base_damage * randf_range(0.85, 1.15))
	GameManager.recibir_dano(damage)
	var phrases = ENEMY_PHRASES.get(enemy_name, ["¡Muere!"])
	_log("🩸 %s: \"%s\" (%.0f)" % [enemy_name, phrases[randi() % phrases.size()], damage])
	_update_ui()
	if GameManager.turgencia_actual <= 0:
		_log("\n💀 Tu quitina se quiebra. El Charco no perdona.")
		_end_combat(false)
	else:
		await get_tree().create_timer(0.4).timeout
		state = CombatState.PLAYER_TURN
		_set_buttons_enabled(true)
		_log("— Tu turno.")

# Frases de provocación del enemigo (por tipo)
const ENEMY_PROVOCACIONES: Dictionary = {
	"Garrapata Salvaje": [
		{"frase": "🦷 \"¡Eres tan lento que me da sueño!\"", "efecto": "debuff_gan", "valor": -1},
		{"frase": "💐 \"Hueles a presa fácil, cariño...\"", "efecto": "debuff_cri", "valor": -1},
	],
	"Cucaracha Carroñera": [
		{"frase": "🦷 \"¡Yo sobreviví al zapatazo divino! ¿Tú qué?\"", "efecto": "debuff_tor", "valor": -1},
		{"frase": "💐 \"Tu inventario es basura. Como tú.\"", "efecto": "debuff_fer", "valor": -1},
	],
	"Polilla Sedante": [
		{"frase": "📡 \"Shhh... siento tu miedo. Es delicioso.\"", "efecto": "debuff_sen", "valor": -1},
		{"frase": "💐 \"La luz me dijo que no vales nada...\"", "efecto": "debuff_gan", "valor": -2},
	],
}

func _enemy_provocar() -> void:
	var provocaciones = ENEMY_PROVOCACIONES.get(enemy_name, [
		{"frase": "🦷 \"¡No me das miedo, insecto!\"", "efecto": "debuff_tor", "valor": -1},
	])
	var prov = provocaciones[randi() % provocaciones.size()]
	
	_log("🗣️ %s provoca:" % enemy_name)
	_log("   %s" % prov["frase"])
	
	# El jugador puede resistir con Feromonas o Sensilios
	var resistencia = GameManager.stats.get("feromonas", 3) + GameManager.stats.get("sensilios", 5)
	var dificultad = enemy_feromonas + enemy_sensilios
	
	if resistencia + randi_range(-2, 2) >= dificultad:
		_log("   😤 Resistes la provocación. No te afecta.")
	else:
		# Aplicar debuff
		match prov["efecto"]:
			"debuff_tor":
				GameManager.stats["torax"] = max(GameManager.stats.get("torax", 5) + prov["valor"], 1)
				_log("   😰 Te intimida. -%d Tórax." % abs(prov["valor"]))
			"debuff_gan":
				GameManager.stats["ganglios"] = max(GameManager.stats.get("ganglios", 5) + prov["valor"], 1)
				_log("   😰 Te desconcentra. -%d Ganglios." % abs(prov["valor"]))
			"debuff_cri":
				GameManager.stats["cripsis"] = max(GameManager.stats.get("cripsis", 5) + prov["valor"], 1)
				_log("   😰 Te expone. -%d Cripsis." % abs(prov["valor"]))
			"debuff_sen":
				GameManager.stats["sensilios"] = max(GameManager.stats.get("sensilios", 5) + prov["valor"], 1)
				_log("   😰 Te nubla. -%d Sensilios." % abs(prov["valor"]))
			"debuff_fer":
				GameManager.stats["feromonas"] = max(GameManager.stats.get("feromonas", 3) + prov["valor"], 1)
				_log("   😰 Te humilla. -%d Feromonas." % abs(prov["valor"]))
	
	await get_tree().create_timer(0.5).timeout
	state = CombatState.PLAYER_TURN
	_set_buttons_enabled(true)
	_log("— Tu turno. ¿Respondes con golpes o con palabras?")

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
