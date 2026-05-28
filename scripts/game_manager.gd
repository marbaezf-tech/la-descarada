extends Node
## GameManager — Autoload Singleton
## Plaga: La Descarada
## Controla el estado global del juego: Taxón, Esencia, Recursos, Inventario
##
## DOCUMENTACIÓN:
## - Sistemas de combate: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html
## - Esencia/Silencio Verde: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html#esencia
## - Grados de Estabilidad: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html#grados
## - Trazabilidad: https://marbaezf-tech.github.io/plaga-wiki/trazabilidad.html

# ===== SEÑALES =====
signal esencia_changed(new_value: float)
signal recurso_changed(new_value: float)
signal turgencia_changed(current: float, max_val: float)
signal hemolinfa_changed(current: float, max_val: float)
signal marioneta_triggered()  # Game Over — Silencio Verde ganó
signal defecto_activated(taxon_id: String, message: String)

# ===== DATOS DEL TAXÓN =====
enum Taxon {
	ZANCUDO, CUCARACHA, AVISPA, GARRAPATA, CHINCHE,
	MARIPOSA, ARANA, ESCORPION, VINCHUCA, MOSCA,
	SANGUIJUELA, POLILLA, PULGA, TIPULA
}

const TAXON_DATA: Dictionary = {
	Taxon.ZANCUDO: {
		"nombre": "Zancudo",
		"emoji": "🦟",
		"recurso_nombre": "Sangre Fresca",
		"defecto_nombre": "Sobrecarga de Buffer",
		"stats_base": {"torax": 5, "ganglios": 7, "quitina_base": 5, "sensilios": 6, "cripsis": 8, "feromonas": 3},
		"recurso_max": 100.0,
		"faccion": "El Enjambre Negro"
	},
	Taxon.CUCARACHA: {
		"nombre": "Cucaracha",
		"emoji": "🪳",
		"recurso_nombre": "Bio-Residuos",
		"defecto_nombre": "Aura de Asco",
		"stats_base": {"torax": 5, "ganglios": 5, "quitina_base": 7, "sensilios": 7, "cripsis": 6, "feromonas": 1},
		"recurso_max": 120.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.AVISPA: {
		"nombre": "Avispa",
		"emoji": "🐝",
		"recurso_nombre": "Carne Dulce y Azúcar",
		"defecto_nombre": "Frenesí de Asado",
		"stats_base": {"torax": 7, "ganglios": 7, "quitina_base": 5, "sensilios": 4, "cripsis": 3, "feromonas": 4},
		"recurso_max": 80.0,
		"faccion": "Los Sueltos"
	},
	Taxon.GARRAPATA: {
		"nombre": "Garrapata",
		"emoji": "🕷️",
		"recurso_nombre": "Plasma Estancado",
		"defecto_nombre": "Anclaje Pesado",
		"stats_base": {"torax": 5, "ganglios": 2, "quitina_base": 9, "sensilios": 5, "cripsis": 4, "feromonas": 2},
		"recurso_max": 150.0,
		"faccion": "Los Sueltos",
		"pasivo": "tanque_regenerativo"
	},
	Taxon.CHINCHE: {
		"nombre": "Chinche de Cama",
		"emoji": "🛏️",
		"recurso_nombre": "Sangre Premium",
		"defecto_nombre": "Paladar Fino",
		"stats_base": {"torax": 3, "ganglios": 5, "quitina_base": 4, "sensilios": 6, "cripsis": 7, "feromonas": 9},
		"recurso_max": 60.0,
		"faccion": "La Colmena"
	},
	Taxon.MARIPOSA: {
		"nombre": "Mariposa",
		"emoji": "🦋",
		"recurso_nombre": "Néctar Fermentado",
		"defecto_nombre": "Alas de Cristal",
		"stats_base": {"torax": 3, "ganglios": 9, "quitina_base": 3, "sensilios": 7, "cripsis": 5, "feromonas": 10},
		"recurso_max": 70.0,
		"faccion": "La Colmena"
	},
	Taxon.ARANA: {
		"nombre": "Araña de Rincón",
		"emoji": "🕸️",
		"recurso_nombre": "Hemolinfa",
		"defecto_nombre": "Fobia Social",
		"stats_base": {"torax": 6, "ganglios": 5, "quitina_base": 5, "sensilios": 9, "cripsis": 7, "feromonas": 1},
		"recurso_max": 90.0,
		"faccion": "La Colmena"
	},
	Taxon.ESCORPION: {
		"nombre": "Escorpión",
		"emoji": "🦂",
		"recurso_nombre": "Turgencia",
		"defecto_nombre": "Fotofobia Humillante",
		"stats_base": {"torax": 7, "ganglios": 4, "quitina_base": 6, "sensilios": 5, "cripsis": 6, "feromonas": 3},
		"recurso_max": 100.0,
		"faccion": "El Enjambre Negro"
	},
	Taxon.VINCHUCA: {
		"nombre": "Vinchuca",
		"emoji": "🗡️",
		"recurso_nombre": "Sangre Inoculada",
		"defecto_nombre": "Digestión Traicionera",
		"stats_base": {"torax": 5, "ganglios": 7, "quitina_base": 5, "sensilios": 8, "cripsis": 10, "feromonas": 2},
		"recurso_max": 80.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.MOSCA: {
		"nombre": "Mosca Panteonera",
		"emoji": "🪰",
		"recurso_nombre": "Necromasa",
		"defecto_nombre": "Olor a Muerte",
		"stats_base": {"torax": 4, "ganglios": 6, "quitina_base": 5, "sensilios": 7, "cripsis": 2, "feromonas": 5},
		"recurso_max": 110.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.SANGUIJUELA: {
		"nombre": "Sanguijuela",
		"emoji": "💉",
		"recurso_nombre": "Toxinas y Filtros",
		"defecto_nombre": "Adicción Espiritual",
		"stats_base": {"torax": 4, "ganglios": 4, "quitina_base": 4, "sensilios": 6, "cripsis": 5, "feromonas": 8},
		"recurso_max": 90.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.POLILLA: {
		"nombre": "Polilla de la Luz",
		"emoji": "🌙",
		"recurso_nombre": "Fotones",
		"defecto_nombre": "Atracción Fatal",
		"stats_base": {"torax": 3, "ganglios": 7, "quitina_base": 4, "sensilios": 10, "cripsis": 4, "feromonas": 6},
		"recurso_max": 80.0,
		"faccion": "Neutral"
	},
	Taxon.PULGA: {
		"nombre": "Pulga",
		"emoji": "⚡",
		"recurso_nombre": "Flujo Cinético",
		"defecto_nombre": "Hiperactividad Crónica",
		"stats_base": {"torax": 4, "ganglios": 10, "quitina_base": 4, "sensilios": 6, "cripsis": 5, "feromonas": 5},
		"recurso_max": 70.0,
		"faccion": "Los Sueltos",
		"pasivo": "evasion_maestra"
	},
	Taxon.TIPULA: {
		"nombre": "Típula",
		"emoji": "🦟",
		"recurso_nombre": "Calor Robado",
		"defecto_nombre": "Cristal Ambulante",
		"stats_base": {"torax": 3, "ganglios": 8, "quitina_base": 2, "sensilios": 10, "cripsis": 8, "feromonas": 9},
		"recurso_max": 60.0,
		"faccion": "Los Parásitos Libres"
	}
}

# ===== ATAVISMOS POR TAXÓN =====
# Cada taxón tiene: 1 Melee (daño), 1 Social (debuff/presión), 1 Utilidad (evasión/stun/heal)
const ATAVISMOS_DATA: Dictionary = {
	Taxon.ZANCUDO: [
		{"nombre": "Micro-Inyección", "costo": 3, "tipo": "melee", "efecto": "veneno", "desc": "Veneno: 4 daño/turno ×3", "valor": 4.0},
		{"nombre": "Zumbido Hipnótico", "costo": 2, "tipo": "social", "efecto": "confuso", "desc": "Enemigo se ataca solo (30%)", "valor": 0.3},
		{"nombre": "Vuelo Errático", "costo": 3, "tipo": "utilidad", "efecto": "evasion", "desc": "+40% evasión 2 turnos", "valor": 0.4},
	],
	Taxon.CUCARACHA: [
		{"nombre": "Embestida Quitinosa", "costo": 3, "tipo": "melee", "efecto": "penetrar", "desc": "Ignora 50% armadura. x1.5", "valor": 1.5},
		{"nombre": "Aura de Asco", "costo": 2, "tipo": "social", "efecto": "miedo", "desc": "Enemigo pierde turno (asco)", "valor": 1.0},
		{"nombre": "Caparazón de Emergencia", "costo": 4, "tipo": "utilidad", "efecto": "inmune", "desc": "Inmune 1 turno. No atacas.", "valor": 1.0},
	],
	Taxon.AVISPA: [
		{"nombre": "Picada Frenética", "costo": 4, "tipo": "melee", "efecto": "multi", "desc": "3 ataques al 60%", "valor": 0.6},
		{"nombre": "Feromona de Guerra", "costo": 3, "tipo": "social", "efecto": "miedo", "desc": "Enemigo pierde turno (terror)", "valor": 1.0},
		{"nombre": "Mandíbula de Acero", "costo": 3, "tipo": "melee", "efecto": "penetrar", "desc": "Ignora armadura. x1.8", "valor": 1.8},
	],
	Taxon.GARRAPATA: [
		{"nombre": "Anclaje Vital", "costo": 3, "tipo": "melee", "efecto": "drenar", "desc": "Drena 20% HP enemigo → te cura igual", "valor": 0.2},
		{"nombre": "Coraza Ancestral", "costo": 4, "tipo": "utilidad", "efecto": "armadura", "desc": "+6 Defensa 4 turnos (muro)", "valor": 6.0},
		{"nombre": "Presión Parasitaria", "costo": 2, "tipo": "social", "efecto": "stun", "desc": "Se ancla al enemigo. Pierde turno + drena 5 HP.", "valor": 5.0},
	],
	Taxon.CHINCHE: [
		{"nombre": "Mordida Nocturna", "costo": 3, "tipo": "melee", "efecto": "drenar", "desc": "Drena 10% HP + heal", "valor": 0.1},
		{"nombre": "Decreto Real", "costo": 2, "tipo": "social", "efecto": "confuso", "desc": "Enemigo se golpea solo", "valor": 1.0},
		{"nombre": "Sábanas de Seda", "costo": 3, "tipo": "utilidad", "efecto": "evasion", "desc": "+35% evasión 2 turnos", "valor": 0.35},
	],
	Taxon.MARIPOSA: [
		{"nombre": "Polvo Cegador", "costo": 2, "tipo": "melee", "efecto": "veneno", "desc": "3 daño/turno + ciego", "valor": 3.0},
		{"nombre": "Mirada Morpho", "costo": 3, "tipo": "social", "efecto": "stun", "desc": "Hipnotiza. Pierde 2 turnos.", "valor": 2.0},
		{"nombre": "Aleteo Dimensional", "costo": 4, "tipo": "utilidad", "efecto": "esquiva", "desc": "Esquiva 100% próximo ataque", "valor": 1.0},
	],
	Taxon.ARANA: [
		{"nombre": "Necrosis Letal", "costo": 4, "tipo": "melee", "efecto": "critico", "desc": "Veneno necrótico x2.5 (ignora def)", "valor": 2.5},
		{"nombre": "Red de Contención", "costo": 3, "tipo": "social", "efecto": "stun", "desc": "Inmoviliza 2 turnos (telaraña)", "valor": 2.0},
		{"nombre": "Emboscada Silenciosa", "costo": 2, "tipo": "utilidad", "efecto": "stun", "desc": "Stun 1 turno + próximo ataque crítico", "valor": 1.0},
	],
	Taxon.ESCORPION: [
		{"nombre": "Golpe de Pinza", "costo": 5, "tipo": "melee", "efecto": "critico", "desc": "Daño x2.5 ignora armadura", "valor": 2.5},
		{"nombre": "Ultravioleta y Abismo", "costo": 3, "tipo": "social", "efecto": "miedo", "desc": "Terror puro. Pierde turno.", "valor": 1.0},
		{"nombre": "Sombra de Pinza", "costo": 3, "tipo": "utilidad", "efecto": "sigilo", "desc": "Próximo ataque = crítico x2", "valor": 2.0},
	],
	Taxon.VINCHUCA: [
		{"nombre": "Mordida Silenciosa", "costo": 3, "tipo": "melee", "efecto": "robar", "desc": "Daño x1.5 + roba item", "valor": 1.5},
		{"nombre": "Regalo de Chagas", "costo": 4, "tipo": "social", "efecto": "veneno", "desc": "Veneno social: -2 stats/turno", "valor": 2.0},
		{"nombre": "Desvanecimiento", "costo": 2, "tipo": "utilidad", "efecto": "esquiva", "desc": "Invisible. Esquiva 100%.", "valor": 1.0},
	],
	Taxon.MOSCA: [
		{"nombre": "Invocar Larva Tanque", "costo": 4, "tipo": "melee", "efecto": "golem", "desc": "Larva absorbe 25 daño (tanquea por ti)", "valor": 25.0},
		{"nombre": "Espíritu de Carroña", "costo": 3, "tipo": "melee", "efecto": "larva", "desc": "Espíritu ataca: 6 daño/turno ×3", "valor": 6.0},
		{"nombre": "Hedor Paralizante", "costo": 2, "tipo": "social", "efecto": "stun", "desc": "Olor a muerte. Enemigo pierde 2 turnos.", "valor": 2.0},
	],
	Taxon.SANGUIJUELA: [
		{"nombre": "Éxtasis Tóxico", "costo": 3, "tipo": "melee", "efecto": "drenar", "desc": "Drena 12% HP + adicción", "valor": 0.12},
		{"nombre": "Anestesia Extática", "costo": 3, "tipo": "social", "efecto": "stun", "desc": "Placer paralizante. Pierde turno.", "valor": 1.0},
		{"nombre": "Camuflaje Adaptativo", "costo": 2, "tipo": "utilidad", "efecto": "evasion", "desc": "+45% evasión 2 turnos", "valor": 0.45},
	],
	Taxon.POLILLA: [
		{"nombre": "Rayo Lunar", "costo": 3, "tipo": "melee", "efecto": "critico", "desc": "Daño x2 (luz concentrada)", "valor": 2.0},
		{"nombre": "Síndrome del Foco", "costo": 3, "tipo": "social", "efecto": "confuso", "desc": "Enemigo se daña solo (hipnosis)", "valor": 1.0},
		{"nombre": "Polvo de Ala", "costo": 2, "tipo": "utilidad", "efecto": "evasion", "desc": "+50% evasión 1 turno", "valor": 0.5},
	],
	Taxon.PULGA: [
		{"nombre": "Salto Demoledor", "costo": 3, "tipo": "melee", "efecto": "critico", "desc": "Impacto cinético x2", "valor": 2.0},
		{"nombre": "Truco de la Moneda", "costo": 2, "tipo": "social", "efecto": "aleatorio", "desc": "50%: daño x3 o fallo total", "valor": 3.0},
		{"nombre": "Salto Dimensional", "costo": 1, "tipo": "utilidad", "efecto": "esquiva", "desc": "Esquiva 100% próximo ataque", "valor": 1.0},
	],
	Taxon.TIPULA: [
		{"nombre": "Autotomía Táctica", "costo": 2, "tipo": "melee", "efecto": "multi", "desc": "Sacrifica pata: 2 golpes x1.2", "valor": 1.2},
		{"nombre": "Ocelo Ancestral", "costo": 3, "tipo": "social", "efecto": "revelar", "desc": "Lee mente: revela stats + debuff -2", "valor": 2.0},
		{"nombre": "Extracción del Terror", "costo": 4, "tipo": "utilidad", "efecto": "terror_heal", "desc": "Absorbe miedo: +30% Turgencia", "valor": 0.3},
	],
}

func obtener_atavismos() -> Array:
	return ATAVISMOS_DATA.get(taxon_actual, [])

# ===== ESTADO DEL JUGADOR =====
var taxon_actual: Taxon = Taxon.ZANCUDO
var nombre_plaga: String = ""

# Esencia de Taxón (El Silencio Verde)
var esencia: float = 100.0  # 0 = Marioneta (Game Over)

# Antenas Sociales (0-10) — indicador de socialización en combate
# Si solo pegas sin socializar, bajan. Si socializas, suben.
# 0 antenas = el hongo avanza (-5% Esencia por combate)
# 10 antenas = bonus social (+2 a tiradas de Danza)
var antenas: int = 5  # Empieza en 5/10
const ANTENAS_MAX: int = 10

# Recursos vitales
var turgencia_actual: float = 100.0
var turgencia_max: float = 100.0
var hemolinfa_actual: float = 50.0
var hemolinfa_max: float = 50.0
var recurso_taxon: float = 50.0

# Instinto (Willpower — chispazos ganglionares para esfuerzos supremos)
var instinto_actual: int = 5
var instinto_max: int = 5

# Stats
var stats: Dictionary = {}

# Inventario (max 20)
var inventario: Array = []
const INVENTARIO_MAX: int = 20

# Reputación con facciones (-100 a +100)
var reputacion: Dictionary = {
	"La Colmena": 0,
	"El Enjambre Negro": 0,
	"Los Sueltos": 0,
	"Los Parásitos Libres": 0
}

# Zona actual
var zona_actual: String = "El Laboratorio"
var zonas_descubiertas: Array = []

# Experiencia
var experiencia: float = 0.0
var nivel: int = 1

# Turnos sin moverse (para Pulgas)
var turnos_quieto: int = 0

# ===== INICIALIZACIÓN =====
func inicializar_plaga(taxon: Taxon, nombre: String) -> void:
	taxon_actual = taxon
	nombre_plaga = nombre
	var data = TAXON_DATA[taxon]
	stats = data["stats_base"].duplicate()
	recurso_taxon = data["recurso_max"] * 0.5  # Empieza al 50%
	turgencia_max = 80.0 + stats["quitina_base"] * 4.0
	turgencia_actual = turgencia_max
	hemolinfa_max = 30.0 + stats["sensilios"] * 4.0
	hemolinfa_actual = hemolinfa_max
	esencia = 100.0
	print("🦟 Plaga inicializada: %s [%s]" % [nombre, data["nombre"]])

func reset() -> void:
	## Resetea todo el estado del juego para volver al menú limpio
	taxon_actual = Taxon.ZANCUDO
	nombre_plaga = ""
	esencia = 100.0
	antenas = 5
	turgencia_actual = 100.0
	turgencia_max = 100.0
	hemolinfa_actual = 50.0
	hemolinfa_max = 50.0
	recurso_taxon = 50.0
	stats = {}
	inventario = []
	reputacion = {
		"La Colmena": 0,
		"El Enjambre Negro": 0,
		"Los Sueltos": 0,
		"Los Parásitos Libres": 0
	}
	zona_actual = "El Laboratorio"
	zonas_descubiertas = []
	experiencia = 0.0
	nivel = 1
	turnos_quieto = 0
	print("🔄 GameManager reseteado")

# ===== SISTEMA DE ESENCIA (SILENCIO VERDE) =====
func modificar_esencia(cantidad: float, razon: String) -> void:
	var anterior = esencia
	esencia = clampf(esencia + cantidad, 0.0, 100.0)
	esencia_changed.emit(esencia)
	
	if cantidad < 0:
		print("🍄 Esencia -%s: %s [%s → %s]" % [abs(cantidad), razon, anterior, esencia])
		# Verificar cambio de fase
		_check_fase_infeccion(anterior, esencia)
	else:
		print("✨ Esencia +%s: %s [%s → %s]" % [cantidad, razon, anterior, esencia])
	
	# Verificar Marioneta (Game Over)
	if esencia <= 0.0:
		_activar_marioneta()

func _check_fase_infeccion(anterior: float, actual: float) -> void:
	# Fase Susurros (75%)
	if anterior > 75.0 and actual <= 75.0:
		print("🟡 FASE: Susurros. El hongo te habla. -1 Sensilios.")
		stats["sensilios"] = max(stats.get("sensilios", 5) - 1, 1)
	# Fase Parasitismo (50%)
	if anterior > 50.0 and actual <= 50.0:
		print("🟠 FASE: Parasitismo. +1 Tórax, -2 Ganglios. Más letal, más torpe.")
		stats["torax"] = stats.get("torax", 5) + 1
		stats["ganglios"] = max(stats.get("ganglios", 5) - 2, 1)
	# Fase Dominación (25%)
	if anterior > 25.0 and actual <= 25.0:
		print("🔴 FASE: Dominación. El hongo toma control parcial. -3 a todo.")
		for key in ["torax", "ganglios", "sensilios", "cripsis", "feromonas"]:
			stats[key] = max(stats.get(key, 5) - 1, 1)

func _activar_marioneta() -> void:
	print("💀 [ASIMILADO] Tu voluntad se apaga. Los filamentos verdes brotan de tus ojos.")
	marioneta_triggered.emit()
	_mostrar_asimilado()

func _mostrar_game_over() -> void:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree: return
	
	var fin = CanvasLayer.new()
	fin.layer = 100
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.1, 0, 0, 0.95)
	fin.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.25
	vbox.anchor_right = 0.5
	vbox.offset_left = -200
	vbox.offset_right = 200
	vbox.add_theme_constant_override("separation", 12)
	fin.add_child(vbox)
	
	var t1 = Label.new()
	t1.text = "💀 QUITINA QUEBRADA"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 20)
	t1.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	vbox.add_child(t1)
	
	var t2 = Label.new()
	t2.text = "Tu exoesqueleto se fractura.\nLa presión interna cede.\nEl Gran Charco reclama otro cadáver."
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD
	t2.add_theme_font_size_override("font_size", 11)
	t2.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3))
	vbox.add_child(t2)
	
	var t3 = Label.new()
	t3.text = "\n\"El Charco no perdona la debilidad.\nPero siempre acepta más biomasa.\""
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_theme_font_size_override("font_size", 10)
	t3.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(t3)
	
	var btn = Button.new()
	btn.text = "Volver al Menú"
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func():
		reset()
		scene_tree.change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(btn)
	
	scene_tree.current_scene.add_child(fin)

