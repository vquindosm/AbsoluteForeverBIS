# Validación 3.7.0-pilot

2026-11-20. Caso visual nuevo limitado a Fel Cape. No se ha ejecutado WoW Forever.

- 4.113 comprobaciones Lua: suites run, v3, visual_layout, phase1_stats, foundation,
  authenticated_foundation, item_guide, loot_indicator, loot_visual e item_inspector
  en las variantes modern, legacy, no-model y player-model.
- 101 comprobaciones nuevas por variante: datos publicados de Fel Cape/receta, costes,
  bolsas simuladas, deltas y EP matemáticos, peso ausente, aliases, solapamientos,
  clase, carga, comparación del mismo objeto, caché, rating, navegación, estados
  colapsados, reutilización de frames y geometría a 280/360/510 px.
- 33 pruebas Python (24 data_foundation + 9 gear_guide), sin red.
- Sintaxis individual de los 59 archivos Lua, con Lua 5.1.5 / luac -p.
- El empaquetador recompila snapshots revisados offline, rechaza claves/archivos privados,
  verifica la integridad del ZIP y comprueba todos los archivos Lua del TOC.

Se inspeccionaron las dos previews de docs/validation-3.7. Están generadas a partir de
los frames del addon mediante APIs simuladas; no son capturas del juego. El antes utiliza
el commit 7aa41af y el después los componentes nuevos. Los valores publicados del objeto
se distinguen del equipo y bolsas ficticios, tanto en las imágenes como en la documentación.

La comprobación de tooltips reales, unidades/cobertura del cliente, fuentes y modelos
nativos y el recorrido del usuario siguen pendientes de [ITEM-INSPECTOR-3.7.md](ITEM-INSPECTOR-3.7.md).
El inspector no se generaliza visualmente a otros objetos hasta validar el piloto.
