extends Node
class_name AINpcCache
## AI NPC Cache — Sistema de diálogo con caché progresivo
##
## Flujo:
## 1. Jugador interactúa con NPC → busca respuesta en caché local (JSON)
## 2. Si hay match → usa respuesta cacheada (gratis, instantáneo)
## 3. Si no hay match → llama a Gemini → guarda respuesta en caché
## 4. Con el tiempo, el caché crece y la IA se necesita cada vez menos
##
## El archivo de caché se puede distribuir con el juego — eventualmente
## el juego funciona 100% offline sin necesitar la API.

const GEMINI_URL := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
const CACHE_DIR := "res://dialogues/cache/"
const SIMILARITY_THRESHOLD := 0.6  # Qué tan parecida debe ser una pregunta para usar caché

var api_key: String = ""
var _http: HTTPRequest = null
var _pending_callback: Callable = Callable()
var _pending_npc: String = ""
var _pending_input: String = ""
var _is_busy: bool = false

func _ready() -> void:
	api_key = _cargar_api_key()
	_http = HTTPRequest.new()
	_http.request_completed.connect(_on_response)
	add_child(_http)
	# Crear directorio de caché si no existe
	if not DirAccess.dir_exists_absolute(CACHE_DIR.replace("res://", "")):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))

## Obtener respuesta para un NPC — primero busca en caché, luego IA
func obtener_respuesta(npc_id: String, npc_context: Dictionary, player_input: String, callback: Callable) -> void:
	# 1. Buscar en caché
	var cached := _buscar_en_cache(npc_id, player_input)
	if cached != "":
		callback.call(cached)
		return

	# 2. Si no hay caché y no hay API key → respuesta genérica
	if api_key == "" or _is_busy:
		var fallback := _respuesta_generica(npc_context)
		callback.call(fallback)
		return

	# 3. Llamar a la IA
	_is_busy = true
	_pending_callback = callback
	_pending_npc = npc_id
	_pending_input = player_input
	_llamar_ia(npc_context, player_input)

## Busca en el archivo JSON de caché del NPC
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

## Guarda una nueva respuesta en el caché del NPC
func _guardar_en_cache(npc_id: String, player_input: String, response: String) -> void:
	var cache_path := CACHE_DIR + npc_id + ".json"
	var data: Dictionary = {"npc_id": npc_id, "dialogues": []}

	# Leer existente si hay
	if FileAccess.file_exists(cache_path):
		var file := FileAccess.open(cache_path, FileAccess.READ)
		var existing = JSON.parse_string(file.get_as_text())
		file.close()
		if existing != null and existing.has("dialogues"):
			data = existing

	# Agregar nueva entrada
	data["dialogues"].append({
		"input": player_input,
		"response": response,
		"timestamp": Time.get_datetime_string_from_system()
	})

	# Guardar
	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("[AINpcCache] Guardado en caché: %s → %d entradas" % [npc_id, data["dialogues"].size()])

## Similitud simple entre dos strings (Jaccard sobre palabras)
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

## Llama a Gemini API
func _llamar_ia(ctx: Dictionary, player_input: String) -> void:
	var prompt := _construir_prompt(ctx, player_input)
	var body := {
		"contents": [{"role": "user", "parts": [{"text": prompt}]}],
		"generationConfig": {"maxOutputTokens": 150, "temperature": 0.85}
	}
	var headers := ["Content-Type: application/json"]
	var url := GEMINI_URL + "?key=" + api_key
	_http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_response(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_is_busy = false
	var response_text := ""

	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("candidates"):
			response_text = json["candidates"][0]["content"]["parts"][0]["text"]
			response_text = response_text.replace("**", "").replace("*", "").strip_edges()
			# Guardar en caché para futuro uso
			_guardar_en_cache(_pending_npc, _pending_input, response_text)

	if response_text == "":
		response_text = "[El NPC murmura algo incomprensible...]"

	_pending_callback.call(response_text)

func _construir_prompt(ctx: Dictionary, player_input: String) -> String:
	var p := "Eres '%s', un %s de '%s' en el juego Plaga: La Descarada. " % [
		ctx.get("nombre", "NPC"), ctx.get("taxon", "insecto"), ctx.get("faccion", "neutral")]
	p += "Personalidad: %s. " % ctx.get("personalidad", "cínico")
	p += "Zona: %s. Año 20.000, era glacial, insectos dominan bajo tierra. " % ctx.get("zona", "Gran Charco")
	if ctx.has("lore"): p += ctx["lore"] + " "
	p += "\nReglas: Responde EN ESPAÑOL, máximo 2 frases. Tono cínico/descarado. "
	p += "Nunca rompas personaje. Si no sabes, inventa algo coherente.\n"
	p += "El jugador dice: \"%s\"" % player_input
	return p

func _respuesta_generica(ctx: Dictionary) -> String:
	var respuestas := [
		"%s te mira con desprecio. 'No tengo tiempo para larvas sin propósito.'",
		"%s se rasca una antena. 'Pregunta algo interesante o lárgate.'",
		"%s suspira. 'El frío congela hasta las preguntas estúpidas.'",
		"%s entrecierra los ojos. 'Hmm. Vuelve cuando tengas algo que ofrecer.'",
	]
	var nombre: String = ctx.get("nombre", "El NPC")
	return respuestas[randi() % respuestas.size()] % nombre

func _cargar_api_key() -> String:
	var env_path := ProjectSettings.globalize_path("res://.env")
	if FileAccess.file_exists(env_path):
		var file := FileAccess.open(env_path, FileAccess.READ)
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.begins_with("GEMINI_API_KEY="):
				return line.substr(15)
	return ""

## Stats del caché (para debug)
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
