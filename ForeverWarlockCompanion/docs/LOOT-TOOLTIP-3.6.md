# Tooltip de botín 3.6

El bloque ancho independiente de 3.5 se sustituye por dos líneas nativas: cabecera con
icono y cuerpo compacto multilínea. Los atributos se agrupan de dos en dos con iconos;
verde indica ganancia y rojo pérdida. Se conservan el nombre del equipo comparado,
las dos comparaciones de anillos/abalorios, las restricciones y los estados pendientes.
Mayús amplía los atributos. El fallback separado sólo se usa si faltan las capacidades
estándar de las líneas del tooltip. No se reconstruye el tooltip ni se altera texto ajeno.

## Datos y puntuación

- Se conservan ambos enlaces completos, con encantamiento y sufijo aleatorio.
- `C_Item.GetItemStatDelta` o su equivalente global aporta diferencias explícitas. Antes
  de aceptarlas se comprueba la dirección con diferencias numéricas de atributos comunes.
  Respuestas incompatibles, restringidas, no finitas o sin ancla se descartan.
- Una diferencia explícita permite reconstruir sólo ese atributo de esa pareja. El caché
  original no se cambia. Omitir un atributo en una tabla dispersa nunca basta para darle 0.
- Las comparaciones que cambian ambas manos conservan la ruta del conjunto de equipo.
- Los atributos usan los nombres localizados del cliente. El sufijo histórico `RATING`
  en una clave no autoriza convertir puntos en porcentajes. No se importan fórmulas de
  Classic para calcular salud, maná, regeneración o crítico de Forever.

La dependencia opcional `ForeverLevelingBiS` ofrece puntuación mediante su
[API pública v2](https://github.com/thunder426/ForeverLevelingBiS-API).
Se llama a `GetSpec`, `ScoreItem` y `OnChanged`; no se copian pesos ni código del addon.
Las llamadas tienen contención de errores y las notificaciones se agrupan al siguiente
tick. No se usa `IsUpgrade`, condicionado por sus opciones de bolsas. Se puntúa por
separado el equipo realmente equipado en cada ranura: `GetGain` puede comparar contra
un conjunto guardado diferente, y no sirve como baseline de nuestro tooltip.

Automático conserva los EP configurados explícitamente; sin ellos intenta la API externa.
Settings permite forzar cualquiera de las dos fuentes. El proveedor y su especialización
se identifican. Una fuente externa seleccionada pero no disponible no se sustituye por
otra puntuación de forma silenciosa. Cambiar el tipo de arma/configuración no recibe una
puntuación externa por objeto como si demostrara una mejora del conjunto de las dos manos.
Sólo hay porcentaje cuando la puntuación equipada es positiva. EP/puntuación no es DPS,
y la API no proporciona un porcentaje del mejor BiS ni un ranking por ranura.

La consulta externa sigue la especialización, modelo y opciones del jugador en ese addon;
no exige que coincidan con la vista de Forever Companion. La clase sí debe coincidir con
el personaje. Los datos de adquisición/fichas conservan el crédito:
[Data from ForeverDB.net](https://foreverdb.net). Ningún dato privado o clave se distribuye.

## Regresión y prueba en el juego

`tests/loot_visual.lua` reproduce la forma del caso comunicado con respuestas sintéticas:
botas candidatas con 13 Intellect, 13 Spirit, 52 Armor frente a 7 Intellect, 10 Spirit,
58 Armor, 9 Spell power y 17 Stamina. La comparación devuelve +6, +3, -6, -9 y -17.
La puntuación externa de control usa 3.7 frente a 13.6: -9.9 y aproximadamente -73%.
No afirma que estos fixtures sean una base de objetos verificada ni renderiza WoW.

Pendiente en Forever 1.60.1:

1. Sustituir la carpeta completa, `/reload`, comprobar versión 3.6.0-preview.
2. Hover sobre las mismas botas con sufijo. Capturar tooltip antes/después: bloque
   dentro del marco, iconos legibles, verdes/rojos, sin panel separado ni duplicación.
3. Con Forever Leveling BiS API v2, seleccionar su fuente en Settings y comprobar
   perfil/puntuación y ambas referencias equipadas. Si usa un conjunto guardado externo,
   nuestro porcentaje debe seguir correspondiendo a lo realmente equipado.
4. Comprobar -9 Spell power y -17 Stamina si el cliente publica esas diferencias.
   Si su API no expone alguna cantidad, debe seguir como desconocida; no inventarla.
5. Cambiar perfil externo y equipo con el tooltip abierto; probar Mayús, enlace de chat,
   dos anillos, manos, botín desplazado, datos aún cargando y objetivos no equipables.
6. Probar con/sin API externa, con pesos propios, con flechas de bolsas externas
   desactivadas, desactivar/reactivar `/fwc loot` y cambiar rápidamente de tooltip.

Las pruebas locales validan contratos y ciclo de vida. No equivalen a una captura
comparativa ni certifican que el motor del juego haya renderizado el resultado.
