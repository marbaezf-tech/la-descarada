extends Node
## LootSystem — Genera items aleatorios por tier
## Plaga: La Descarada
##
## DOCUMENTACIÓN:
## - Tiers de loot: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html#loot
## - Catálogo de equipo: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html#equipo
## - Fusión: https://marbaezf-tech.github.io/plaga-wiki/sistemas.html#fusion
## - Trazabilidad: https://marbaezf-tech.github.io/plaga-wiki/trazabilidad.html

const LOOT_TABLE: Dictionary = {
	"comun": {
		"prob": 60,
		"items": [
			{"nombre": "Hemolinfa Fresca", "emoji": "🩸", "tipo": "consumible", "valor": 1, "desc": "Sabe a cobre líquido. +20% Hemolinfa.", "efecto": "hemolinfa", "cantidad": 10},
			{"nombre": "Hoja de Menta", "emoji": "🌿", "tipo": "consumible", "valor": 1, "desc": "Horrible pero cura veneno. +10 Turgencia.", "efecto": "turgencia", "cantidad": 10},
			{"nombre": "Espina de Cactus", "emoji": "🌵", "tipo": "arma", "valor": 1, "desc": "Afilada como la envidia. +1 Daño.", "bonus_ataque": 1},
			{"nombre": "Capa de Hoja Seca", "emoji": "🍂", "tipo": "armadura", "valor": 1, "desc": "Camuflaje básico. +1 Defensa.", "bonus_defensa": 1},
		]
	},
	"poco_comun": {
		"prob": 25,
		"items": [
			{"nombre": "Gota de Miel", "emoji": "🍯", "tipo": "consumible", "valor": 2, "desc": "Robada de las Abejas. +30 Turgencia.", "efecto": "turgencia", "cantidad": 30},
			{"nombre": "Fémur de Grillo", "emoji": "🦴", "tipo": "arma", "valor": 2, "desc": "Aerodinámica para cráneos. +2 Daño.", "bonus_ataque": 2},
			{"nombre": "Placa de Élitro", "emoji": "🪲", "tipo": "armadura", "valor": 2, "desc": "Ala de escarabajo. +2 Defensa.", "bonus_defensa": 2},
			{"nombre": "Seda de Fibra de Carbono", "emoji": "🕸️", "tipo": "material", "valor": 2, "desc": "Material para el Anclaje de Fibra."},
		]
	},
	"raro": {
		"prob": 12,
		"items": [
			{"nombre": "Mandíbula de Escarabajo", "emoji": "🪓", "tipo": "arma", "valor": 3, "desc": "Corta quitina como mantequilla. +3 Daño.", "bonus_ataque": 3},
			{"nombre": "Coraza de Escorpión", "emoji": "🦂", "tipo": "armadura", "valor": 3, "desc": "Protección militar. +3 Defensa.", "bonus_defensa": 3},
			{"nombre": "Rocío Matutino Puro", "emoji": "💧", "tipo": "consumible", "valor": 3, "desc": "+50 Turgencia + cura estados.", "efecto": "turgencia", "cantidad": 50},
			{"nombre": "Nervio de Cobre", "emoji": "⚡", "tipo": "material", "valor": 3, "desc": "Vibra con estática. Material para el Anclaje."},
		]
	},
	"epico": {
		"prob": 2.5,
		"items": [
			{"nombre": "Burbuja de O₂ al 30%", "emoji": "🫧", "tipo": "consumible", "valor": 5, "desc": "Casi el Gran Éter. +20% todas stats 3 turnos.", "efecto": "buff_total", "cantidad": 20},
			{"nombre": "Pinza de Cangrejo", "emoji": "🦀", "tipo": "arma", "valor": 5, "desc": "Aplasta todo. +5 Daño.", "bonus_ataque": 5},
		]
	},
	"legendario": {
		"prob": 0.5,
		"items": [
			{"nombre": "Fragmento de Ámbar", "emoji": "🌟", "tipo": "reliquia", "valor": 10, "desc": "300M años. Por un instante, eres un dios. +30% todas stats.", "efecto": "buff_total", "cantidad": 30},
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
