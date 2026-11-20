FOREVER COMPANION 3.8.0-preview — interfaz 16001

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


3.3.3 — FOREVERDB AUTENTICADO
Data from ForeverDB.net — https://foreverdb.net
Documentación consultada: https://foreverdb.net/developers
El catálogo activo usa Catalog/api-vendor-slice.json, normalizado desde cuatro registros
individuales de objetos y el vendedor 227853. La API confirma la moneda 3469 por 75 unidades
para Arcanoweave Cloak, precio publicado 0 cobre por compra, NPC y coordenadas 28.5, 75.8.
El plan consulta C_CurrencyInfo; item 226404 en bolsas no sustituye ese saldo. Una lectura
no disponible sigue siendo Unknown. La oferta ilimitada publicada no prueba stock actual.
Reputación requerida, quests y restricciones no publicadas siguen UNKNOWN. Se conservan
método, objetivo y notas. Los costes actuales sólo prevalecen con ese vendedor abierto.

Los atributos API de Felcloth/Dreamweave y la capa son referencias parciales, con prioridad
para la lectura del cliente. No se convierten unidades de Hit sin revisar ni se conceden EP
con referencias parciales. Crédito/enlace visible en los paneles que muestran estos datos.
La API se consulta fuera de WoW. No se distribuyen claves ni metadatos privados de cuenta.
Catalog/public-vendor-slice.json es un archivo histórico de 3.3.2, no la fuente del build actual.
La comprobación dentro de WoW y la importación masiva siguen pendientes.


3.4.0 — FICHAS VISUALES, ENCANTAMIENTOS Y REQUISITOS
Data from ForeverDB.net — https://foreverdb.net
Equipment conserva al personaje 3D y sus ranuras. El detalle del objeto cambia su composición:
atributos junto a dos alternativas con icono; debajo, mejoras recomendadas; después, requisitos
de equipamiento y origen, separados de la comparación y los pasos. Las alternativas se pueden
pulsar y hoverean el tooltip del juego. Las acciones secundarias siguen dentro de More options.

157 objetos consultados individualmente en la API: atributos, nivel requerido, vinculación,
unicidad y advertencias de disponibilidad/build. Todas las fichas tienen requisitos publicados
y señalan restricciones extra no confirmadas. Nivel de equipo y habilidad para fabricar son
conceptos separados; no se exige Sastrería 295 para llevar la Toga del Vacío por inferencia.

17 mejoras de referencia para Aflicción JcE 60: encantamientos, arcanos, inscripción y kit.
Pulsa una mejora para expandir su fórmula, materiales en bolsas, vendedores/coordenadas y
costes cuando están publicados. Hay fuentes distintas por facción, orígenes Classic señalados
y opciones de utilidad para la capa. El kit requiere nivel de objeto 35; no nivel de personaje 35.
El origen desconocido de un arcano no se convierte en un vendedor o quest inventado.
Los materiales para 29 objetos fabricables también se muestran en Dónde conseguirlo.

El índice publicado de la guía ForeverDB tiene contexto propio: Aflicción JcE nivel 60,
todas las fuentes, que pueden incluir bandas. No cambia el orden del catálogo Pre-BiS,
no es EP de tu personaje y no demuestra porcentaje de mejora o DPS. Identidades por ID,
sin unir objetos distintos por compartir nombre. El EP y la comparación del cliente conservan
sus controles anteriores y no usan estos índices o referencias como estadísticas confirmadas.

El addon no accede a Internet, compra, equipa ni aplica encantamientos automáticamente.
Las claves/respuestas privadas siguen fuera del paquete. Leer docs/ITEM-GUIDE-3.4.md,
ITEM_GUIDE_COVERAGE.json y las comparativas de geometría simulada en docs/validation-3.4.


3.5.0 — INDICADORES DE MEJORA EN EL BOTÍN
Activados por defecto. /fwc loot on | off; también en Settings.
La ventana de botín estándar muestra una marca junto al objeto y el tooltip desglosa ganancias
y pérdidas frente al equipo actual. Funciona igual en mazmorras y en mundo abierto, también
con objetos fuera del catálogo, y en enlaces de chat a través de ItemRefTooltip.

