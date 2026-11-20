# Validación local 3.9.0-preview

2026-11-20. La captura del usuario documenta el fallo real de posición de 3.8.
La corrección elimina las modificaciones de fuentes/altura nativas de ese diseño.

- 4.322 comprobaciones Lua en las once suites de regresión y las cuatro variantes
  modern, legacy, no-model y player-model.
- Tarjeta: 52 comprobaciones modernas y 53 en legacy. Incluye datos/ranking, signos,
  clase/especialización, atlas, colores completos, temas, medidor, anchura, colisiones,
  ausencia de lectura/escritura de fuentes nativas, altura intacta, perfil externo,
  manejo de negativos, protección, hooks y ciclos de vida.
- 33 pruebas Python (24 data_foundation + 9 gear_guide), sin red.
- Sintaxis individual de 64 archivos Lua, Lua 5.1.5 / luac -p.
- ZIP offline con comprobación de credenciales, integridad y entradas del TOC.

Dos previews exportadas e inspeccionadas en docs/validation-3.9: mejora verde y
empeoramiento rojo, frente al commit 9a9b3e5. Usan geometría del código real, datos
publicados de Fel Cape y equipo/pesos simulados. No reproducen el fallo del motor C
de la captura original y no son capturas de WoW.

El recorrido de validación real se describe en UPGRADE-TOOLTIP-3.9.md.
