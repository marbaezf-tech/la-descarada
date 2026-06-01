extends Node2D
## DialogueTrigger — NPC que inicia diálogo con Dialogue Manager
## Se usa como spot interactivo que abre diálogo en lugar del menú de spot

@export var dialogue_file: String = ""  # Path al .dialogue (ej: "res://dialogues/vlad_laboratorio.dialogue")
@export var dialogue_start: String = "start"  # Nodo inicial del diálogo
@export var npc_name: String = "NPC"

var _dialogue_resource: Resource = null

func _ready() -> void:
	if dialogue_file != "":
		_dialogue_resource = load(dialogue_file)

## Llamado cuando el player interactúa con este NPC
func interact() -> void:
	if _dialogue_resource == null:
		push_error("DialogueTrigger: No hay archivo de diálogo asignado para " + npc_name)
		return

	# Pausar movimiento del player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set"):
		player.can_move = false

	# Determinar qué nodo de diálogo usar
	var start_node: String = dialogue_start

	# Si tiene quest completable, verificar si mostrar diálogo de entrega
	if GameManager.get("quest_vlad_hongo") == true and GameManager.has_method("tiene_item"):
		if GameManager.tiene_item("cordyceps_luminoso"):
			start_node = "vlad_quest_complete"

	# Mostrar el diálogo usando Dialogue Manager
	# NOTA: Requiere que el addon esté instalado y activado
	if Engine.has_singleton("DialogueManager") or ClassDB.class_exists("DialogueManager"):
		DialogueManager.show_dialogue_balloon(_dialogue_resource, start_node)
		# Conectar señal de fin de diálogo para reanudar movimiento
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	else:
		# Fallback si Dialogue Manager no está instalado — mostrar texto simple
		_mostrar_dialogo_simple()

func _on_dialogue_ended(_resource) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)

## Fallback: diálogo simple sin el addon (para testing)
func _mostrar_dialogo_simple() -> void:
	var label := Label.new()
	label.text = npc_name + ": (Instala Dialogue Manager para ver el diálogo completo)"
	label.position = Vector2(100, 300)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	get_tree().current_scene.add_child(label)
	# Auto-cerrar después de 3 segundos
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		label.queue_free()
		var player = get_tree().get_first_node_in_group("player")
		if player: player.can_move = true
	)

## Para el sistema de spots — muestra indicador
func show_indicator() -> void:
	var ind = get_node_or_null("Indicator")
	if ind: ind.visible = true

func hide_indicator() -> void:
	var ind = get_node_or_null("Indicator")
	if ind: ind.visible = false
