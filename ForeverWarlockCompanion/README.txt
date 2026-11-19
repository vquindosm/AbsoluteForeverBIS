FOREVER COMPANION 3.3.2-preview — interfaz 16001

Instala la carpeta ForeverWarlockCompanion completa en
World of Warcraft/_forever_/Interface/AddOns/ y abre /fwc.
No anides otra carpeta del mismo nombre ni cargues a la vez versiones anteriores.
Antes de reemplazar una instalación, conserva una copia de los SavedVariables.
El addon mantiene su nombre y ForeverWarlockCompanionDB por personaje.

INICIO
Dashboard resume el personaje, objetivos de equipo válidos, adquisición y próximos pasos.
La barra lateral da acceso directo a Equipment, Advanced Stats, Talents, Item Explorer,
Dungeons, Reputations, profesiones, crafting, cooldowns, My Objectives y actividades.
Filters despliega clase, especialización, profesiones y modo. Back restaura la pantalla y
el contexto anterior. La sección y los objetivos se conservan al recargar.

RECORRIDO
1. Equipment: el personaje ocupa la columna principal, con ranuras a ambos lados y armas abajo.
   Actual / Planned cambia la vista; Restore actual appearance restaura el modelo.
2. Alternatives: elige un candidato y compara en el mismo panel. Pulsa el icono del objeto
   para abrir Item Details a ancho completo. Item Explorer también ofrece Open item details.
3. Set as Target cambia la planificación y la apariencia Planned; nunca equipa objetos reales.
4. Track Objective activa seguimiento. My Objectives abre los pasos persistentes.
5. My Objectives muestra origen, estado, pasos y evidencia. Los pasos manuales se alternan
   con un clic. Añade un paso propio escribiendo en el campo y pulsando Add step.
6. View source lleva al grupo de dungeon/reputación, a la receta o a actividades.
7. En fuentes agrupadas, pulsa un objeto para volver a sus pasos; Back conserva el contexto.
8. El tracker permite Compact / Expanded / Collapsed pulsando la cabecera. Selecciona un
   objetivo para expandir pasos. Actions cambia prioridad, foco o seguimiento. Open Details
   abre My Objectives. Arrastra la cabecera o la esquina inferior derecha; modo y posición
   se guardan. Puedes ocultarlo con /fwc tracker. La tarjeta Next action destaca el próximo paso.

DATOS
El catálogo Affliction Pre-BiS conserva sus 157 objetos, 173 entradas por ranura y 10 cascos,
importados sin ranking. BiS y los demás catálogos siguen pendientes. Se mantienen las nueve
clases y las 29 variantes enumeradas por la referencia. Los objetivos se separan por perfil
y modo. La selección predeterminada sigue siendo el primer objeto importado, no el mejor.
Los estados manuales se conservan incluso al quitar seguimiento y recuperarlo después.

ESTADOS
Not Started / In Progress / Ready to Acquire / Obtained / Blocked / Unknown.
Completar un dungeon, jefe, misión o fabricación como paso manual NO prueba la adquisición.
La posesión se comprueba por IDs en bolsas/equipo, o se marca manualmente de forma explícita.
Los detalles distinguen esa evidencia. No se leen banco cerrado ni personajes alternativos.
Las dependencias de pasos se validan y no admiten ciclos; la edición visual de dependencias
no forma parte de esta preview.

PROFESIONES Y REPUTACIÓN
Recipes incluye búsqueda y enlaces desde objetivos. Crafting Planner agrega sólo costes
conocidos; los que faltan permanecen desconocidos. No se declaran recetas aprendidas ni
cooldowns reales sin información. Mooncloth conserva historial manual y la advertencia de
que 2 Felcloth / 95 horas son valores heredados sin verificar.
La reputación usa los datos disponibles del cliente y la asociación manual de facción de
versiones anteriores. Un umbral hasta el siguiente rango sólo representa el objetivo final
cuando ese siguiente rango ES el requerido. En otro caso la cantidad restante queda
sin verificar; no se confunde una barra parcial con progreso completo a Exaltado.

