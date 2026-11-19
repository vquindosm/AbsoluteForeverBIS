# Auditoría y entrega por fases

Se han modificado los cuatro archivos entregados, manteniendo el identificador de addon,
la variable por personaje, `/fwc`, clases, rutas y el historial manual. Se añadieron módulos
que el `.toc` carga en orden. Los adjuntos originales permanecen fuera del paquete de instalación.
La revisión se hizo antes de cambiar el código; el diagnóstico, arquitectura, distribución
de pantalla y orden de fases se presentaron en el chat.

## Hallazgos de la versión recibida

| Hallazgo | Efecto | Cambio |
| --- | --- | --- |
| TOC/README 2.0.0, encabezado Lua 2.1.0 | Versión incoherente | 2.2.0-preview en todos los puntos |
| `GetItemInfo` global sin comprobación | Puede fallar en Forever | Adaptador `C_Item`, fallback sólo si existe |
| `local _, qty = GetContainerItemInfo and GetContainerItemInfo(...)` | El operador lógico colapsa retornos; puede perder la cantidad | Lectura explícita de tabla moderna / retornos antiguos |
| Equipo y bolsas recorridos por cada objetivo en cada render | Trabajo repetido | Snapshot compartido y debounce de eventos |
| Filas ocultas y abandonadas en cada refresco | Los frames WoW no se destruyen así; crecimiento por sesión | Pool de filas reutilizable |
| Objetivos únicamente `affliction:<slot>` | No escala a otros perfiles | Perfil clase/especialización, objetivos separados por modo |
| Alternativas heredan fuente del objeto principal | Puede atribuir un jefe incorrecto | Fuente individual por ID importado |
| Filtros de profesiones sólo se guardaban | No filtraban recetas | Filtrado efectivo por profesión |
| `renderPlanner()` sobrescribía los detalles tras el clic | El texto seleccionado desaparecía | Selección conservada al refrescar |
| “28” frente a 29 variantes enumeradas | Información incorrecta | Se conservan y cuentan las 29 |
| `TBD` y nombres sin IDs | Estados y previews poco fiables | IDs importados; selección heredada no resoluble queda explícita |
| `READY` basado en 95h heredadas | Confundía estimación con cooldown confirmado | Historial y aviso siempre etiquetados como estimación |
| API/UI y DB mezcladas en un único archivo | Difícil aislar fallos | Servicios separados, bootstrap e inicialización por evento |

## Arquitectura implementada

- `ForeverWarlockCompanion.lua`: namespace, versión y diagnóstico.
- `Data.lua`, `Data/`: clases, ranuras, rutas, catálogo y recetas con procedencia.
- `Services/Compatibility.lua`: acceso protegido a APIs y valores restringidos.
- `Persistence.lua`: esquema 2, migración, perfiles y respaldo original.
- `Catalog.lua`: validación, filtros y objetivos por ID.
- `InventoryScanner.lua`: una lectura de bolsas/equipo por lote de eventos, diferida en combate.
- `CharacterReader.lua`: personaje, profesiones y talentos, sin modificar el personaje.
- `ProfessionTracker.lua`: materiales importados, prioridades, estimación e historial manual.
- `GearPlanner.lua`: objetivos, cantidades, prioridades, fuentes y diferencias de estadísticas.
- `UI/`: widgets, ventana, personaje, visor, selector, detalles y paneles auxiliares.
- `Events.lua`: arranque tras SavedVariables, eventos comprobados y comando.

Character & Gear usa tres columnas con proporciones 28/32/resto: ranuras, modelo y detalles.
El mínimo lógico es 1100×700; el marco reduce su escala para pantallas pequeñas. Cada lista y
los detalles tienen desplazamiento. La selección de una ranura abre el explorador; confirmar
un objetivo vuelve al personaje en modo Planned. Las acciones sólo cambian planificación.

## Compatibilidad: evidencias y límites

`16001` identifica la interfaz objetivo, no demuestra una API antigua ni moderna por sí solo.
Se revisó el [volcado del cliente publicado por su autor](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api.json):
versión 1.60.1, build 70790, interfaz 16001, exportado el 5 de noviembre de 2026. También se
revisó la rama Forever del código UI distribuido por Blizzard, conservada en Gethe.
Esto confirma presencia documental en esa captura; **no equivale a ejecutar el addon en el
cliente del usuario ni garantiza que un objeto se renderice**.

