# Validación 3.8.0-preview

2026-11-20. El usuario aprobó la presentación del inspector Fel Cape de 3.7; esta
entrega cambia el hover y mantiene pendiente su comprobación en el cliente WoW.

- 4.270 comprobaciones Lua en las once suites run, v3, visual_layout, phase1_stats,
  foundation, authenticated_foundation, item_guide, loot_indicator, loot_visual,
  item_inspector y upgrade_banner, con variantes modern/legacy/no-model/player-model.
- Suite nueva: 39 comprobaciones por variante moderna y 40 en legacy. Incluye puesto
  publicado, escala de colores, perfil/build/nivel, sufijos, scores propios/externos,
  texto compacto, posición bajo el nombre, refresh sin crecimiento, restauración,
  filas añadidas, cambios de anclajes de terceros, cadenas relativas, rebuild nativo,
  protección y texto restringido.
- 33 pruebas Python: data_foundation (24) y gear_guide (9), sin red.
- Sintaxis individual de 64 archivos Lua mediante luac -p (Lua 5.1.5).
- Empaquetado offline con control de credenciales, integridad ZIP y archivos del TOC.

La preview de docs/validation-3.8/tooltip-comparison.png fue exportada desde la geometría
de ambas versiones e inspeccionada. El antes usa 09dd594 (3.7); Fel Cape tiene su puesto
publicado 2, y el equipo/pesos/porcentajes son controles simulados. La escala de colores
inferior son muestras de estilo. No es una captura del cliente ni una validación del reflow C.

Se documenta la prueba real en UPGRADE-TOOLTIP-3.8.md. La cobertura BiS es la referencia
publicada de Aflicción JcE 60; los puestos desconocidos no se deducen del orden del catálogo.