ESTADÍSTICAS
Advanced Stats mantiene comparación de objetos y pesos EP editables, y /fwc stats continúa
funcionando. Las diferencias numéricas requieren datos del cliente; EP además requiere pesos
compatibles que el usuario introduzca. No hay pesos predeterminados inventados ni simulación
DPS. Equipment muestra diferencias básicas cuando están disponibles. Se conservan procs,
sets, topes y otras limitaciones como cuestiones no evaluadas por el modelo lineal.

TEMAS Y TAMAÑO
Settings permite Modern Azeroth y Blizzard Classic Inspired. La ventana admite tamaños
lógicos desde 880x640. Equipment mantiene dos columnas; los bloques de detalle y las
tarjetas de Dashboard se reorganizan y admiten scroll cuando falta espacio. El escalado y el
renderizado real de fuentes/modelos todavía necesitan revisión dentro del cliente.

COMANDOS CONSERVADOS
/fwc; /fwc dashboard; /fwc gear; /fwc explorer; /fwc stats; /fwc specs; /fwc prof;
/fwc planner; /fwc objectives; /fwc dungeons; /fwc route; /fwc settings; /fwc refresh;
/fwc tracker; /fwc choose <ranura 1-17> <alternativa>; /fwc done <ranura>;
/fwc mooncloth; /fwc history; /fwc diag.

PRUEBAS Y CONSTRUCCIÓN
Ver docs/ARCHITECTURE-3.0.md, docs/CHANGELOG-3.0.md, docs/PENDING-3.0.md y
 docs/PRUEBAS-3.0.md. Desde la carpeta del addon:
 lua tests/run.lua modern
 lua tests/v3.lua modern
Repetir con legacy, no-model y player-model. Los fixtures no se cargan por el .toc.
 python3 tools/build_zip.py /ruta/fuera/del/addon/ForeverCompanion-3.0.0-preview.zip

La compatibilidad efectiva con el cliente real no ha sido certificada. Las pruebas usan
Lua 5.1 y dobles de API, no ejecutan World of Warcraft. La documentación de versiones 2.x
se conserva como referencia histórica; los cambios actuales están en los documentos 3.0.

NOVEDADES 3.1 — DASHBOARD
Rediseño visual inspirado en la imagen aportada: cabecera concisa, seis accesos principales
y More para las vistas adicionales, más tarjetas apiladas para progreso de equipo, siguiente
objetivo y actividades. Las cifras, la prioridad y el icono proceden del personaje y de sus
objetivos; no se muestran los números de la imagen de referencia. Pulsa la tarjeta del objetivo
para abrir sus pasos. Un estado vacío indica cómo comenzar. Las secciones y datos de 3.0 siguen
disponibles. El aspecto real en WoW Forever aún está pendiente de validación visual.

NOVEDADES 3.2 — EXPERIENCIA VISUAL
Dashboard desplazable con resumen del personaje, progreso de equipo, hasta tres objetivos
prioritarios, actividades por fuente, estadísticas rápidas, Mooncloth/materiales y accesos
rápidos. Los datos proceden del personaje y de objetivos seguidos; los guiones indican datos
no disponibles. La disponibilidad real de Mooncloth no se deduce de la estimación heredada.
El detalle muestra estado/fuente, estadísticas de guía, comparación resumida y pasos basados
en metadatos existentes. More options conserva acciones y explicaciones avanzadas.
My Objectives muestra icono, estado, siguiente acción y barra de pasos; el tracker diferencia
completado, pendiente y bloqueado. Los pasos previos no demuestran adquisición del objeto.
Ver docs/UX-3.2.md. La presentación aún no se ha probado en el cliente real de WoW Forever.

REWORK VISUAL 3.3
Dashboard sigue la composición de la primera referencia: resumen/progreso arriba, tres
objetivos horizontales, cuatro actividades, estadísticas en rail y acciones al pie.
La barra lateral agrupa Character, Gear & Content, Professions y Progression; los grupos
se pueden plegar. Equipment, Item Details y My Objectives siguen los bloques de la segunda
referencia. Las texturas de piedra y esquinas doradas son propias; se incluyen en Media.
No se copian los números, nombres, estados, costes ni estadísticas del diseño conceptual.
More options mantiene IDs, procedencia y limitaciones de EP fuera de la vista principal.
Las comparativas en docs/validation son inspecciones de geometría con APIs simuladas.
NO son capturas de WoW. Queda pendiente el checklist de renderizado real documentado
en docs/MOCKUP-3.3.md antes de declarar esta preview visualmente aceptada en el cliente.

