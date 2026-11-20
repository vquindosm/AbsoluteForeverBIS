# Comparación e indicadores de botín — 3.5.0-preview

Al abrir botín de mazmorra o mundo abierto, los objetos equipables muestran una pequeña
insignia en la ventana estándar si sus filas exponen el slot de botín. Al pasar el ratón,
el tooltip muestra un panel con las ganancias y pérdidas frente al equipo real.
También admite el tooltip de enlaces de chat. No necesita abrir `/fwc` ni pertenecer al BiS.

## Interpretación

| Indicador | Significado |
|---|---|
| ↑ EP, verde | Mejora estimada con los pesos guardados en Stats y datos suficientes |
| ↓ EP, rojo | Menor puntuación con esos pesos |
| ↑ stats / ↓ stats | Gana/pierde atributos comparados; no es una valoración global |
| ? | Datos parciales, pendientes o compatibilidad no comprobada |
| = | Mismo objeto/variante o sin cambio en atributos/EP leídos; los efectos pueden diferir |
| + | Ranura vacía; no se inventa un porcentaje respecto a cero |
| ! | Requisito de uso/nivel o cambio de armas que impide una comparación directa |

El detalle enseña cada cambio, por ejemplo un aumento de poder con hechizos junto a una
pérdida de aguante. Mayús muestra más atributos. Estos ejemplos describen la interfaz;
no certifican valores de ningún objeto del juego.

Activado por defecto; `/fwc loot off` lo desactiva y `/fwc loot on` lo activa. Settings tiene
el mismo control. Se guarda por personaje sin modificar el esquema ni reiniciar preferencias.

## Reglas de comparación

- Se leen el enlace completo del botín y los enlaces equipados del cliente. Sufijos,
  encantamientos y variantes no se sustituyen por otra copia del mismo ID.
- La lectura no depende de que el objeto esté entre los 157 del catálogo o de que el inventario
  cacheado ya se haya actualizado. No se recorren bolsas en cada hover.
- Se usa el perfil EP seleccionado si corresponde a la clase del personaje. No hay pesos
  universales de relleno ni se usa el índice publicado de ForeverDB para valorar el drop.
- Sin pesos se muestran diferencias y, cuando procede, dominancia de atributos leídos,
  dejando claro que falta una valoración global. Un cambio mixto no se declara mejora global.
- Ausente, fallo, dato restringido y cero explícito son estados distintos. Los incompletos
  no obtienen porcentaje EP; las referencias offline no se usan para reparar el botín.
- Anillos y abalorios tienen comparaciones independientes con las dos ranuras actuales.
- Si añadir un anillo/abalorio aumenta las copias de ese mismo ID que ya llevas, se pide comprobar
  Único-equipado antes de mostrar una marca verde. Los límites de categorías únicas entre IDs
  distintos no se modelan: comprobar siempre el tooltip nativo.
- Un arma de dos manos considera también el accesorio/arma de mano izquierda que retira.
  La suma exige datos explícitos en cada pieza; no se supone cero para un atributo omitido.
- Una mano izquierda requiere cambiar primero un arma de dos manos equipada. Armas genéricas
  se comparan con ambas manos sólo si el cliente confirma la capacidad de doble empuñadura.
- Nivel requerido y respuestas nativas de uso/equipamiento impiden un aviso de mejora de un
  objeto no utilizable. Si esa comprobación no está disponible, el indicador queda incierto.
- EP modela estadísticas con pesos lineales, no DPS ni todos los procs, bonus, caps o daño de arma.
  Un EP positivo no garantiza más rendimiento en todos los combates.

## Integración y compatibilidad

Se usa `TooltipDataProcessor.AddTooltipPostCall` con fallback a `HookScript(OnTooltipSetItem)`.
Se requieren hooks de limpieza/ocultación, no se sustituyen los scripts ni el texto nativo,
y se reutiliza un panel propio por tooltip. Un resultado asíncrono sólo actualiza el objeto
que siga bajo el cursor. No hay polling permanente ni avisos de chat automáticos.

La insignia soporta `LootButtonN.slot` clásico y elementos de `LootFrame.ScrollBox` que
exponen `GetSlotIndex`. Respeta el slot real de filas recicladas. Los hooks seguros de
actualización y los eventos de botín refrescan el estado; el cierre oculta las insignias.
Una ventana personalizada que no exponga esas capacidades puede conservar sólo la comparación
del tooltip estándar. Estas comprobaciones de capacidad no prueban su comportamiento en Forever.

Referencias de contratos API: [Tooltip API](https://warcraft.wiki.gg/wiki/Tooltip_API),
[OnTooltipSetItem](https://warcraft.wiki.gg/wiki/UIHANDLER_OnTooltipSetItem),
[CanUseItem](https://warcraft.wiki.gg/wiki/API_C_PlayerInfo.CanUseItem) y la estructura de
[LootFrame de Blizzard](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/LootFrame.lua).
No se copia el código de esas fuentes. La lectura y valoración del botín usan el cliente;
los datos importados de otras pantallas mantienen el crédito a [ForeverDB.net](https://foreverdb.net).

## Prueba manual pendiente en WoW

1. Instalar el addon completo, `/reload`, comprobar Settings y `/fwc loot on` con ventana cerrada.
2. Abrir botín en una mazmorra y en mundo abierto. Hover sobre equipo y material: sólo el equipo
   debe mostrar comparación. Confirmar que recoger botín y sus controles nativos funcionan.
3. Con pesos propios guardados, contrastar un resultado positivo y uno negativo contra Stats.
   Sin pesos, comprobar diferencias por atributo y ausencia de porcentaje inventado.
4. Probar un anillo/abalorio frente a dos piezas distintas y un slot vacío. Revisar nombres,
   enlaces completos y cantidades sin que se elija silenciosamente una sola ranura.
5. Comparar 2H frente a 1H + accesorio, y accesorio con 2H equipada. No ignorar la pieza retirada.
6. Hover sobre un objeto no cacheado y cambiar de objeto antes de que cargue: el resultado tardío
   no debe aparecer en el nuevo objeto. Un fallo de carga indica `/fwc refresh` para reintentar.
7. Desplazar/actualizar/cerrar la ventana de botín: las marcas corresponden a los slots actuales
   y desaparecen al cerrar. Comprobar también el tooltip de un enlace de chat.
8. Cambiar equipo en combate y comparar de nuevo sin esperar al escaneo de bolsas. Revisar que
   las restricciones del personaje y las diferencias de variantes no se pierdan.
9. Probar `/fwc loot off`, reactivarlo y `/reload`, así como otros addons de tooltip/botín.
   No debe haber líneas duplicadas, botones bloqueados, compras/equipado/loot automáticos ni errores Lua.

Las pruebas locales son dobles de API con objetos sintéticos. No son capturas, drops reales
ni confirmación de compatibilidad dentro del cliente. Esa validación sigue pendiente.
