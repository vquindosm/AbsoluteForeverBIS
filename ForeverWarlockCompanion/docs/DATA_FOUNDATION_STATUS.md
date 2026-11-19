# Estado de entrega — 3.3.2-preview

Se ha seguido el gate final solicitado: auditar stats/adquisición y después implementar
importador + un vendedor. No se ha avanzado al catálogo masivo ni a cuatro ejemplos ficticios.

| Parte | Implementado / evidencia | Pendiente |
|---|---|---|
| Fuentes y licencias | DATA_SOURCES.md y sondas HTTP propias | API autenticada: variable no disponible en este proceso |
| Modelo | JSON Schema, procedencia por campo, unknown/legacy explícitos | Más adaptadores revisados para respuestas reales |
| Importador | Cuatro registros públicos factuales, compilador a Lua y SQLite relacional, cobertura y hash | Mapping API autenticado certificado; importación masiva deshabilitada |
| Stats | Prioridad cliente, referencias offline de mismo build/variante, unidades desconocidas sin conversión; ambas clases de guantes probadas | Verificación local de todos los atributos/modificaciones en WoW |
| Rating | Se conserva el EP manual anterior, se bloquean referencias/incompletos | StatWeightProvider y perfiles/simulación nuevos; sin pesos oficiales inventados |
| Requisitos | ALL/ANY/QUANTITY/MANUAL/UNKNOWN, fuentes alternativas, recursos compartidos y procedencia | Ampliar sólo tras validar la vertical de vendedor |
| Vendedor | Arcanoweave Cloak 272411 por 75 unidades de item 226404; progreso, bloqueo, UI existente, lectura de mercader y persistencia | Reputación/quests/oro base/stock no publicados; prueba en el cliente aún pendiente |
| Recetas/misiones | Esquema definido; datos anteriores preservados | Nuevas recetas de 12 profesiones y quests: 0 importadas |
| Cuatro verticales | Una vertical de vendedor implementada con requisitos publicados parciales | Confirmación en juego y luego crafting/quest/dungeon |

No se presenta la lectura de un mercader simulado como observación real. Sus precios/stock
históricos no se reutilizan como actuales fuera de su ventana abierta. El booleano de compra
no demuestra todos los requisitos universales. UNKNOWN no equivale a ausencia de requisito.
La adquisición observada completa el objetivo, manteniendo separada la falta de cobertura de datos.
Las sumas de recursos compartidos describen demanda total y una única disponibilidad real;
no reservan ni gastan moneda automáticamente ni prometen completar varios objetivos a la vez.

## Validación local

| Variante simulada | Original | v3 | Layout | Stats fase 1 | Foundation |
|---|---:|---:|---:|---:|---:|
| modern | 134 | 60 | 201 | 64 | 66 |
| legacy | 130 | 60 | 201 | 64 | 66 |
| no-model | 132 | 60 | 201 | 64 | 66 |
| player-model | 133 | 60 | 201 | 64 | 66 |

2.093 comprobaciones Lua y 17 tests Python del compilador/importador. Los 42 archivos Lua
pasan sintaxis Lua 5.1. Los datos originales (157 objetos, 28 recetas), Dashboard y ventana
principal se compararon byte a byte con 3.3.1: se mantienen sin cambios.

Los tests parten del registro publicado conservado en Catalog, pero las respuestas del jugador,
mercader y grafos adversos son controles explícitos. No prueban el cliente real. Recorrido
necesario: VENDOR_SLICE_TEST.md. La base no se declara completa ni verificada por compilar.

La clave aprobada que el usuario indicó que configuraría no se recibió en la variable
FOREVERDB_API_KEY del proceso. No se usaron otras credenciales ni se intentó eludir el 401.
La documentación explica cómo obtener una respuesta en cuarentena sin distribuir la clave.