func _mostrar_asimilado() -> void:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree: return
	
	var fin = CanvasLayer.new()
	fin.layer = 100
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0, 0.05, 0, 0.95)
	fin.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.2
	vbox.anchor_right = 0.5
	vbox.offset_left = -220
	vbox.offset_right = 220
	vbox.add_theme_constant_override("separation", 12)
	fin.add_child(vbox)
	
	var t1 = Label.new()
	t1.text = "🍄 A S I M I L A D O"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 22)
	t1.add_theme_color_override("font_color", Color(0.2, 0.9, 0.1))
	vbox.add_child(t1)
	
	var t2 = Label.new()
	t2.text = "Los filamentos verdes brotan de tus ojos compuestos.\nTu voluntad se apaga como una luz fundida.\nYa no eres tú.\n\nEres un dron más en la marcha de\nLa Colmena Silenciosa."
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD
	t2.add_theme_font_size_override("font_size", 11)
	t2.add_theme_color_override("font_color", Color(0.4, 0.8, 0.2))
	vbox.add_child(t2)
	
	var t3 = Label.new()
	t3.text = "\n\"El Silencio Verde no te mató.\nTe mejoró. Ahora eres parte de algo\nmás grande que tu patética individualidad.\""
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_theme_font_size_override("font_size", 10)
	t3.add_theme_color_override("font_color", Color(0.3, 0.6, 0.2))
	vbox.add_child(t3)
	
	var t4 = Label.new()
	t4.text = "— El Silencio Verde"
	t4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t4.add_theme_font_size_override("font_size", 9)
	t4.add_theme_color_override("font_color", Color(0.2, 0.4, 0.1))
	vbox.add_child(t4)
	
	var btn = Button.new()
	btn.text = "Aceptar el Silencio"
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func():
		reset()
		scene_tree.change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(btn)
	
	scene_tree.current_scene.add_child(fin)

