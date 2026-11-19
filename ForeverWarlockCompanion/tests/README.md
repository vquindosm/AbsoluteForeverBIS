# Pruebas locales

Necesitan Lua 5.1 y se ejecutan desde la carpeta del addon:

```sh
lua tests/run.lua modern
lua tests/run.lua legacy
lua tests/run.lua no-model
lua tests/run.lua player-model
```

`wow_mock.lua` define contratos explícitos de frames/API, sin aceptar métodos arbitrarios.
Los datos de inventario/talentos de prueba son fixtures y no se cargan por el `.toc`.
La suite comprueba carga en orden, migración, selección de Head, perfiles, filtros, cantidades,
fallos de API, combate, debounce, estados de modelo, dimensiones mínimas y reutilización de filas.
No renderiza WoW, no comprueba datos reales de talentos, modelos o recetas y no demuestra que
una API del build real tenga exactamente el comportamiento del doble. La guía manual cubre
esa validación. No es una simulación de juego ni una captura del addon en funcionamiento.

Para comprobar la sintaxis, ejecuta `luac -p` sobre cada archivo `.lua` por separado.
El importador Python sólo se ejecuta fuera del juego y necesita un archivo page-data.json
obtenido de la URL que figura en `docs/import-manifest.json`.

## 3.0

Ejecutar también `lua tests/v3.lua modern` y sus variantes legacy/no-model/player-model.
El caso nuevo usa el objeto real Spellweaver's Turban 22267. Los costes compartidos se
comprueban con fixtures deliberadamente sintéticos, que no se añaden al catálogo entregado.
Comprueba esquema 3/backup, idempotencia, pasos, final independiente, custom steps, ciclos,
materiales agregados, Back, secciones, tracker, foco, guardado en archivo y tamaños compactos.
La prueba anterior se adaptó al selector contextual y a la semántica correcta de reputación:
una barra al siguiente rango NO es una barra hasta Exaltado.

## 3.3: distribución y flujos

Ejecutar `lua tests/visual_layout.lua modern` y las variantes legacy/no-model/player-model.
Comprueba las cuatro pantallas, 880x640 / 1180x780 / 1700x1040, límites de ranuras/tarjetas,
rail sin solapamiento, navegación agrupada, filtros, Back, selección y pasos persistentes.
El doble de geometría distingue ancho y alto incluso cuando sólo uno está fijado.

`lua tests/export_layout.lua modern /tmp/fwc-after` exporta la geometría de cuatro vistas.
`python3 tools/render_layout.py /tmp/fwc-before /tmp/fwc-after docs/validation` genera las
comparativas usando también una exportación de 3.2. Requiere Pillow y fuentes DejaVu.
Es una herramienta externa de desarrollo: usa fixtures, iconos simbólicos, una aproximación
de fuentes y un marcador de modelo nativo. No se carga en el juego y no certifica el motor WoW.

## Fase 1 de estadísticas (3.3.1)

Ejecutar también `lua tests/phase1_stats.lua modern` y las variantes legacy/no-model/player-model.
Reproduce el caso Felcloth Gloves usando respuestas API deliberadamente controladas: cero,
atributo ausente, caché pendiente, errores, enlaces con sufijo/encantamiento, tablas parciales,
aliases, conflictos, fuentes verificadas por build, eventos asíncronos, fallback Item y logs.
No certifica los valores reales del objeto, la cobertura de GetItemStats ni el cliente Forever.
Ver docs/PHASE-1-CLIENT-TEST.md para el gate antes de activar puntuación global.

## Data foundation / un vendedor (3.3.2)

`python3 -m unittest discover -s tests -p data_foundation.py` valida el importador y su fuente real
sin red. Requiere tools/data/requirements.txt. Comprueba esquema, null vs 0, precio en moneda,
procedencia, identidades, cobertura, seguridad de credenciales, SQL relacional y Lua reproducible.
`lua tests/foundation.lua modern` y variantes legacy/no-model/player-model comprueban el objetivo
real publicado, progreso con jugador simulado, ALL/ANY, bloqueo UNKNOWN, observación de mercader,
precio/stock temporal, persistencia, plan legado y referencias de ambos guantes sin EP ficticio.
Los datos del jugador y grafos adversos son fixtures, no afirmaciones sobre registros nuevos.
Prueba manual pendiente: docs/VENDOR_SLICE_TEST.md. El build no hace HTTP en Lua.


## ForeverDB autenticado (3.3.3)

Ejecutar `lua tests/authenticated_foundation.lua modern` y variantes legacy/no-model/player-model.
Parte del catálogo normalizado real de la API, con jugador/mercader simulados: moneda 3469,
bolsas con item de nombre igual, progreso/Unknown/0, actualización del objetivo existente,
GUID localizado, costes/stock temporales, referencias estadísticas y crédito visible por panel.
`foundation.lua` conserva el fixture de 3.3.2 público y no modifica el catálogo de producción.
La suite Python anterior también valida el snapshot API reproducible y el adaptador con
controles sintéticos de formato, atribución/marcas, cuenta privada, unidades y cambios de esquema.
No incluye respuestas privadas completas ni claves, y no prueba el cliente del juego.
