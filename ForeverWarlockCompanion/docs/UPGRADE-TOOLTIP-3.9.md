# Tarjeta inferior de comparación 3.9

La captura del usuario confirmó que la recolocación de textos de 3.8 podía separar el
nombre y los atributos, abriendo un espacio grande en la parte superior. Esta versión
elimina por completo esa recolocación: no lee, reancla ni redimensiona fuentes nativas,
y no modifica la altura ni las líneas del tooltip. Sólo posiciona su propio frame debajo.

La composición usa una tarjeta compacta con:

- Fondo y borde verdes ante mejora, rojos ante empeoramiento.
- Icono nativo de clase y nombre de clase/especialización del perfil que puntúa.
- Icono de especialización para Aflicción/Demonología/Destrucción; perfil genérico en otros casos.
- Porcentaje y diferencia GS/EP con sus signos originales.
- Etiqueta BiS publicada, cuando hay referencia compatible, separada del estado de mejora.
- Medidor con cero central: las mejoras crecen a la derecha y las pérdidas a la izquierda.

La escala del medidor es de −100% a +100%; se satura visualmente para cambios mayores,
sin recortar el porcentaje numérico. No representa porcentaje del mejor BiS ni DPS.
La tarjeta adopta el ancho del tooltip, con un mínimo para legibilidad y límite de pantalla.
Si no cabe debajo, se coloca a un lateral disponible, alineada al borde inferior. No se
coloca encima ni se fuerza una superposición sobre los atributos. Si no hay sitio, se omite.

## Datos conservados

Los cálculos de comparación no cambian. Se siguen usando los enlaces completos y el equipo
realmente equipado; pesos propios o la API opcional de Forever Leveling BiS según Settings.
GS/EP sigue siendo la diferencia de la puntuación ponderada del perfil, no GearScore de
otra herramienta. Se muestran ahora también los resultados negativos válidos. Empates,
carga pendiente, uso no confirmado o ausencia de cálculo siguen sin producir tarjeta.
En joyería se elige la mejor sustitución válida entre las dos ranuras existentes.

El encabezado refleja el perfil externo activo cuando éste proporciona el cálculo;
no se identifica ese perfil como la distribución de talentos leída del personaje.
La etiqueta BiS conserva las comprobaciones de contexto y la metodología publicada de
3.8; no se amplía el catálogo ni se inventan posiciones. Su color de calidad es independiente
del fondo: un objeto 2 BiS puede empeorar el equipo actual y aparecer en una tarjeta roja.

La URL se retira del score, a petición del usuario. El crédito permanece dentro del addon:
Settings, Item Explorer y las fichas muestran **Data from [ForeverDB.net](https://foreverdb.net)**.
No se copian datos/pesos privados ni código de Forever Leveling BiS.

## Compatibilidad y pruebas

Se mantienen TooltipDataProcessor y los hooks clásicos, la limpieza OnHide/OnTooltipCleared,
el caché y las invalidaciones por eventos. La recolocación única al siguiente ciclo sigue
el tamaño final del tooltip sin polling. No se depende de GameTooltipTextLeft1, GetName,
NumLines o los anclajes internos del cliente para dibujar la tarjeta.

La prueba impide leer/escribir fuentes nativas y comprueba que la tarjeta aún funciona.
También se verifican alturas/posiciones invariantes, icono de clase, perfil externo, fondos
completos, meter, cambio de verde a rojo, bordes, anchura, colisiones, temas y reutilización.

Previews: [antes/después](validation-3.9/tooltip-comparison.png) y
[empeoramiento](validation-3.9/tooltip-downgrade.png). El antes usa el commit 9a9b3e5 (3.8).
La simulación de frames **no reproduce el fallo de reflow C mostrado por el usuario**;
representa la composición anterior y la nueva a partir del código real de cada versión.
Iconos/fuentes son aproximaciones, no capturas del cliente WoW.

Los datos publicados de Fel Cape se conservan. Equipo y pesos de los ejemplos son controles:
5.7 → 23.8 EP (+18.1; +317.5%) y 45.7 → 23.8 EP (−21.9; −47.9%). Ninguno de esos porcentajes
describe al personaje de la captura del usuario ni se instala como perfil recomendado.

## Recorrido dentro de WoW

1. Reemplazar la carpeta completa, `/reload`, comprobar 3.9.0-preview.
2. Hover sobre el mismo Spellweaver's Turban de la captura. El nombre y los atributos deben
   permanecer juntos; la tarjeta verde debe estar debajo con los valores ya calculados.
3. Hover sobre un candidato peor con comparación válida: tarjeta roja y valores negativos.
4. Comprobar icono de clase y perfil de especialización, medidor, porcentaje y GS/EP. No debe
   aparecer la URL tras el score. El crédito sigue disponible dentro de Settings.
5. Probar enlaces de chat, botín, cambio rápido de objetos y perfiles, otra extensión de tooltip
   y distintos tamaños/escalas de UI. La tarjeta no debe duplicarse ni agrandar el tooltip.
6. Probar el borde inferior de la pantalla: debe utilizar un lateral libre y no tapar atributos.
7. `/fwc loot off` / `on`: sólo desaparece/reaparece la tarjeta, sin mover el texto nativo.

La comprobación de estos pasos en el cliente queda pendiente del usuario; los dobles locales
verifican geometría y datos, no certifican el motor de renderizado de WoW Forever.