# ===== SISTEMA DE ANTENAS SOCIALES =====
func ganar_antena(razon: String) -> void:
	if antenas < ANTENAS_MAX:
		antenas += 1
		print("🐜 +1 Antena: %s [%d/%d]" % [razon, antenas, ANTENAS_MAX])
	if antenas >= ANTENAS_MAX:
		modificar_esencia(2.0, "Antenas al máximo — el hongo retrocede")

func perder_antena(razon: String) -> void:
	if antenas > 0:
		antenas -= 1
		print("🐜 -1 Antena: %s [%d/%d]" % [razon, antenas, ANTENAS_MAX])
	if antenas <= 0:
		modificar_esencia(-5.0, "Sin antenas — violencia pura. El Cordyceps celebra.")
		print("🍄 ¡ALERTA! Antenas en 0. El hongo avanza. Socializa o serás asimilado.")

func get_bonus_antenas() -> int:
	## Bonus a tiradas sociales según nivel de antenas
	if antenas >= 9: return 3
	if antenas >= 7: return 2
	if antenas >= 5: return 1
	if antenas >= 3: return 0
	return -2  # Penalización si estás muy bajo

# ===== ACCIONES QUE AFECTAN ESENCIA =====
func accion_matar_sin_justificacion() -> void:
	modificar_esencia(-10.0, "Asesinato injustificado — el verde se alimenta de tu violencia")

