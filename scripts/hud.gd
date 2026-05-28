extends CanvasLayer
## HUD — Barras de estado del Zancudo
## Muestra Turgencia (vida), Hemolinfa (energía) y Esencia (Silencio Verde)

@onready var quitina_bar: ProgressBar = $Panel/VBox/TurgenciaBar
@onready var quitina_label: Label = $Panel/VBox/TurgenciaLabel
@onready var hemolinfa_bar: ProgressBar = $Panel/VBox/HemolinfaBar
@onready var hemolinfa_label: Label = $Panel/VBox/HemolinfaLabel
@onready var esencia_bar: ProgressBar = $Panel/VBox/EsenciaBar
@onready var esencia_label: Label = $Panel/VBox/EsenciaLabel
@onready var exp_bar: ProgressBar = $Panel/VBox/ExpBar
@onready var exp_label: Label = $Panel/VBox/ExpLabel

func _ready() -> void:
	GameManager.turgencia_changed.connect(_on_turgencia_changed)
	GameManager.hemolinfa_changed.connect(_on_hemolinfa_changed)
	GameManager.esencia_changed.connect(_on_esencia_changed)
	
	# Inicializar el Zancudo
	GameManager.inicializar_plaga(GameManager.Taxon.ZANCUDO, "Jugador")
	_update_all()

func _update_all() -> void:
	_on_turgencia_changed(GameManager.turgencia_actual, GameManager.turgencia_max)
	_on_hemolinfa_changed(GameManager.hemolinfa_actual, GameManager.hemolinfa_max)
	_on_esencia_changed(GameManager.esencia)
	_update_exp()
	# Colores de las barras
	quitina_bar.modulate = Color(0.9, 0.2, 0.2)  # Rojo vida
	hemolinfa_bar.modulate = Color(0.2, 0.5, 0.9)  # Azul energía
	exp_bar.modulate = Color(0.9, 0.7, 0.1)  # Dorado exp

func _on_turgencia_changed(current: float, max_val: float) -> void:
	quitina_bar.max_value = max_val
	quitina_bar.value = current
	quitina_label.text = "🛡️ Turgencia: %d/%d" % [current, max_val]

func _on_hemolinfa_changed(current: float, max_val: float) -> void:
	hemolinfa_bar.max_value = max_val
	hemolinfa_bar.value = current
	hemolinfa_label.text = "💧 Hemolinfa: %d/%d" % [current, max_val]

func _on_esencia_changed(value: float) -> void:
	esencia_bar.value = value
	esencia_label.text = "🍄 Esencia: %d%%" % [value]
	# Cambiar color según nivel
	if value > 75:
		esencia_bar.modulate = Color(0.2, 0.9, 0.3)
	elif value > 50:
		esencia_bar.modulate = Color(0.9, 0.9, 0.2)
	elif value > 25:
		esencia_bar.modulate = Color(0.9, 0.5, 0.1)
	else:
		esencia_bar.modulate = Color(0.9, 0.1, 0.1)

func _update_exp() -> void:
	var exp_max = GameManager.nivel * 20.0
	exp_bar.max_value = exp_max
	exp_bar.value = GameManager.experiencia
	exp_label.text = "⭐ Nv.%d — EXP: %d/%d" % [GameManager.nivel, GameManager.experiencia, exp_max]

func _process(_delta: float) -> void:
	# Actualizar EXP cada frame (es barato)
	_update_exp()