3.3.1 — FASE 1: ESTADÍSTICAS INDIVIDUALES
Esta entrega implementa sólo la primera fase de la mejora iterativa solicitada. No cambia
el Dashboard ni añade rating global o árboles visuales. El motor individual utiliza ahora
una lectura compartida de cliente, caché por enlace completo y estados por atributo.
0 = cero explícito; Not present = la API no expone ese atributo, NO demuestra cero;
Data pending = carga pendiente; Read error = error de lectura; Unknown = no disponible.
No se calculan diferencias sustituyendo datos ausentes por cero. Los EP individuales
anteriores se conservan sólo cuando sus entradas y pesos permiten un cálculo válido;
la cobertura sigue limitada a los atributos soportados, no a todo el rendimiento del objeto.
Los datos importados sin verificar sólo aparecen como guía en Advanced information.
Settings incluye Item stat diagnostics e Inspect Felcloth Gloves. El registro está apagado
por defecto, es acotado (80 entradas), se guarda en SavedVariables y se imprime con /fwc diag.
Actualizar datos o /fwc refresh permite reintentar lecturas fallidas.
Lee docs/PHASE-1-STATS-AUDIT.md y docs/PHASE-1-CLIENT-TEST.md antes de validar esta fase.
Fases 2–6: pendientes de validar los atributos individuales contra el tooltip del cliente.

3.3.2 — DATA FOUNDATION / UN VENDEDOR
No hay rediseño. Se conservan los 157 objetos y las 28 recetas anteriores, perfiles y selecciones.
La nueva capa offline añade cuatro referencias estadísticas y una oferta de vendedor:
Arcanoweave Cloak, Pix Xizzix, 75 Tarnished Undermine Real. La referencia pública indica
nivel 60; no publica todos los requisitos, por lo que oro adicional, reputación, quests,
stock, coordenadas y NPC ID permanecen UNKNOWN en ese registro.
No se deducen requisitos de la afiliación del vendedor. No se usa el precio de venta como compra.

Settings > Track vendor: Arcanoweave Cloak abre el objetivo. My Objectives, Item Details
y el tracker usan el resolver de requisitos y el inventario de moneda actual. Al abrir el
vendedor en el juego se pueden observar precio efectivo, costes y stock con APIs disponibles;
no se compra nada automáticamente. Al cerrarlo deja de considerarse actual esa observación.
La posesión del objeto completa el objetivo sin transformar requisitos desconocidos en hechos.
Las notas/dependencias manuales y el plan anterior se conservan. No se equipan objetos reales.

Los datos offline de stats sólo sirven como referencia * para el mismo build y la variante
base; tienen cobertura parcial y se excluyen de EP. No rellenan con cero atributos ausentes,
no sustituyen ceros explícitos del cliente ni convierten el Hit de unidad desconocida a %/rating.
El registro muestra resultados crudos, normalizados, atributos no expuestos, fuente y errores.
Felcloth Gloves y Dreamweave Gloves tienen casos nuevos de regresión con registros publicados.

Catalog/schema.json + Catalog/public-vendor-slice.json generan Data/Foundation.lua y SQLite
con tools/import_foundation.py. Python y las credenciales sólo se usan fuera del juego.
La API autenticada requiere FOREVERDB_API_KEY; nunca guardar esa variable en el addon o ZIP.
El mapping de una respuesta autenticada aún no está validado; las once sondas sin clave dieron 401.

Leer docs/DATA_SOURCES.md, DATA_MODEL.md, UPDATE_CATALOG.md, VENDOR_SLICE_TEST.md
y DATA_COVERAGE.json. Recetas nuevas de las doce profesiones y misiones: 0 importadas.
No se declara catálogo completo ni se importan los otros tres casos antes de validar éste en WoW.