func accion_recurso_corrupto() -> void:
	modificar_esencia(-5.0, "Consumiste basura tóxica — las esporas celebran")

func accion_habilidad_excesiva() -> void:
	modificar_esencia(-3.0, "Abusaste de tus poderes — el hongo toma nota")

func accion_fallo_enjambre() -> void:
	modificar_esencia(-8.0, "Perdiste el control — el enjambre habló por ti")

func accion_traicion() -> void:
	modificar_esencia(-7.0, "Traicionaste a un aliado — la soledad es fertilizante")

func accion_violar_fumigacion() -> void:
	modificar_esencia(-5.0, "Te vieron los Gigantes — el estrés debilita tu voluntad")
	reputacion["La Colmena"] = max(reputacion["La Colmena"] - 10, -100)

func accion_diablerie() -> void:
	modificar_esencia(-15.0, "Consumiste un fósil del Gran Éter — poder a cambio de tu alma")

func accion_descanso() -> void:
	modificar_esencia(3.0, "Descansaste en tu Nido — tu hogar te ancla")

func accion_quest_pacifica() -> void:
	modificar_esencia(5.0, "Resolviste sin violencia — el verde retrocede")

func accion_ayudar_aliado() -> void:
	modificar_esencia(2.0, "Ayudaste a otro — la conexión combate al hongo")

