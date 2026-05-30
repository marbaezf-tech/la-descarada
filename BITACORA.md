# 🦟 BITÁCORA — Plaga: La Descarada
**Proyecto:** `c:\Users\HardwareX\OneDrive\Documentos\descarada`
**Motor:** Godot 4.6 — Mobile renderer — 640×360 viewport (escala 2x → 1280×720)
**Plataforma objetivo:** Android (APK) + PC
**Última actualización:** Mayo 2026 (semana 4)

---

## 📁 ESTRUCTURA DEL PROYECTO

```
descarada/
├── main.tscn          ← Escena principal (El Laboratorio)
├── menu.tscn          ← Menú principal
├── creacion.tscn      ← Creación de personaje
├── assets/
│   └── sprites/       ← Sprites del zancudo (zancudo_front/back/left/right.png)
├── imagenes/          ← Imágenes de enemigos, fondos, taxones
│   └── Enemigos/      ← Imágenes 2d_ de enemigos
├── scripts/           ← Todos los scripts GDScript
├── video/             ← Trailers OGV (torneo 1, torneo 2, demo escorpión)
└── export/            ← APKs exportados (v0.2.0, v0.3.0, latest)
```

---

## 🎮 ESTADO ACTUAL DEL JUEGO

### Lo que funciona (implementado y jugable)
- ✅ Menú principal con reproducción de trailers OGV en secuencia
- ✅ Creación de personaje: selección de Taxón + nombre + arquetipo
- ✅ Escena principal (El Laboratorio) construida por código en `main.gd`
- ✅ Jugador con sprites direccionales (front/back-L/back-R/left/right)
- ✅ Movimiento top-down 4 direcciones + joystick virtual para Android
- ✅ 3 Spots interactivos: Monitor Holográfico, Vaso de Agua, Cable Expuesto
- ✅ Sistema de combate por turnos completo (Atacar / Atavismo / Danza / Huir)
- ✅ HUD con barras de Turgencia, Hemolinfa, Esencia, EXP
- ✅ Inventario con uso, equipamiento, fusión de items y crafteo
- ✅ Bestiario (se llena al vencer enemigos)
- ✅ Sistema de guardado/carga (F5/F9, JSON en user://)
- ✅ Game Over por Turgencia = 0 ("Quitina Quebrada")
- ✅ Game Over por Esencia = 0 ("Asimilado" — Silencio Verde)
- ✅ Pantalla de fin de demo al craftear el Anclaje de Fibra
- ✅ Desbloqueo del Escorpión al completar la demo
- ✅ Exportado como APK (v0.3.0)
- ✅ **Mapa isométrico** generado por código — reemplaza imagen de fondo
- ✅ **Sistema de zonas en cruz** — 5 zonas conectadas desde el Laboratorio central
- ✅ **zona_base.gd** — clase base con sistema de 4 puertas, spawn contextual, painter's algorithm
- ✅ **zona_laboratorio.gd** — zona central (12×12), 4 puertas (N/S/E/O)
- ✅ **zona_pasillo.gd** — este del laboratorio, tonos tierra (refactorizado a zona_base)
- ✅ **zona_azotea.gd** — norte, exterior expuesto, tonos azul-gris
- ✅ **zona_sotano.gd** — sur, subterráneo infectado, tonos verde bioluminiscente
- ✅ **zona_maquinas.gd** — oeste, industrial, tonos naranja-rojo
- ✅ **Transición genérica** `_on_entrar_zona()` en main.gd — maneja todas las zonas con fade
- ✅ **Spawn contextual** — `get_spawn_desde()` en zona_base ubica al jugador en la puerta correcta al volver
- ✅ HUD muestra nombre de zona activa

### Pendiente / En desarrollo
- ⏳ Enemigos propios por zona (tabla de spawn diferente por zona)
- ⏳ NPCs con diálogo
- ⏳ Sistema de facciones activo (reputación existe pero no tiene consecuencias en juego)
- ⏳ Imágenes 2D de enemigos (actualmente placeholders de color)
- ⏳ Ajustar posiciones de Spots para que coincidan con el mapa isométrico

---

## 🧬 TAXONES JUGABLES

14 taxones en total. 10 disponibles en v1.0, 4 reservados para DLC.

| Taxón | Emoji | Facción | Recurso | Defecto | Pasivo especial |
|-------|-------|---------|---------|---------|-----------------|
| Zancudo | 🦟 | El Enjambre Negro | Sangre Fresca | Sobrecarga de Buffer | — |
| Cucaracha | 🪳 | Los Parásitos Libres | Bio-Residuos | Aura de Asco | — |
| Avispa | 🐝 | Los Sueltos | Carne Dulce y Azúcar | Frenesí de Asado | — |
| Garrapata | 🕷️ | Los Sueltos | Plasma Estancado | Anclaje Pesado | Regenera 3% HP/turno |
| Chinche | 🛏️ | La Colmena | Sangre Premium | Paladar Fino | — |
| Mariposa | 🦋 | La Colmena | Néctar Fermentado | Alas de Cristal | — |
| Araña | 🕸️ | La Colmena | Hemolinfa | Fobia Social | — |
| Escorpión | 🦂 | El Enjambre Negro | Turgencia | Fotofobia Humillante | — |
| Vinchuca | 🗡️ | Los Parásitos Libres | Sangre Inoculada | Digestión Traicionera | — |
| Mosca | 🪰 | Los Parásitos Libres | Necromasa | Olor a Muerte | — |
| Sanguijuela | 💉 | Los Parásitos Libres | Toxinas y Filtros | Adicción Espiritual | — |
| Polilla | 🌙 | Neutral | Fotones | Atracción Fatal | — |
| Pulga | ⚡ | Los Sueltos | Flujo Cinético | Hiperactividad Crónica | Evasión maestra |
| Típula | 🦟 | Los Parásitos Libres | Calor Robado | Cristal Ambulante | — |

### Stats base (6 atributos primordiales)
- **Tórax** — fuerza física, daño en combate
- **Ganglios** — velocidad, iniciativa
- **Quitina Base** → determina Turgencia máx (80 + quitina×4)
- **Sensilios** → determina Hemolinfa máx (30 + sensilios×4), precisión
- **Cripsis** — sigilo, evasión
- **Feromonas** — carisma, social

### Arquetipos (se eligen en creación)
| Arquetipo | Bonus | Penalización |
|-----------|-------|--------------|
| El Estratega 🧠 | +2 Sensilios | -1 Tórax |
| El Ejecutor 💪 | +2 Quitina | -1 Feromonas |
| El Infiltrado 🗡️ | +2 Cripsis | -1 Quitina |
| El Diplomático 💐 | +2 Feromonas | -1 Cripsis |

---

## ⚔️ SISTEMA DE COMBATE

Combate por turnos estilo Pokémon. Prota de espalda (abajo-izq), enemigo de frente (arriba-der).

### Acciones disponibles
1. **Atacar** — daño físico. Fórmula: `(Tórax + arma_equipada) × 2 - defensa_enemigo × 0.5`
2. **Atavismo** — habilidades especiales del taxón (costo en Hemolinfa)
3. **Danza de Antenas** — sistema social piedra-papel-tijera con 4 posturas
4. **Retirada** — huir. Chance = `velocidad_jugador / velocidad_enemigo × 0.5`

### Danza de Antenas (sistema social)
4 posturas químicas en ciclo: Acecho > Exposición > Vibración > Mimetismo > Acecho
- Ganar = +1 Antena + efecto especial según postura
- Perder = penalización según postura enemiga
- Antenas (0-10): si llegan a 0 → -5% Esencia por combate

### Enemigos actuales (El Laboratorio)
| Enemigo | HP | Fuerza | Agilidad | Defensa | Aparición |
|---------|-----|--------|----------|---------|-----------|
| Garrapata Salvaje | 30 | 4 | 3 | 2 | 33% |
| Cucaracha Carroñera | 20 | 3 | 5 | 1 | 33% |
| Polilla Sedante | 15 | 2 | 4 | 0 | 33% |

### Fórmulas clave
- **Evasión enemiga:** `GAN×3.5% + CRI×2.5%` (cap 55%)
- **Precisión jugador:** reduce evasión en `SEN×2%`
- **Velocidad:** `(Ganglios + Sensilios) / 2`

---

## 🍄 SISTEMA DE ESENCIA (EL SILENCIO VERDE)

La Esencia empieza en 100%. Si llega a 0% → Game Over "Asimilado".

### Fases de infección (se activan al bajar)
| Fase | Umbral | Efecto |
|------|--------|--------|
| Susurros | 75% | -1 Sensilios |
| Parasitismo | 50% | +1 Tórax, -2 Ganglios |
| Dominación | 25% | -1 a todos los stats |
| Marioneta | 0% | Game Over |

### Acciones que bajan Esencia
- Matar sin justificación: -10%
- Diablerie (consumir fósil): -15%
- Traicionar aliado: -7%
- Fallo del enjambre: -8%
- Huir del combate: -2%
- Usar habilidad excesiva: -3%

### Acciones que suben Esencia
- Quest pacífica: +5%
- Meditar en El Panal: +5%
- Resistir impulso: +4%
- Descansar en Nido: +3%
- Ayudar aliado: +2%
- Victoria social (Danza): +2%

---

## 🎒 SISTEMA DE LOOT E INVENTARIO

Inventario máximo: 20 items.

### Tiers de loot
| Tier | Probabilidad |
|------|-------------|
| Común | 60% |
| Poco Común | 25% |
| Raro | 12% |
| Épico | 2.5% |
| Legendario | 0.5% |

### Crafteo (objetivo de la demo)
**Anclaje de Fibra** = 3× Seda de Fibra de Carbono + 1× Nervio de Cobre + 15 Hemolinfa
→ Completa la demo → desbloquea Escorpión

### Fusión de items
Items repetidos se pueden fusionar en items de tier superior.
Ejemplos: 10× Espina de Cactus → Lanza de Espinas (+6 daño) → 3× Lanza → Tridente del Charco (+12 daño)

---

## 💾 GUARDADO

- **F5** — Guardar
- **F9** — Cargar
- Archivo: `user://save_data.json`
- Guarda: nivel, EXP, stats, inventario, reputación, zona, taxón, nombre

---

## 🗺️ MAPA ISOMÉTRICO (NUEVO — Mayo 2026)

Se agregó `scripts/iso_map.gd` que genera el mapa del Laboratorio por código.
- Reemplaza la imagen de fondo `fondo.jpg`
- Tiles isométricos dibujados con `Image.create()` en runtime
- Mapa 10×9 con tipos: piso / pared / acento verde / peligro rojo
- Se instancia en `main.gd` antes del player
- El player hace spawn en tile (4,4) = centro del mapa

**Pendiente:** ajustar posiciones de los Spots para que coincidan con el mapa isométrico.

---

## 📱 EXPORTACIÓN ANDROID

- APK firmado con `debug.keystore`
- Script de exportación: `exportar_apk.bat`
- Versiones exportadas: v0.2.0, v0.3.0, latest en `export/`
- Touch controls: joystick virtual + botones (solo aparece en dispositivos touch)

---

## 🔧 SCRIPTS — RESUMEN

| Script | Tipo | Función |
|--------|------|---------|
| `game_manager.gd` | Autoload | Estado global: stats, esencia, inventario, combate |
| `loot_system.gd` | Autoload | Generador de loot aleatorio por tier |
| `save_system.gd` | Autoload | Guardar/cargar partida (F5/F9) |
| `main.gd` | Node2D | Construye toda la escena del Laboratorio por código |
| `menu_principal.gd` | Control | Menú + reproducción de trailers OGV |
| `creacion_personaje.gd` | Control | Selección de Taxón + Arquetipo |
| `player.gd` | CharacterBody2D | Movimiento + sprites direccionales + touch |
| `combat_manager.gd` | CanvasLayer | Combate por turnos completo |
| `spot.gd` | Node2D | Punto de interacción en el mapa |
| `spot_menu.gd` | CanvasLayer | Menú de interacción (explorar/cazar/saquear) |
| `hud.gd` | CanvasLayer | Barras de Turgencia, Hemolinfa, Esencia, EXP |
| `inventario_ui.gd` | CanvasLayer | Inventario + fusión + crafteo |
| `bestiario_ui.gd` | CanvasLayer | Pokédex de enemigos vencidos |
| `touch_controls.gd` | CanvasLayer | Joystick virtual para Android |
| `iso_map.gd` | Node2D | Mapa isométrico generado por código |

---

## ⌨️ CONTROLES

| Acción | Teclado | Android |
|--------|---------|---------|
| Mover | WASD / Flechas | Joystick virtual |
| Interactuar | Espacio / Enter | Botón ⚡ |
| Inventario | I | Botón 🎒 |
| Bestiario | L | — |
| Guardar | F5 | — |
| Cargar | F9 | — |

---

## 📝 NOTAS DE DESARROLLO

- Todo se construye por código (`main.gd`) para evitar problemas de UID en Godot
- Los sprites del zancudo están en `assets/sprites/` (zancudo_front/back/left/right.png)
- Las imágenes de enemigos van en `imagenes/Enemigos/2d_[nombre].png`
- El proyecto `c:\Users\HardwareX\OneDrive\Documentos\la-descarada` es una rama experimental — el proyecto real es este (`descarada`)
