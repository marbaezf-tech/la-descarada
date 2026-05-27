# 🎨 Guía de Sprites — Plaga: La Descarada

## Formato Requerido
- **Tamaño por frame:** 32x32 píxeles (Propuesta 2: Micro-Gótico)
- **Formato:** PNG con fondo transparente
- **Contorno:** Outline oscuro de 1px

## Sprites Necesarios

### Jugador (Zancudo)
- `zancudo_idle.png` — 4 frames (espasmos nerviosos)
- `zancudo_walk_down.png` — 4 frames
- `zancudo_walk_up.png` — 4 frames
- `zancudo_walk_left.png` — 4 frames
- `zancudo_walk_right.png` — 4 frames
- `zancudo_attack.png` — 3 frames (dash con estilete)

### Enemigos
- `garrapata.png` — 2 frames idle
- `cucaracha.png` — 2 frames idle
- `polilla.png` — 2 frames idle

### Spots (Puntos de interés)
- `spot_estanteria.png` — 32x32 estático
- `spot_vaso.png` — 32x32 estático
- `spot_cable.png` — 32x32 estático

### UI
- `portrait_zancudo.png` — 64x64 (estilo Polly Pocket para diálogos)
- `indicator.png` — 16x16 (icono "!" de interacción)

## Paleta de Colores (Micro-Gótico)
- Exoesqueleto: #1a1a2e (negro profundo)
- Reflejos: #16213e (azul acero frío)
- Hemolinfa: #c0392b (rojo carmesí)
- Ojos: #ffffff (blanco vacío)
- Estilete: #bdc3c7 (plata)
- Fondo: #0d1117 (oscuridad)

## Cómo Integrar
1. Pon los PNGs en `assets/sprites/`
2. Godot los importa automáticamente
3. El código ya está preparado para cargarlos

## Herramientas Sugeridas
- Aseprite (pixel art profesional)
- Piskel (gratis, web)
- IA: usa los prompts de Gemini con Stable Diffusion o DALL-E