func accion_meditar_panal() -> void:
	modificar_esencia(5.0, "Meditaste en El Panal — el silencio sagrado ahoga al verde")

func accion_resistir_enjambre() -> void:
	modificar_esencia(4.0, "Resististe el impulso — cada 'no' te hace más fuerte")

# ===== SISTEMA DE RECURSOS =====
func consumir_recurso(cantidad: float) -> bool:
	var data = TAXON_DATA[taxon_actual]
	if recurso_taxon >= cantidad:
		recurso_taxon -= cantidad
		recurso_changed.emit(recurso_taxon)
		return true
	return false

func obtener_recurso(cantidad: float) -> void:
	var data = TAXON_DATA[taxon_actual]
	recurso_taxon = minf(recurso_taxon + cantidad, data["recurso_max"])
	recurso_changed.emit(recurso_taxon)

func esta_hambriento() -> bool:
	var data = TAXON_DATA[taxon_actual]
	return recurso_taxon < data["recurso_max"] * 0.2

# ===== SISTEMA DE COMBATE =====
# ===== SISTEMA DE COMBATE =====
func calcular_velocidad() -> float:
	## Velocidad (Iniciativa) = (Agilidad + Percepción) / 2
	return (stats.get("ganglios", 5) + stats.get("sensilios", 5)) / 2.0