↑ EP = mejora estimada con tus pesos de Stats. ↓ EP = menor puntuación con esos pesos.
↑ stats / ↓ stats = gana/pierde atributos leídos, sin valoración global de DPS.
? = comparación incompleta, carga pendiente o uso sin comprobar. + = ranura vacía.
El detalle enseña cambios concretos como +6 Spell power y -5 Stamina. Mayús amplía los cambios.
Sin pesos o datos suficientes no se inventa un porcentaje. Efectos, bonus y caps pueden quedar
fuera de EP: no es una simulación de DPS. Los atributos ausentes no se convierten en cero.

Anillos y abalorios se comparan con las dos ranuras. Un arma de dos manos se compara con el
arma y mano izquierda actuales; una mano izquierda no se declara mejora directa mientras
lleves un arma de dos manos. Se respetan los enlaces completos y las variantes del objeto.
El equipo se consulta en el cliente incluso con inventario cacheado o en combate.
No se equipa, compra, recoge botín ni se envían mensajes de grupo automáticamente.

La integración usa TooltipDataProcessor si está disponible o hooks del tooltip clásico,
sin sustituir scripts/texto de Blizzard u otros addons. La insignia del botín admite botones
clásicos con slot y elementos ScrollBox con GetSlotIndex; interfaces de botín personalizadas
pueden mostrar sólo el indicador del tooltip. Prueba dentro de WoW aún pendiente.
Ver docs/LOOT-INDICATOR-3.5.md. Este indicador usa estadísticas del cliente, no puntuaciones
publicadas por ForeverDB ni referencias offline para declarar una mejora.


3.6.0 — TOOLTIP COMPACTO Y PERFIL DE FOREVER LEVELING BIS
El resumen pasa al interior del tooltip nativo: iconos de atributos, ganancias verdes,
pérdidas rojas y dos atributos por fila. Ya no crea un panel ancho separado en clientes
con las líneas estándar del tooltip. Mayús amplía el desglose. No inventa vida, maná,
regeneración o crítico derivados con fórmulas de otra versión del juego.

GetItemStatDelta permite recuperar pérdidas explícitas que GetItemStats no expone como
ceros: por ejemplo perder poder con hechizos o aguante al cambiar a un objeto sin ellos.
Los datos pendientes, errores y referencias offline siguen sin convertirse en cero.
La dirección de la comparación nativa se valida con atributos comunes a los dos objetos.

Forever Leveling BiS es opcional. Si ofrece API pública v2, se consultan sus puntuaciones
para el perfil activo y los enlaces completos del objeto actual y del candidato. Los sufijos
aleatorios se conservan. Se muestra puntuación, cambio absoluto y porcentaje cuando el
equipo actual tiene puntuación positiva. No se publica un porcentaje del mejor BiS ni un
ranking que la API no proporciona. Los cambios de configuración de armas requieren cautela.

Settings > Botín: Automático usa tus pesos EP si existen; después intenta Forever Leveling BiS.
Puedes elegir expresamente Forever Leveling BiS o sólo tus pesos EP. El perfil del addon
externo se identifica en el tooltip; puede diferir del seleccionado en Forever Companion.
Sin proveedor/pesos suficientes se muestran los cambios de atributos sin valoración global.
Desactivar sus flechas de bolsas no desactiva la puntuación de Forever Companion.

API utilizada: https://github.com/thunder426/ForeverLevelingBiS-API
No se distribuyen código, pesos ni datos privados de ese addon; sólo se consulta su API.
Los datos de adquisición y fichas siguen atribuidos a ForeverDB.net — https://foreverdb.net.
Validación local con APIs simuladas; prueba visual y datos del cliente Forever pendientes.
Recorrido manual y límites: docs/LOOT-TOOLTIP-3.6.md.


