extends Node
## LootSystem — Genera items aleatorios por tier
## Plaga: La Descarada

const LOOT_TABLE: Dictionary = {
	"comun": {
		"prob": 60,
		"items": [
			{"nombre": "Espina de Cactus", "emoji": "🌵", "tipo": "arma_cc", "valor": 1, "desc": "Afilada como la envidia de un Chinche."},
			{"nombre": "Hemolinfa Fresca", "emoji": "🩸", "tipo": "consumible", "valor": 1, "desc": "Sabe a cobre líquido. +20% Hemolinfa."},
			{"nombre": "Hoja de Menta", "emoji": "🌿", "tipo": "consumible", "valor": 1, "desc": "Horrible pero cura veneno."},
			{"nombre": "Cristal de Cafeína", "emoji": "☕", "tipo": "consumible", "valor": 1, "desc": "Hiperactivo 3 turnos. Luego crash."},
			{"nombre": "Guante de Quitina", "emoji": "🥊", "tipo": "arma_cc", "valor": 1, "desc": "Exoesqueleto moldeado como puño."},
		]
	},
	"poco_comun": {
		"prob": 25,
		"items": [
			{"nombre": "Fémur de Grillo", "emoji": "🦴", "tipo": "arma_cc", "valor": 2, "desc": "Aerodinámica para partir cráneos."},
			{"nombre": "Gota de Miel", "emoji": "🍯", "tipo": "consumible", "valor": 2, "desc": "Robada de las Abejas. +30% Quitina."},
			{"nombre": "Dardo de Veneno", "emoji": "🎯", "tipo": "arma_dist", "valor": 2, "desc": "Espina hueca con neurotoxina."},
			{"nombre": "Membrana de Huevo", "emoji": "🐚", "tipo": "armadura", "valor": 2, "desc": "Flexible. Protección 2."},
			{"nombre": "Adrenalina de Avispa", "emoji": "⚡", "tipo": "consumible", "valor": 2, "desc": "+3 Fuerza. Riesgo de Enjambre."},
		]
	},
	"raro": {
		"prob": 12,
		"items": [
			{"nombre": "Mandíbula de Escarabajo", "emoji": "🪓", "tipo": "arma_cc", "valor": 3, "desc": "Corta quitina como mantequilla."},
			{"nombre": "Rocío Matutino Puro", "emoji": "💧", "tipo": "consumible", "valor": 3, "desc": "+50% Quitina + cura estados."},
			{"nombre": "Coraza de Escorpión", "emoji": "🦂", "tipo": "armadura", "valor": 4, "desc": "Protección militar. Pesa."},
			{"nombre": "Nervio de Cobre", "emoji": "⚡", "tipo": "material", "valor": 3, "desc": "Vibra con estática. Para el Anclaje."},
		]
	},
	"epico": {
		"prob": 2.5,
		"items": [
			{"nombre": "Cápsula Bombardera", "emoji": "💣", "tipo": "arma_dist", "valor": 7, "desc": "Tecnología del Semidiós Brachinus. Explota."},
			{"nombre": "Burbuja de O₂ al 30%", "emoji": "🫧", "tipo": "consumible", "valor": 5, "desc": "Casi el Gran Éter. +20% todas stats."},
		]
	},
	"legendario": {
		"prob": 0.5,
		"items": [
			{"nombre": "Fragmento de Ámbar", "emoji": "🌟", "tipo": "reliquia", "valor": 10, "desc": "300M años. Por un instante, eres un dios."},
		]
	}
}

func generar_loot() -> Dictionary:
	var roll := randf() * 100.0
	var tier: String = "comun"
	
	if roll < 0.5:
		tier = "legendario"
	elif roll < 3.0:
		tier = "epico"
	elif roll < 15.0:
		tier = "raro"
	elif roll < 40.0:
		tier = "poco_comun"
	else:
		tier = "comun"
	
	var items_pool: Array = LOOT_TABLE[tier]["items"]
	var item: Dictionary = items_pool[randi() % items_pool.size()].duplicate()
	item["tier"] = tier
	return item
