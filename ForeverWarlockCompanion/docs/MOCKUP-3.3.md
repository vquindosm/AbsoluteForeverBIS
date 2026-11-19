# Rework estructural 3.3 y aceptación visual

Se recibieron dos referencias. La primera fija la composición del Dashboard ancho.
La segunda completa Equipment, detalle de objeto y Mis objetivos. Sus números, nombres
y estados son ejemplos de diseño, no hechos que se deban importar al personaje.

## Diferencias identificadas antes de modificar cada pantalla

| Zona | 3.2 | Distribución implementada en 3.3 |
|---|---|---|
| Navegación | seis botones planos + More | cuatro grupos plegables y subsecciones visibles; marca y versión |
| Dashboard superior | resumen/progreso pequeños | dos tarjetas emparejadas con identidad y progreso |
| Objetivos prioritarios | lista vertical | tres tarjetas horizontales con icono, fuente, prioridad y próxima acción |
| Estadísticas | tarjeta en flujo principal | rail derecho junto a objetivos y actividades |
| Actividades | botones 2x2 | cuatro tarjetas horizontales; adaptación a dos columnas |
| Acciones | al final del flujo | barra inferior de anchura completa |
| Equipment | lista de objetivos + modelo estrecho + texto | modelo protagonista (~51%), seis ranuras a la izquierda, ocho a la derecha y tres armas abajo; detalle a la derecha |
| Detalle | texto continuo con subtítulos | bloques nativos de estadísticas, comparación, fuente, pasos y alternativas; ruta propia a ancho completo |
| Mis objetivos | lista + texto de estado y pasos | lista con barras, cabecera del objeto, progreso, tarjeta Next action, checklist y bloque de fuente/relacionados |
| Tracker flotante | próxima acción repetida en filas | tarjeta Next action destacada sobre el listado con iconos/progreso |
| Materiales visuales | fondos planos | textura propia de piedra oscura, esquinas metálicas doradas y progreso violeta |

El resumen muestra identidad, especialización detectada y profesiones leídas del personaje;
los filtros de planificación se identifican por separado en la cabecera.
La ventana usa frames Lua nativos. El modelo sigue siendo DressUpModel/PlayerModel con fallback.
No se equipa ni se transmogrifica el personaje real. Los iconos Current corresponden al equipo
observado; Planned muestra los objetivos. Seleccionar un candidato no cambia su estado de posesión.
Las ranuras conservan sus tooltips y seleccionan la comparación de su ranura; el icono de la ficha
abre el detalle completo. Set as Target activa Planned. Restaurar fuerza una lectura de apariencia.
Los refrescos normales conservan la firma del modelo para evitar recargas innecesarias.

## Evidencia local

Las cuatro imágenes de `validation/` comparan geometría de 3.2 y 3.3 a 1700x1040.
Proceden de `tests/export_layout.lua` + `tools/render_layout.py`. Se revisaron visualmente,
pero **no son capturas del cliente WoW**: los iconos están sustituidos por símbolos, las fuentes
son aproximadas, el modelo es un marcador y las APIs usan fixtures. No prueban la apariencia
final, carga de texturas, oclusión del modelo ni compatibilidad exacta con el motor real.
Las pruebas estructurales también cubren 880x640 y 1180x780, scroll y flujos conservados.

## Checklist de aceptación

| Criterio | Comprobación local | Validación dentro de WoW |
|---|---|---|
| Personaje y ranuras protagonistas | ancho principal y límites de 17 botones comprobados | pendiente: modelo, oclusión, iconos y tooltips nativos |
| Qué es, mejora, fuente y siguiente paso | bloques independientes; deltas/EP condicionados a datos y pesos | pendiente: contraste con objetos equipados y caché del cliente |
| IDs y notas técnicas ocultos | Advanced information oculto hasta More options | pendiente: lectura a escala UI habitual |
| Siguiente acción, pasos y progreso | misma fuente persistente en panel/tracker; checklist probado | pendiente: eventos reales de inventario/reputación |
| Jerarquía de acciones | Set as Target principal; Next action destacada; extras plegados | pendiente: evaluación de uso y legibilidad |
| Piedra, metal y dorado legibles | texturas propias incluidas y geometría inspeccionada | pendiente: carga TGA, contraste y fuentes reales |
| Layouts nuevos | comparativas de las cuatro vistas incluidas | pendiente: captura comparada con los mockups en el cliente |
| Sin datos de ejemplo como hechos | fixtures sólo en tests; las imágenes lo advierten | pendiente: contraste con personaje de prueba real |

Esta entrega es **preview**. No se declara completada la aceptación visual en WoW.

## Recorrido manual necesario en el cliente

1. Instalar toda la carpeta y comprobar `/fwc` a 1180x780 y en ventana amplia. Capturar Dashboard.
2. Abrir Equipment; comprobar las 17 ranuras, hover y selección. Alternar Current/Planned,
   cambiar un objetivo y restaurar. Confirmar que refrescos ordinarios no hacen parpadear el modelo.
3. Pulsar el icono de la ficha; capturar Item Details. Comparar dos objetos con datos cargados,
   abrir alternativas y More options. Los IDs sólo deben estar en Advanced information.
4. Seguir varios objetos; abrir My Objectives. Completar un paso manual, comprobar el siguiente,
   filtrar/buscar y recargar. Capturar esta vista y el tracker flotante, incluida reputación si existe.
5. Repetir a 880x640, con scroll y escala habitual. Revisar textos largos y APIs ausentes.
6. Comparar las capturas reales con las referencias y marcar la última columna del checklist.
