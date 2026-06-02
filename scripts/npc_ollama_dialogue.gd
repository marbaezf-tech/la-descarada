extends Area2D
class_name NPCOllamaDialogue
## NPC con diálogos dinámicos via Ollama
##
## Uso: Agregar como hijo de un Node2D en el mapa.
## Configurar las variables @export desde el Inspector.
## Cuando el player entra al área y presiona E/Enter → abre diálogo.
##
## El diálogo usa Ollama local. Si Ollama no está corriendo,
## usa respuestas genéricas del caché o fallbacks.

@export var npc_id: String = "vlad"
@export var npc_nombre: String = "Vlad el Destilador"
@export var npc_taxon: String = "Zancudo"
@export var npc_faccion: String = "La Colmena"
@export var npc_cargo: String = "Destilador Jefe"
@export var npc_zona: String = "Laboratorio"
@export var npc_personalidad: String = "Paranoico, obsesivo, habla en metáforas de destilación"
@export var npc_secreto: String = "Destila hemolinfa prohibida para el Enjambre Negro a escondidas"
@export var npc_lore: String = ""
@export var interact_distance: float = 40.0

var _ollama: AIOllama = null
var _player_in_range: bool = false
var _dialogue_open: bool = false
var _dialogue_ui: Control = null
var _input_field: LineEdit = null
var _response_label: RichTextLabel = null
var _loading_label: Label = null

func _ready() -> void:
	# Crear instancia de AIOllama
	_ollama = AIOllama.new()
	add_child(_ollama)

	# Configurar collision shape para detección de proximidad
	if get_child_count() == 1:  # Solo tiene AIOllama, agregar CollisionShape
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = interact_distance
		shape.shape = circle
		add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Crear UI de diálogo (oculta por defecto)
	_crear_ui_dialogo()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _dialogue_open:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_abrir_dialogo()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		_player_in_range = true
		# Mostrar prompt "Presiona E para hablar"
		_mostrar_hint(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		_player_in_range = false
		_mostrar_hint(false)
		if _dialogue_open:
			_cerrar_dialogo()

## ─── DIÁLOGO ───────────────────────────────────────────────────

func _abrir_dialogo() -> void:
	_dialogue_open = true
	_dialogue_ui.visible = true
	_input_field.text = ""
	_input_field.grab_focus()
	_response_label.text = "[color=gray]%s te observa...[/color]" % npc_nombre
	_loading_label.visible = false
	# Pausar movimiento del player
	get_tree().paused = false  # No pausar el tree, solo bloquear input del player

func _cerrar_dialogo() -> void:
	_dialogue_open = false
	_dialogue_ui.visible = false
	_input_field.release_focus()

func _enviar_mensaje() -> void:
	var texto := _input_field.text.strip_edges()
	if texto == "":
		return
	if texto == "/salir" or texto == "/exit":
		_cerrar_dialogo()
		return

	_input_field.text = ""
	_response_label.text += "\n\n[color=cyan]Tú:[/color] %s" % texto
	_loading_label.visible = true
	_loading_label.text = "💭 %s piensa..." % npc_nombre

	var contexto := _get_contexto()
	_ollama.chat_npc(npc_id, contexto, texto, _on_respuesta)

func _on_respuesta(respuesta: String) -> void:
	_loading_label.visible = false
	_response_label.text += "\n\n[color=yellow]%s:[/color] %s" % [npc_nombre, respuesta]
	# Auto-scroll al final
	_response_label.scroll_to_line(_response_label.get_line_count() - 1)

func _get_contexto() -> Dictionary:
	return {
		"nombre": npc_nombre,
		"taxon": npc_taxon,
		"faccion": npc_faccion,
		"cargo": npc_cargo,
		"zona": npc_zona,
		"personalidad": npc_personalidad,
		"secreto": npc_secreto,
		"lore": npc_lore
	}

## ─── UI ────────────────────────────────────────────────────────

func _crear_ui_dialogo() -> void:
	# CanvasLayer para que esté siempre encima
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# Panel principal
	_dialogue_ui = PanelContainer.new()
	_dialogue_ui.visible = false
	_dialogue_ui.anchor_left = 0.1
	_dialogue_ui.anchor_right = 0.9
	_dialogue_ui.anchor_top = 0.5
	_dialogue_ui.anchor_bottom = 0.95
	_dialogue_ui.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_ui.custom_minimum_size = Vector2(600, 250)
	canvas.add_child(_dialogue_ui)

	var vbox := VBoxContainer.new()
	_dialogue_ui.add_child(vbox)

	# Header con nombre del NPC
	var header := Label.new()
	header.text = "💬 %s (%s — %s)" % [npc_nombre, npc_taxon, npc_faccion]
	header.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header)

	# Área de respuesta (scrollable)
	_response_label = RichTextLabel.new()
	_response_label.bbcode_enabled = true
	_response_label.custom_minimum_size = Vector2(0, 150)
	_response_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_response_label.scroll_following = true
	vbox.add_child(_response_label)

	# Loading indicator
	_loading_label = Label.new()
	_loading_label.text = "💭 Pensando..."
	_loading_label.visible = false
	_loading_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_loading_label)

	# Input field
	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	_input_field = LineEdit.new()
	_input_field.placeholder_text = "Escribe algo... (/salir para cerrar)"
	_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_field.text_submitted.connect(func(_t): _enviar_mensaje())
	hbox.add_child(_input_field)

	var btn_send := Button.new()
	btn_send.text = "Enviar"
	btn_send.pressed.connect(_enviar_mensaje)
	hbox.add_child(btn_send)

	var btn_close := Button.new()
	btn_close.text = "✕"
	btn_close.pressed.connect(_cerrar_dialogo)
	hbox.add_child(btn_close)

## ─── HINT ──────────────────────────────────────────────────────

var _hint_label: Label = null

func _mostrar_hint(visible: bool) -> void:
	if _hint_label == null:
		_hint_label = Label.new()
		_hint_label.text = "[E] Hablar con %s" % npc_nombre
		_hint_label.add_theme_font_size_override("font_size", 10)
		_hint_label.position = Vector2(-40, -30)
		add_child(_hint_label)
	_hint_label.visible = visible and not _dialogue_open
