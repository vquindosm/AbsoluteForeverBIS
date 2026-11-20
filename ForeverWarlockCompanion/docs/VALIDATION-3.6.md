# Validación local 3.6.0-preview

2026-11-19. Lua 5.1.5 y Python 3, sin cliente WoW ni renderizado del juego.

- Suites Lua run, v3, visual_layout, phase1_stats, foundation,
  authenticated_foundation, item_guide, loot_indicator y loot_visual en las variantes
  modern, legacy, no-model y player-model: 3.709 comprobaciones.
- Regresión nueva: 58 comprobaciones por variante, con APIs simuladas. Pérdidas de
  poder con hechizos/aguante en tablas dispersas, enlaces con sufijo, dirección y errores
  del delta nativo, API externa opcional, pesos manuales, fuente explícita, carga,
  baseline cero, versiones incompatibles, perfil, callbacks y líneas de tooltip propias.
- Suites Python data_foundation (24) y gear_guide (9): 33 pruebas, sin red.
- Sintaxis de los 52 archivos Lua: luac -p, uno por archivo.
- El empaquetador offline recompila los snapshots revisados y comprueba credenciales,
  integridad ZIP y presencia de cada archivo declarado por el TOC.

La geometría y el ciclo de vida de los frames se verifican con dobles. El tooltip
conserva los textos ajenos antes/después del bloque y no acumula filas al actualizar,
desactivar/reactivar o recibir cambios del proveedor externo. No es una captura visual.
El recorrido real, las unidades del cliente y la cobertura de GetItemStatDelta siguen
pendientes de la prueba descrita en [LOOT-TOOLTIP-3.6.md](LOOT-TOOLTIP-3.6.md).