| API | Evidencia revisada | Comportamiento si falta o falla |
| --- | --- | --- |
| `C_Item.GetItemInfo`, `GetItemStats`, `RequestLoadItemDataByID` | Exportación 16001 | Fallback comprobado a global; caché pendiente explícita |
| `C_Container.GetContainerNumSlots/GetContainerItemInfo` | Exportación; información en tabla | Fallback comprobado a globales; fallo -> Unchecked |
| `GetInventoryItemID/GetInventoryItemLink` | Globales exportadas | Equipo sin comprobar, sin afirmar ausencia |
| `GetProfessions/GetProfessionInfo` | Globales exportadas | Selección manual |
| `C_SpecializationInfo.GetSpecialization/GetSpecializationInfo/GetTalentInfo` | Firmas exportadas, query de talento en tabla | Selección manual; talentos vacíos explicados |
| `C_ClassTalents.GetActiveConfigID` y lectores `C_Traits` | Exportación | Fallback de lectura; no se invocan mutadores |
| `DressUpModel:TryOn`, `Dress` | FrameAPIDressUpModel exportado | Se comprueba el método y el resultado; fallback PlayerModel |
| `SetRotation`, `SetFacing`, `SetPortraitZoom` | Uso en SharedXML de la rama Forever | Se comprueban en el objeto real; control no disponible explícito |
| `SetUnit` | Herencia de PlayerModel; comprobación en ejecución | Modelo no disponible; interfaz restante funcional |
| Frame, Button, Slider, ScrollFrame, FontString, texturas | Base de la UI nativa; contratos probados con dobles | Requieren validar el renderizado en el motor real |
| Eventos y `C_Timer.After` | Registro protegido en ejecución | Evento rechazado queda en diagnóstico; debounce OnUpdate de un solo uso |

No hay comprobaciones del tipo `interface >= 100000`. Las capacidades se comprueban directamente.
No se usan EasyMenu, BackdropTemplate ni dependencias de bibliotecas UI. La carga de modelos,
TryOn asíncrono, visibilidad de cascos/capas, escala, fuentes y restricciones en combate necesitan
prueba en juego. Un `TryOn` aceptado se describe como petición enviada, nunca como resultado visual confirmado.

## Referencias de diseño y datos

- [WoWSims Forever Warlock](https://www.wowsims.com/forever/warlock/dps/): la página no expuso
  contenido legible al navegador de investigación y su descarga directa devolvió 403. Se revisó
  el [código público del selector de equipo](https://github.com/wowsims/forever/blob/master/ui/features/gear/components/GearPicker/GearPicker.tsx)
  y su FiltersMenu: selección por ranura, separación entre elección y configuración y filtros
  agrupados. Se adaptaron esos patrones a frames y listas nativas; no se importó su interfaz web.
- [WOWTBC Affliction Forever](https://wowtbc.gg/warcraftforever/bis-list/affliction-warlock/):
  navegación por clase/especialización y alternativas por ranura. Sus datos se obtuvieron del
  `page-data.json` público de Gatsby, con hash, fecha y URL en `import-manifest.json`.
- [Índice WOWTBC](https://wowtbc.gg/warcraftforever/bis-list/): el aviso indica que los objetos
  están sin ordenar y que la itemización sigue en revisión. Todos quedan `imported_unranked`.
- [ModelFrames de Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/ModelFrames.lua).
- [DressUp de Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/DressUpFrames.lua).

## Estado y trabajo pendiente

Las fases 2–3 y el recorrido de selección/persistencia de la fase 4 están implementados.
La fase 5 es parcial: hay inventario, objetivos, progreso, actividades, costes de encantamiento
importados y seguimiento manual. Faltan recetas de sastrería verificadas, detección de recetas
aprendidas, cooldowns reales y un lector completo del libro de recetas. La fase 6 mantiene las
29 variantes, pero no inventa catálogos ni builds. No se ha hecho una simulación de DPS.

Talents permite consultar ramas/rangos que exponga el cliente y guardar snapshots junto con los
objetivos efectivos. Elegir un snapshot lo asocia al perfil de planificación; no restaura ni
modifica talentos, y no es aún un editor interactivo de puntos hipotéticos. Los snapshots de
ramas de un personaje no se presentan como builds recomendados para otras especializaciones.

La comparación usa sólo datos actuales de `GetItemStats` para ambos enlaces, y muestra diferencias
numéricas sin pesos. No equipara automáticamente atributos importados con claves del cliente.
El inventario no lee el banco cerrado y no interpreta una API fallida como prueba de ausencia.

Validación automatizada: ver `tests/README.md` y `VALIDACION.txt`. Validación visual y de
compatibilidad efectiva: pendiente de ejecutar el recorrido de `PRUEBAS_EN_JUEGO.md`.
