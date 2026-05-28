extends CanvasLayer
## CombatManager — Combate por turnos estilo Pokémon
## Prota de espalda abajo-izquierda, Enemigo de frente arriba-derecha

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
var player_hp_bar: ProgressBar
var player_hp_label: Label
var player_name_label: Label
var log_label: RichTextLabel
var btn_atacar: Button
var btn_habilidad: Button
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
	
	# --- ENEMIGO: imagen de fondo + stats a la derecha ---
	# Avatar enemigo como fondo de la zona de batalla
	enemy_avatar = _create_avatar_fullscreen(enemy_name)
	battle_zone.add_child(enemy_avatar)
	
	# Stats del enemigo (derecha, sobre la imagen)
	var enemy_container = VBoxContainer.new()
	enemy_container.position = Vector2(460, 15)
	enemy_container.custom_minimum_size = Vector2(170, 0)
	battle_zone.add_child(enemy_container)
	
	# Nombre enemigo
	enemy_name_label = Label.new()
	enemy_name_label.text = "🎯 %s" % enemy_name
	enemy_name_label.add_theme_font_size_override("font_size", 11)
	enemy_name_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	enemy_container.add_child(enemy_name_label)
	
	# HP bar enemigo
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
	
	# --- JUGADOR: abajo-izquierda ---
	var player_container = VBoxContainer.new()
	player_container.position = Vector2(100, 130)
	player_container.custom_minimum_size = Vector2(200, 0)
	battle_zone.add_child(player_container)
	
	# Nombre jugador
	player_name_label = Label.new()
	var taxon_data = GameManager.TAXON_DATA[GameManager.taxon_actual]
	player_name_label.text = "%s %s" % [taxon_data["emoji"], GameManager.nombre_plaga]
	player_name_label.add_theme_font_size_override("font_size", 11)
	player_name_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
	player_container.add_child(player_name_label)
	
	# HP bar jugador
	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(160, 10)
	player_hp_bar.max_value = GameManager.turgencia_max
	player_hp_bar.value = GameManager.turgencia_actual
	player_hp_bar.show_percentage = false
	player_container.add_child(player_hp_bar)
	
	player_hp_label = Label.new()
	player_hp_label.text = "HP: %d/%d" % [GameManager.turgencia_actual, GameManager.turgencia_max]
	player_hp_label.add_theme_font_size_override("font_size", 9)
	player_container.add_child(player_hp_label)
	
	# Avatar jugador (DE ESPALDA, al lado izquierdo de la barra de HP)
	player_avatar = _create_player_avatar()
	player_avatar.position = Vector2(15, 115)
	battle_zone.add_child(player_avatar)
	
	# === ZONA DE COMANDOS (abajo ~40%) ===
	var cmd_panel = PanelContainer.new()
	cmd_panel.anchor_top = 0.55
	cmd_panel.anchor_right = 1.0
	cmd_panel.anchor_bottom = 1.0
	cmd_panel.offset_left = 10
	cmd_panel.offset_right = -10
	cmd_panel.offset_bottom = -10
	add_child(cmd_panel)
	
	var cmd_vbox = VBoxContainer.new()
	cmd_vbox.add_theme_constant_override("separation", 4)
	cmd_panel.add_child(cmd_vbox)
	
	# Log de combate
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 70)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.scroll_following = true
	log_label.add_theme_font_size_override("normal_font_size", 9)
	cmd_vbox.add_child(log_label)
	
	# Separador
	cmd_vbox.add_child(HSeparator.new())
	
	# Botones de acción (Atacar / Atavismo / Retirada)
	var btn_grid = GridContainer.new()
	btn_grid.columns = 3
	btn_grid.add_theme_constant_override("h_separation", 8)
	btn_grid.add_theme_constant_override("v_separation", 4)
	cmd_vbox.add_child(btn_grid)
	
	btn_atacar = Button.new()
	btn_atacar.text = "⚔️ Atacar"
	btn_atacar.custom_minimum_size = Vector2(130, 28)
	btn_atacar.add_theme_font_size_override("font_size", 11)
	btn_atacar.pressed.connect(_on_atacar)
	btn_grid.add_child(btn_atacar)
	
	btn_habilidad = Button.new()
	btn_habilidad.text = "🧬 Atavismo"
	btn_habilidad.custom_minimum_size = Vector2(130, 28)
	btn_habilidad.add_theme_font_size_override("font_size", 11)
	btn_habilidad.pressed.connect(_on_habilidad)
	btn_grid.add_child(btn_habilidad)
	
	btn_huir = Button.new()
	btn_huir.text = "🏃 Retirada"
	btn_huir.custom_minimum_size = Vector2(130, 28)
	btn_huir.add_theme_font_size_override("font_size", 11)
	btn_huir.pressed.connect(_on_huir)
	btn_grid.add_child(btn_huir)

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
	btn_huir.disabled = not enabled

func _log(text: String) -> void:
	log_label.text += text + "\n"

func _on_atacar() -> void:
	if state != CombatState.PLAYER_TURN: return
	state = CombatState.ANIMATING
	_set_buttons_enabled(false)
	var player_fuerza = GameManager.stats.get("torax", 5)
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
	_log("🧬 Atavismo activado. Neuro-bloqueador inyectado.")
	enemy_agilidad *= 0.5
	var damage = GameManager.stats.get("torax", 5) * 1.5
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
	var base_damage = enemy_fuerza * 1.5 - GameManager.stats.get("quitina_base", 4) - GameManager.stats.get("armadura_equipada", 0)
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
