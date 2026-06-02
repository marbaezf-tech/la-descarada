extends Node
class_name AIOllama
## AI Ollama — Diálogos dinámicos con IA local
##
## Conecta con Ollama (localhost:11434) para generar respuestas de NPCs.
## Usa el mismo sistema de caché que AINpcCache pero con modelo local.
## Ventajas: sin rate limits, sin costos, funciona offline, más rápido.
##
## Uso:
##   var ollama = AIOllama.new()
##   add_child(ollama)
##   ollama.chat_npc("vlad", contexto_vlad, "¿Quién manda aquí?", func(resp): print(resp))
##
## Requiere: Ollama corriendo en localhost:11434

const OLLAMA_URL := "http://localhost:11434/api/chat"
const OLLAMA_GENERATE_URL := "http://localhost:11434/api/generate"
const CACHE_DIR := "res://dialogues/cache/"
const DEFAULT_MODEL := "plaga-trained"
const FALLBACK_MODEL := "plaga-narrator"
const SIMILARITY_THRESHOLD := 0.6

var model: String = DEFAULT_MODEL
var _http: HTTPRequest = null
var _pending_callback: Callable = Callable()
var _pending_npc: String = ""
var _pending_input: String = ""
var _is_busy: bool = false
var _ollama_available: bool = false

signal respuesta_recibida(npc_id: String, texto: String)
signal ollama_status_changed(online: bool)

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 30.0  # 30 seg timeout (modelo puede tardar en cargar)
	_http.request_completed.connect(_on_response)
	add_child(_http)
	# Verificar si Ollama está corriendo
	_check_ollama.call_deferred()

## ─── API PÚBLICA ───────────────────────────────────────────────

## Obtener respuesta de un NPC — caché → Ollama → fallback
func chat_npc(npc_id: String, npc_context: Dictionary, player_input: String, callback: Callable) -> void:
	# 1. Buscar en caché primero
	var cached := _buscar_en_cache(npc_id, player_input)
	if cached != "":
		callback.call(cached)
		respuesta_recibida.emit(npc_id, cached)
		return

	# 2. Si Ollama no disponible o busy → fallback
	if not _ollama_available or _is_busy:
		var fallback := _respuesta_generica(npc_context)
		callback.call(fallback)
		return

	# 3. Llamar a Ollama
	_is_busy = true
	_pending_callback = callback
	_pending_npc = npc_id
	_pending_input = player_input
	_llamar_ollama(npc_context, player_input)

## Pregunta libre (no de NPC) — para debug o narrador
func preguntar(texto: String, callback: Callable) -> void:
	if not _ollama_available or _is_busy:
		callback.call("[Ollama no disponible]")
		return
	_is_busy = true
	_pending_callback = callback
	_pending_npc = ""
	_pending_input = texto
	_llamar_ollama_raw(texto)

## ¿Está Ollama disponible?
func is_online() -> bool:
	return _ollama_available

## Cambiar modelo activo
func set_model(nuevo_modelo: String) -> void:
	model = nuevo_modelo
	print("[AIOllama] Modelo cambiado a: %s" % model)

## ─── CONEXIÓN CON OLLAMA ───────────────────────────────────────

func _llamar_ollama(ctx: Dictionary, player_input: String) -> void:
	var system_prompt := _construir_system_prompt(ctx)
	var body := {
		"model": model,
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": player_input}
		],
		"stream": false,
		"options": {
			"temperature": 0.85,
			"num_predict": 150,
			"num_ctx": 2048
		}
	}
	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := _http.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		_is_busy = false
		_pending_callback.call(_respuesta_generica(ctx))

