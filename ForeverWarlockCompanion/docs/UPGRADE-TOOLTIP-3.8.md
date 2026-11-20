# Indicador de mejora 3.8

Actualización 3.9: la captura del usuario mostró un fallo de reflow de este diseño en el
cliente. Se sustituye por la [tarjeta inferior independiente](UPGRADE-TOOLTIP-3.9.md),
con estados verde/rojo y sin modificar las fuentes o la altura del tooltip nativo.

La extensión de Forever Companion muestra un solo indicador bajo el nombre del objeto.
Sustituye el bloque de atributos, comparación y notas del hover anterior. La comparación
completa sigue disponible en el inspector y Stats. El inspector visual continúa limitado
a Fel Cape; esta entrega incorpora el extra solicitado antes de ampliar las demás fichas.

Formato con ranking publicado:

```text
Item Improvement - 2 BiS
+X.X% · +Y.Y GS/EP · https://foreverdb.net
```

| Puesto | Color WoW |
|---|---|
| 1 | Legendario naranja, ff8000 |
| 2–3 | Épico morado, a335ee |
| 4–5 | Raro azul, 0070dd |
| Resto o puesto desconocido | Verde, 1eff00 |

Sin puesto publicado se muestra Item Improvement en verde, sin ordinal BiS. No se
supone que el primer objeto del catálogo sea el mejor. Las reglas 4/5 y posteriores
están implementadas y probadas, pero el snapshot actual publica únicamente los puestos
disponibles de su referencia (47 registros, normalmente tres por ranura).

## Ranking y puntuación

Data from [ForeverDB.net](https://foreverdb.net). El ranking procede de la
[referencia Aflicción JcE 60](https://foreverdb.net/bis/warlock/affliction), con todas las
fuentes publicadas, incluidas bandas. Sólo se usa cuando coinciden clase, especialización,
nivel y build del cliente con el registro, con procedencia de guía publicada y sin flags
de copia beta, disponibilidad especulada o build histórico. Un sufijo aleatorio no hereda
el puesto de su objeto base. El puesto representa esa metodología de guía; no demuestra
el mejor objeto universal para cualquier especialización, nivel o escenario.

La mejora personal se calcula por separado. **GS/EP** nombra la puntuación ponderada por
atributos que ya usa el addon, no una escala de GearScore externa. El número indica la
diferencia absoluta de esa puntuación y el porcentaje se calcula contra la puntuación
positiva del equipo realmente equipado. No es DPS ni porcentaje de aproximación al BiS.

Settings conserva la elección de fuente. Automático usa pesos EP propios si existen y,
en su ausencia, puede consultar Forever Leveling BiS API v2, también para Fel Cape.
No se copian sus pesos ni código. Su perfil activo determina el score externo; el puesto
BiS sólo aparece si esa especialización coincide con la referencia publicada. La ficha
piloto conserva su comparación EP propia; la integración opcional del hover se identifica
en Settings y se explica aquí.

El indicador exige ganancia absoluta y porcentual positivas, compatibilidad de uso
confirmada y un cálculo válido. No aparece para downgrade, empate, datos pendientes,
porcentaje desconocido, ranura vacía o comprobación de copia Único-equipado pendiente.
En anillos/abalorios se toma la mejora válida mayor entre las dos ranuras reales.
No se introduce un perfil de pesos de ejemplo en los SavedVariables del jugador.

## Integración visual

`UpgradeIndicator` prepara el texto y el puesto. `UpgradeTooltip` coloca un frame propio
bajo GameTooltipTextLeft1 o ItemRefTooltipTextLeft1. Reserva espacio desplazando anclajes
nativos existentes; las dependencias entre líneas se desplazan una vez. El nombre conserva
su posición y no cambia el número de líneas nativas. Al retirar el indicador sólo se restauran
anclajes que siguen coincidiendo con los aplicados por esta extensión. Se preservan filas
que otra extensión añada o modifique. No se llama a ClearLines ni SetHyperlink recursivamente.

Se conservan TooltipDataProcessor y el hook clásico, el ciclo OnHide/OnTooltipCleared,
la invalidación de estadísticas por eventos y el caché de comparación. No hay escaneos
de inventario por frame. Ante tooltip protegido, texto restringido o anclajes no compatibles
se omite la extensión. `/fwc loot off` y Settings la desactivan y restauran la geometría.
Cada evento de objeto programa además una única recolocación al siguiente ciclo, para
respetar el reflow final del motor nativo. Esa recolocación no vuelve a programarse a sí misma.

## Preview y prueba

[Antes/después](validation-3.8/tooltip-comparison.png), exportado desde los frames Lua.
El antes corresponde al commit 09dd594 (3.7). Fel Cape conserva su puesto publicado 2;
el equipo y los pesos son controles sintéticos: 5.7 → 23.8 EP, diferencia +18.1 y +317.5%.
Estos números no describen al jugador de la captura del usuario. Las muestras inferiores
representan sólo la escala de colores. Iconos, fuentes y reflow son aproximaciones;
la imagen **no es una captura del cliente WoW**.

Para reproducir la imagen, exportar tests/export_upgrade_tooltip.lua sobre ambas versiones
y ejecutar tools/render_upgrade_tooltip.py con las dos rutas TSV y la ruta PNG de salida.
AGENTS.md conserva la preferencia del usuario por previews antes/después en futuros cambios visuales.

Recorrido pendiente en el cliente:

1. Instalar 3.8.0-preview, `/reload`, hover sobre Fel Cape con un perfil de pesos válido o
   Forever Leveling BiS API v2 activo. El texto debe quedar inmediatamente bajo el nombre.
2. Comprobar una mejora real contra la capa equipada: porcentaje y diferencia GS/EP deben
   corresponder al modelo elegido. Con perfil/build compatibles, Fel Cape debe indicar 2 BiS morado.
3. Equipar el mismo objeto o uno mejor y repetir: no debe aparecer el indicador. Sin cálculo
   válido tampoco debe aparecer. Un objeto sin ranking conocido puede mejorar y mostrarse verde.
4. Alternar enlaces, botín, equipo y chat; refrescar repetidamente. No deben acumularse espacio,
   frames ni líneas. Revisar las dos ranuras de joyería, uso no permitido y carga pendiente.
5. Probar `/fwc loot off` / `on`, cambio de especialización y otras extensiones de tooltip.
   Verificar que los textos nativos conservan su contenido y que el espacio se restaura.
6. Capturar el resultado en Forever para verificar el reflow real. Los dobles locales
   comprueban el contrato de anclajes, no certifican el motor C del cliente.
