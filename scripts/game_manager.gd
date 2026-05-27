extends Node
## GameManager — Autoload Singleton
## Plaga: La Descarada
## Controla el estado global del juego: Taxón, Esencia, Recursos, Inventario

# ===== SEÑALES =====
signal esencia_changed(new_value: float)
signal recurso_changed(new_value: float)
signal quitina_changed(current: float, max_val: float)
signal hemolinfa_changed(current: float, max_val: float)
signal marioneta_triggered()  # Game Over — Silencio Verde ganó
signal defecto_activated(taxon_id: String, message: String)

# ===== DATOS DEL TAXÓN =====
enum Taxon {
	ZANCUDO, CUCARACHA, AVISPA, GARRAPATA, CHINCHE,
	MARIPOSA, ARANA, ESCORPION, VINCHUCA, MOSCA,
	SANGUIJUELA, POLILLA, PULGA
}

const TAXON_DATA: Dictionary = {
	Taxon.ZANCUDO: {
		"nombre": "Zancudo",
		"emoji": "🦟",
		"recurso_nombre": "Sangre Fresca",
		"defecto_nombre": "Sobrecarga de Buffer",
		"stats_base": {"fuerza": 5, "agilidad": 7, "resistencia": 4, "percepcion": 6, "sigilo": 8, "carisma": 3},
		"recurso_max": 100.0,
		"faccion": "El Enjambre Negro"
	},
	Taxon.CUCARACHA: {
		"nombre": "Cucaracha",
		"emoji": "🪳",
		"recurso_nombre": "Bio-Residuos",
		"defecto_nombre": "Aura de Asco",
		"stats_base": {"fuerza": 6, "agilidad": 5, "resistencia": 9, "percepcion": 7, "sigilo": 6, "carisma": 1},
		"recurso_max": 120.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.AVISPA: {
		"nombre": "Avispa",
		"emoji": "🐝",
		"recurso_nombre": "Carne Dulce y Azúcar",
		"defecto_nombre": "Frenesí de Asado",
		"stats_base": {"fuerza": 8, "agilidad": 7, "resistencia": 5, "percepcion": 4, "sigilo": 3, "carisma": 4},
		"recurso_max": 80.0,
		"faccion": "Los Sueltos"
	},
	Taxon.GARRAPATA: {
		"nombre": "Garrapata",
		"emoji": "🕷️",
		"recurso_nombre": "Plasma Estancado",
		"defecto_nombre": "Anclaje Pesado",
		"stats_base": {"fuerza": 7, "agilidad": 2, "resistencia": 10, "percepcion": 5, "sigilo": 4, "carisma": 2},
		"recurso_max": 150.0,
		"faccion": "Los Sueltos"
	},
	Taxon.CHINCHE: {
		"nombre": "Chinche de Cama",
		"emoji": "🛏️",
		"recurso_nombre": "Sangre Premium",
		"defecto_nombre": "Paladar Fino",
		"stats_base": {"fuerza": 3, "agilidad": 4, "resistencia": 4, "percepcion": 6, "sigilo": 7, "carisma": 9},
		"recurso_max": 60.0,
		"faccion": "La Colmena"
	},
	Taxon.MARIPOSA: {
		"nombre": "Mariposa",
		"emoji": "🦋",
		"recurso_nombre": "Néctar Fermentado",
		"defecto_nombre": "Alas de Cristal",
		"stats_base": {"fuerza": 2, "agilidad": 9, "resistencia": 2, "percepcion": 7, "sigilo": 5, "carisma": 10},
		"recurso_max": 70.0,
		"faccion": "La Colmena"
	},
	Taxon.ARANA: {
		"nombre": "Araña de Rincón",
		"emoji": "🕸️",
		"recurso_nombre": "Hemolinfa",
		"defecto_nombre": "Fobia Social",
		"stats_base": {"fuerza": 4, "agilidad": 5, "resistencia": 5, "percepcion": 9, "sigilo": 7, "carisma": 1},
		"recurso_max": 90.0,
		"faccion": "La Colmena"
	},
	Taxon.ESCORPION: {
		"nombre": "Escorpión",
		"emoji": "🦂",
		"recurso_nombre": "Quitina",
		"defecto_nombre": "Fotofobia Humillante",
		"stats_base": {"fuerza": 8, "agilidad": 4, "resistencia": 8, "percepcion": 5, "sigilo": 6, "carisma": 3},
		"recurso_max": 100.0,
		"faccion": "El Enjambre Negro"
	},
	Taxon.VINCHUCA: {
		"nombre": "Vinchuca",
		"emoji": "🗡️",
		"recurso_nombre": "Sangre Inoculada",
		"defecto_nombre": "Digestión Traicionera",
		"stats_base": {"fuerza": 5, "agilidad": 6, "resistencia": 5, "percepcion": 8, "sigilo": 10, "carisma": 2},
		"recurso_max": 80.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.MOSCA: {
		"nombre": "Mosca Panteonera",
		"emoji": "🪰",
		"recurso_nombre": "Necromasa",
		"defecto_nombre": "Olor a Muerte",
		"stats_base": {"fuerza": 4, "agilidad": 6, "resistencia": 5, "percepcion": 7, "sigilo": 2, "carisma": 5},
		"recurso_max": 110.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.SANGUIJUELA: {
		"nombre": "Sanguijuela",
		"emoji": "💉",
		"recurso_nombre": "Toxinas y Filtros",
		"defecto_nombre": "Adicción Espiritual",
		"stats_base": {"fuerza": 3, "agilidad": 4, "resistencia": 6, "percepcion": 6, "sigilo": 5, "carisma": 8},
		"recurso_max": 90.0,
		"faccion": "Los Parásitos Libres"
	},
	Taxon.POLILLA: {
		"nombre": "Polilla de la Luz",
		"emoji": "🌙",
		"recurso_nombre": "Fotones",
		"defecto_nombre": "Atracción Fatal",
		"stats_base": {"fuerza": 3, "agilidad": 7, "resistencia": 3, "percepcion": 10, "sigilo": 4, "carisma": 6},
		"recurso_max": 80.0,
		"faccion": "Neutral"
	},
	Taxon.PULGA: {
		"nombre": "Pulga",
		"emoji": "⚡",
		"recurso_nombre": "Flujo Cinético",
		"defecto_nombre": "Hiperactividad Crónica",
		"stats_base": {"fuerza": 4, "agilidad": 10, "resistencia": 3, "percepcion": 6, "sigilo": 5, "carisma": 5},
		"recurso_max": 70.0,
		"faccion": "Los Sueltos"
	}
}

# ===== ESTADO DEL JUGADOR =====
var taxon_actual: Taxon = Taxon.ZANCUDO
var nombre_plaga: String = ""

# Esencia de Taxón (El Silencio Verde)
var esencia: float = 100.0  # 0 = Marioneta (Game Over)

# Recursos vitales
var quitina_actual: float = 100.0
var quitina_max: float = 100.0
var hemolinfa_actual: float = 50.0
var hemolinfa_max: float = 50.0
var recurso_taxon: float = 50.0

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
	quitina_max = 80.0 + stats["resistencia"] * 4.0
	quitina_actual = quitina_max
	hemolinfa_max = 30.0 + stats["percepcion"] * 4.0
	hemolinfa_actual = hemolinfa_max
	esencia = 100.0
	print("🦟 Plaga inicializada: %s [%s]" % [nombre, data["nombre"]])

# ===== SISTEMA DE ESENCIA (SILENCIO VERDE) =====
func modificar_esencia(cantidad: float, razon: String) -> void:
	var anterior = esencia
	esencia = clampf(esencia + cantidad, 0.0, 100.0)
	esencia_changed.emit(esencia)
	
	if cantidad < 0:
		print("🍄 Esencia -%s: %s [%s → %s]" % [abs(cantidad), razon, anterior, esencia])
		if esencia <= 15.0 and anterior > 15.0:
			print("⚠️ ERROR DE SISTEMA. Tus patas se mueven solas. El hongo teje su micelio en tu sistema nervioso.")
	else:
		print("✨ Esencia +%s: %s [%s → %s]" % [cantidad, razon, anterior, esencia])
	
	# Verificar Marioneta (Game Over)
	if esencia <= 0.0:
		_activar_marioneta()

func _activar_marioneta() -> void:
	print("💀 [ASIMILADO] Tus comandos ya no responden. Tu voluntad se apaga mientras los filamentos verdes brotan de tus ojos. Ya no eres un Zancudo. Eres un dron más en la marcha de la Colmena Silenciosa.")
	marioneta_triggered.emit()

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
	return (stats.get("agilidad", 5) + stats.get("percepcion", 5)) / 2.0

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
	quitina_actual = maxf(quitina_actual - cantidad, 0.0)
	quitina_changed.emit(quitina_actual, quitina_max)
	if quitina_actual <= 0.0:
		print("💀 Quitina agotada — la Plaga cae")

func curar(cantidad: float) -> void:
	quitina_actual = minf(quitina_actual + cantidad, quitina_max)
	quitina_changed.emit(quitina_actual, quitina_max)
	# Defecto Zancudo: Sobrecarga de Buffer
	if taxon_actual == Taxon.ZANCUDO and quitina_actual > quitina_max * 0.8:
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
		quitina_max += 5.0
		hemolinfa_max += 3.0
		quitina_actual = quitina_max
		hemolinfa_actual = hemolinfa_max
		quitina_changed.emit(quitina_actual, quitina_max)
		hemolinfa_changed.emit(hemolinfa_actual, hemolinfa_max)
		print("⬆️ ¡NIVEL %d! Quitina max: %.0f | Hemolinfa max: %.0f" % [nivel, quitina_max, hemolinfa_max])

# ===== REPUTACIÓN =====
func modificar_reputacion(faccion: String, cantidad: int) -> void:
	if reputacion.has(faccion):
		reputacion[faccion] = clampi(reputacion[faccion] + cantidad, -100, 100)

func es_hostil(faccion: String) -> bool:
	return reputacion.get(faccion, 0) < -50

func es_aliado(faccion: String) -> bool:
	return reputacion.get(faccion, 0) > 50
