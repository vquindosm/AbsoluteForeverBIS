# Validación local — 3.3.1-preview, Fase 1 (19-11-2026)

| Variante de API simulada | Suite original | Progresión v3 | Layout | Regresión stats |
|---|---:|---:|---:|---:|
| modern | 134 | 60 | 201 | 64 |
| legacy | 130 | 60 | 201 | 64 |
| no-model | 132 | 60 | 201 | 64 |
| player-model | 133 | 60 | 201 | 64 |

1.829 comprobaciones locales pasan. 38 archivos Lua pasan `luac -p` con Lua 5.1.
Se compararon byte a byte con la base 3.3.0: UI/Dashboard.lua, Data.lua,
Data/Affliction.lua y Data/Recipes.lua no cambiaron.

Las regresiones usan el ID real de Felcloth Gloves (18407), pero las respuestas API
son fixtures explícitos. Comprueban identidad/enlace completos, independencia de instancias,
cero vs ausencia vs pending vs error, eventos, caché, alias y unidades, conflicto/restricción/
NaN/infinito, soporte legacy/Item, reglas de fallback y logs activables/persistidos.
No certifican que el cliente real exponga atributos concretos ni cubra sus modificaciones.

Prueba necesaria en juego: PHASE-1-CLIENT-TEST.md. La Fase 1 sigue pendiente de validación
real; no se activa puntuación global ni se declaran implementadas las fases 2–6.
Las comparativas de docs/validation pertenecen al rework visual 3.3; no son capturas de
esta corrección en el cliente ni prueba de estadísticas reales.