func usar_habilidad_taxon(objetivo_agilidad: float) -> Dictionary:
	## Habilidad del Zancudo: Micro-Inyección de Parálisis
	## Costo: 3 Hemolinfa | Efecto: -50% Agilidad enemigo por 2 turnos, anula esquiva
	var costo: float = 3.0
	if not gastar_hemolinfa(costo):
		return {"exito": false, "mensaje": "Hemolinfa insuficiente para la Micro-Inyección."}
	
	# Evaluar impacto en Esencia (uso de habilidad)
	# No penaliza si es el primer uso del combate
	var reduccion_agilidad = objetivo_agilidad * 0.5
	
	return {
		"exito": true,
		"mensaje": "Micro-Inyección de Parálisis. El neuro-bloqueador fluye. -50%% Agilidad por 2 turnos.",
		"efecto": "paralisis",
		"reduccion_agilidad": reduccion_agilidad,
		"duracion_turnos": 2
	}

func recibir_dano(cantidad: float) -> void:
	turgencia_actual = maxf(turgencia_actual - cantidad, 0.0)
	turgencia_changed.emit(turgencia_actual, turgencia_max)
	if turgencia_actual <= 0.0:
		print("💀 Turgencia agotada — la Plaga cae")
		_mostrar_game_over()

func curar(cantidad: float) -> void:
	turgencia_actual = minf(turgencia_actual + cantidad, turgencia_max)
	turgencia_changed.emit(turgencia_actual, turgencia_max)
	# Defecto Zancudo: Sobrecarga de Buffer
	if taxon_actual == Taxon.ZANCUDO and turgencia_actual > turgencia_max * 0.8:
		defecto_activated.emit("ZANCUDO", "Te hinchaste demasiado. Velocidad reducida. Un golpe crítico y EXPLOTAS.")

