extends Node
## AI_NPC — Sistema de diálogo dinámico con IA (Gemini API)
## Se usa para NPCs especiales que responden con IA en tiempo real
## No todos los NPCs usan esto — solo los marcados como "ai_npc"
##
## Requiere: API key de Gemini en .env o en project settings
## Gratis: 15 req/min, 1500 req/día con Gemini Flash

const GEMINI_URL := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

var api_key: String = ""
var _http_request: HTTPRequest = null
var _callback: Callable = Callable()
var _is_requesting: bool = false

func _ready() -> void:
	# Cargar API key desde variable de entorno o project settings
	api_key = _cargar_api_key()
	_http_request = HTTPRequest.new()
	_http_request.request_completed.connect(_on_request_completed)
	add_child(_http_request)

func _cargar_api_key() -> String:
	# Intentar leer de .env
	var env_path := "res://.env"
	if FileAccess.file_exists(env_path):
		var file := FileAccess.open(env_path, FileAccess.READ)
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.begins_with("GEMINI_API_KEY="):
				return line.substr(15)
	# Fallback: project settings
	if ProjectSettings.has_setting("ai_npc/gemini_api_key"):
		return ProjectSettings.get_setting("ai_npc/gemini_api_key")
	return ""

## Genera una respuesta de IA para un NPC
## npc_context: diccionario con {nombre, taxon, faccion, personalidad, zona, lore}
## player_message: lo que el jugador dijo/preguntó
## callback: función que recibe el texto de respuesta
func generar_respuesta(npc_context: Dictionary, player_message: String, callback: Callable) -> void:
	if api_key == "":
		callback.call("[IA no disponible — configura GEMINI_API_KEY en .env]")
		return
	if _is_requesting:
		callback.call("[Esperando respuesta anterior...]")
		return

	_callback = callback
	_is_requesting = true

	var system_prompt := _construir_prompt(npc_context)
	var body := {
		"contents": [
			{"role": "user", "parts": [{"text": system_prompt + "\n\nEl jugador dice: \"" + player_message + "\""}]}
		],
		"generationConfig": {
			"maxOutputTokens": 200,
			"temperature": 0.8
		}
	}

	var json_body := JSON.stringify(body)
	var headers := ["Content-Type: application/json"]
	var url := GEMINI_URL + "?key=" + api_key

	var error := _http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		_is_requesting = false
		callback.call("[Error de conexión]")

func _construir_prompt(ctx: Dictionary) -> String:
	var prompt := "Eres un NPC en el juego 'Plaga: La Descarada'. "
	prompt += "Tu nombre es '%s'. " % ctx.get("nombre", "NPC")
	prompt += "Eres un %s de la facción '%s'. " % [ctx.get("taxon", "insecto"), ctx.get("faccion", "neutral")]
	prompt += "Tu personalidad: %s. " % ctx.get("personalidad", "neutral")
	prompt += "Estás en la zona '%s' del Gran Charco. " % ctx.get("zona", "desconocida")
	prompt += "Contexto del mundo: Año 20.000, era glacial, insectos son la especie dominante bajo tierra. "
	prompt += "Los humanos ('Gigantes') sobreviven arriba en burbujas térmicas. "
	prompt += "El Silencio Verde (Cordyceps) amenaza a todos. "
	if ctx.has("lore"):
		prompt += "Lore adicional: %s. " % ctx["lore"]
	prompt += "\nReglas: "
	prompt += "- Responde EN ESPAÑOL, máximo 2-3 frases cortas. "
	prompt += "- Habla en primera persona como el personaje. "
	prompt += "- Usa el tono del juego: cinismo, arrogancia, desfachatez. "
	prompt += "- Nunca rompas el personaje. Nunca menciones que eres una IA. "
	prompt += "- Si el jugador pregunta algo que no sabes, inventa algo coherente con el lore."
	return prompt

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_requesting = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_callback.call("[El NPC no responde... (error %d)]" % response_code)
		return

	var json := JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json.has("candidates"):
		_callback.call("[El NPC murmura algo incomprensible...]")
		return

	var text: String = json["candidates"][0]["content"]["parts"][0]["text"]
	# Limpiar markdown si viene
	text = text.replace("**", "").replace("*", "").strip_edges()
	_callback.call(text)

## Verifica si la IA está disponible (tiene API key)
func esta_disponible() -> bool:
	return api_key != ""