3.7.0 — ITEM INSPECTOR 2.0 · PILOTO FEL CAPE
Se activa sólo para Fel Cape (279269). Los demás objetos conservan su ficha actual.
Cabecera con rareza, ilvl, posesión y fuente; atributos con iconos; comparación contra
la capa realmente equipada; receta con cantidades/existencias/faltantes; precios separados.
Crit 14 permanece en su unidad publicada, sin convertirlo automáticamente en porcentaje.
Origen del patrón pendiente de confirmar. No se exige Sastrería 300 para equipar la capa.

Se distinguen materiales de fabricación, compra al vendedor, reventa al vendedor y mercado.
Los 99s 99c publicados son REVENTA. No se utiliza ese importe como compra o valor de subasta.
La afinidad de guía de Aflicción es una referencia JcE 60, no una mejora personal.
Data from ForeverDB.net — https://foreverdb.net

El servicio UpgradeComparison usa claves estables y comparación nativa entre enlaces
completos. Se comparte entre ficha, indicadores y tooltip; caché invalidada por eventos.
El piloto requiere pesos EP propios y cobertura válida. Sin ellos: Upgrade score unavailable
y EP: Not calculated. La integración opcional de Forever Leveling BiS sigue disponible
para los otros objetos, sin sustituir los pesos requeridos para este caso piloto.
Indicadores del piloto: verde/rojo con diferencia EP, neutro dentro del umbral y ? sin cálculo.
Settings permite ajustar el umbral absoluto de EP y desactivar la extensión del tooltip.
No es una simulación de DPS ni un ranking absoluto. IDs/API/procedencia están en Advanced Details.

Previews de los frames Lua en docs/validation-3.7: objeto publicado con equipo/bolsas simulados,
iconos y fuentes aproximados. No son capturas de WoW. Prueba real y generalización de las
fichas pendientes; instrucciones y criterios en docs/ITEM-INSPECTOR-3.7.md.


3.8.0 — INDICADOR DE MEJORA BAJO EL NOMBRE
El hover sustituye el bloque detallado de comparación por un solo indicador compacto:
Item Improvement - 2 BiS
+porcentaje% · +puntos GS/EP · https://foreverdb.net
Sólo se muestra con mejora numérica positiva, equipo actual conocido y uso confirmado.
Sin mejora, sin pesos/proveedor válidos, con carga pendiente o con ranura vacía no se añade nada.

Colores: 1 BiS naranja legendario; 2/3 morado épico; 4/5 azul raro; resto verde.
El puesto procede de la referencia publicada compatible con clase, especialización, nivel
y build. La cobertura actual es Aflicción JcE 60 y 47 posiciones publicadas. No se ordenan
los objetos del catálogo para inventar un ranking. Sin puesto conocido se indica mejora
en verde, sin número BiS. Las reglas 4/5 y posteriores están disponibles para datos publicados
futuros. Fel Cape conserva su posición publicada 2 para el perfil compatible.
Data from ForeverDB.net — https://foreverdb.net

GS/EP es la puntuación ponderada del objeto que usa Forever Companion: diferencia de EP
propio o de la API activa de Forever Leveling BiS. No es GearScore de otro addon ni DPS.
El porcentaje compara ese mismo modelo contra el objeto realmente equipado, no contra
el mejor BiS. Settings selecciona la fuente. Automático conserva los pesos propios cuando
existen; en su ausencia puede usar Forever Leveling BiS API v2, también con Fel Cape.
La comparación completa permanece en la ficha y Stats. No se amplía aún el inspector
visual al resto de objetos.

La extensión reserva espacio bajo el nombre y restaura sus anclajes al ocultarse. No añade
líneas nativas ni reconstruye el tooltip. /fwc loot off | on y Settings permiten desactivarla.
Preview antes/después en docs/validation-3.8; usa equipo/pesos simulados y no es una captura
del cliente. Recorrido de prueba y metodología: docs/UPGRADE-TOOLTIP-3.8.md.