func gastar_hemolinfa(cantidad: float) -> bool:
	if hemolinfa_actual >= cantidad:
		hemolinfa_actual -= cantidad
		hemolinfa_changed.emit(hemolinfa_actual, hemolinfa_max)
		return true
	return false

# ===== INVENTARIO =====
func agregar_item(item: Dictionary) -> bool:
	if inventario.size() >= INVENTARIO_MAX:
		return false
	inventario.append(item)
	print("📦 Item agregado: %s %s [%s] — Inventario: %d/%d" % [item.get("emoji",""), item.get("nombre","?"), item.get("tier","?"), inventario.size(), INVENTARIO_MAX])
	return true

func remover_item(index: int) -> void:
	if index >= 0 and index < inventario.size():
		inventario.remove_at(index)

# ===== EXPERIENCIA =====
func ganar_exp(cantidad: float) -> void:
	experiencia += cantidad
	var exp_para_subir = nivel * 20.0
	if experiencia >= exp_para_subir:
		experiencia -= exp_para_subir
		nivel += 1
		turgencia_max += 5.0
		hemolinfa_max += 3.0
		turgencia_actual = turgencia_max
		hemolinfa_actual = hemolinfa_max
		turgencia_changed.emit(turgencia_actual, turgencia_max)
		hemolinfa_changed.emit(hemolinfa_actual, hemolinfa_max)
		print("⬆️ ¡NIVEL %d! Turgencia max: %.0f | Hemolinfa max: %.0f" % [nivel, turgencia_max, hemolinfa_max])

# ===== REPUTACIÓN =====
func modificar_reputacion(faccion: String, cantidad: int) -> void:
	if reputacion.has(faccion):
		reputacion[faccion] = clampi(reputacion[faccion] + cantidad, -100, 100)

func es_hostil(faccion: String) -> bool:
	return reputacion.get(faccion, 0) < -50

func es_aliado(faccion: String) -> bool:
	return reputacion.get(faccion, 0) > 50