func _llamar_ollama_raw(texto: String) -> void:
	var body := {
		"model": model,
		"prompt": texto,
		"stream": false,
		"options": {
			"temperature": 0.85,
			"num_predict": 200
		}
	}
	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := _http.request(OLLAMA_GENERATE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		_is_busy = false
		_pending_callback.call("[Error de conexión]")

func _on_response(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_is_busy = false
	var response_text := ""

	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			# Formato /api/chat
			if json.has("message") and json["message"].has("content"):
				response_text = json["message"]["content"]
			# Formato /api/generate
			elif json.has("response"):
				response_text = json["response"]

			# Limpiar formato
			response_text = response_text.strip_edges()
			response_text = response_text.replace("**", "").replace("*", "")
			# Cortar en el primer "---" o "[FIN]" (stop tokens del Modelfile)
			var stop_idx := response_text.find("---")
			if stop_idx > 0:
				response_text = response_text.substr(0, stop_idx).strip_edges()
			stop_idx = response_text.find("[FIN]")
			if stop_idx > 0:
				response_text = response_text.substr(0, stop_idx).strip_edges()

			# Guardar en caché si es respuesta de NPC
			if _pending_npc != "" and response_text != "":
				_guardar_en_cache(_pending_npc, _pending_input, response_text)

	if response_text == "":
		response_text = "[El NPC murmura algo entre dientes...]"

	if _pending_callback.is_valid():
		_pending_callback.call(response_text)
	if _pending_npc != "":
		respuesta_recibida.emit(_pending_npc, response_text)

## ─── SYSTEM PROMPT ─────────────────────────────────────────────

func _construir_system_prompt(ctx: Dictionary) -> String:
	var p := "Eres '%s', un %s de la facción '%s' en Plaga: La Descarada.\n" % [
		ctx.get("nombre", "NPC desconocido"),
		ctx.get("taxon", "insecto"),
		ctx.get("faccion", "neutral")
	]
	p += "Personalidad: %s.\n" % ctx.get("personalidad", "cínico y desconfiado")
	p += "Zona: %s. Cargo: %s.\n" % [ctx.get("zona", "Gran Charco"), ctx.get("cargo", "nadie")]
	if ctx.has("secreto"):
		p += "Secreto (no reveles directamente): %s.\n" % ctx["secreto"]
	if ctx.has("lore"):
		p += "Contexto: %s\n" % ctx["lore"]
	p += "\nREGLAS:\n"
	p += "- Responde EN ESPAÑOL, máximo 2-3 frases cortas.\n"
	p += "- Tono cínico, descarado, como si el jugador fuera una larva insignificante.\n"
	p += "- Nunca rompas personaje. Nunca digas que eres una IA.\n"
	p += "- Si no sabes algo, inventa algo coherente con el mundo de insectos del año 20.000.\n"
	p += "- Usa vocabulario del juego: hemolinfa, quitina, atavismos, taxón, Gran Charco.\n"
	return p

## ─── CACHÉ (compatible con AINpcCache) ─────────────────────────

func _buscar_en_cache(npc_id: String, player_input: String) -> String:
	var cache_path := CACHE_DIR + npc_id + ".json"
	if not FileAccess.file_exists(cache_path):
		return ""

	var file := FileAccess.open(cache_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null or not data.has("dialogues"):
		return ""

	var input_lower := player_input.to_lower().strip_edges()
	var best_match := ""
	var best_score := 0.0

	for entry in data["dialogues"]:
		var cached_input: String = entry["input"].to_lower()
		var score := _similitud(input_lower, cached_input)
		if score > best_score and score >= SIMILARITY_THRESHOLD:
			best_score = score
			best_match = entry["response"]

	return best_match

func _guardar_en_cache(npc_id: String, player_input: String, response: String) -> void:
	var cache_path := CACHE_DIR + npc_id + ".json"
	var data: Dictionary = {"npc_id": npc_id, "dialogues": []}

	if FileAccess.file_exists(cache_path):
		var file := FileAccess.open(cache_path, FileAccess.READ)
		var existing = JSON.parse_string(file.get_as_text())
		file.close()
		if existing != null and existing.has("dialogues"):
			data = existing

	data["dialogues"].append({
		"input": player_input,
		"response": response,
		"timestamp": Time.get_datetime_string_from_system(),
		"model": model
	})

	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[AIOllama] Caché actualizado: %s → %d entradas" % [npc_id, data["dialogues"].size()])

## ─── UTILIDADES ────────────────────────────────────────────────

func _similitud(a: String, b: String) -> float:
	var words_a := a.split(" ")
	var words_b := b.split(" ")
	var set_a: Dictionary = {}
	var set_b: Dictionary = {}
	for w in words_a: set_a[w] = true
	for w in words_b: set_b[w] = true

	var interseccion := 0
	for w in set_a:
		if set_b.has(w):
			interseccion += 1

	var union := set_a.size() + set_b.size() - interseccion
	if union == 0: return 0.0
	return float(interseccion) / float(union)

func _respuesta_generica(ctx: Dictionary) -> String:
	var nombre: String = ctx.get("nombre", "El NPC")
	var respuestas := [
		"%s te observa con las antenas caídas. 'Otro novato que cree que el Charco le debe algo.'",
		"%s escupe hemolinfa al suelo. 'Habla rápido o piérdete. Tengo asuntos de quitina que atender.'",
		"%s inclina la cabeza. 'Interesante. Y por interesante quiero decir inútil.'",
		"%s se rasca un élitro. '¿Sabes? Antes del Silencio Verde las preguntas estúpidas se castigaban con inoculación.'",
		"%s bosteza. 'El frío congela hasta las neuronas de los recién eclosionados.'",
		"%s entrecierra los ocelos. 'Hmm. Vuelve cuando tu Esencia de Taxón valga algo.'",
	]
	return respuestas[randi() % respuestas.size()] % nombre

func _check_ollama() -> void:
	# Verificar con un simple HTTP GET a /api/tags
	var check_http := HTTPRequest.new()
	check_http.timeout = 5.0
	add_child(check_http)
	check_http.request_completed.connect(func(result, code, _h, _b):
		_ollama_available = (result == HTTPRequest.RESULT_SUCCESS and code == 200)
		if _ollama_available:
			print("[AIOllama] ✅ Ollama detectado en localhost:11434 — modelo: %s" % model)
		else:
			print("[AIOllama] ⚠️ Ollama no disponible — usando respuestas genéricas")
		ollama_status_changed.emit(_ollama_available)
		check_http.queue_free()
	)
	check_http.request("http://localhost:11434/api/tags")

## Obtener stats del caché de un NPC
func get_cache_stats(npc_id: String) -> Dictionary:
	var cache_path := CACHE_DIR + npc_id + ".json"
	if not FileAccess.file_exists(cache_path):
		return {"entries": 0, "exists": false}
	var file := FileAccess.open(cache_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data and data.has("dialogues"):
		return {"entries": data["dialogues"].size(), "exists": true}
	return {"entries": 0, "exists": true}
