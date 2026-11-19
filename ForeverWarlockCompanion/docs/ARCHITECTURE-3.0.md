# Forever Companion 3.0 — arquitectura

## Auditoría previa

2.6 conserva servicios útiles: InventoryScanner por eventos, Catalog con IDs y procedencia,
Persistence por personaje/especialización, Compatibility, GearPlanner/EP, lectores de personaje
y modelo nativo. Se mantienen; no se sustituye su información por una simulación.

MainWindow mezcla shell, ocho pestañas, filtros y rutas. CharacterPanel abre siempre el catálogo
completo. ItemDetails y Tracker dependen de tablas de flags `planner` y variables UI globales.
SupportingPanels agrupa vistas distintas y el tracker sólo enumera fuentes, sin pasos guardados.
El mínimo 1100x700 y proporciones fijas limitan los detalles. Stats compara objetos y conserva
los pesos, pero no sustituye estadísticas del personaje ni una simulación. Los tests sólo
comprueban dobles de las APIs; la apariencia y el cliente real siguen sin validar.

## Diseño y compatibilidad incremental

- DesignSystem: tokens, temas Modern Azeroth/Blizzard Classic Inspired y componentes que
  reutilizan Widgets (tarjetas, barras, navegación, indicadores, vacíos y checklists).
- NavigationService: ruta, contexto, historial limitado y filtros de pantalla. Las rutas
  anteriores son alias válidos. Los paneles existentes siguen siendo reutilizables.
- MainWindow/MainShell: cabecera compacta, filtros plegables, sidebar desplazable, breadcrumb,
  Back y área de contenido. Dashboard es inicio; resolución menor usa menos columnas.
- ObjectiveService: objetivos y pasos persistentes por perfil y modo. `planner` permanece
  como referencia legacy, sincronizada por un adaptador. AcquisitionResolver usa sólo fuentes
  y costes existentes. No crea NPCs, requisitos ni muertes supuestas.
- ProgressService: inventario observado separado de adquisición manual y pasos manuales.
  Una muerte de jefe o una compra planificada nunca prueban posesión del objeto.
- DungeonService y MaterialAggregator agrupan datos de objetivos existentes; cobertura parcial,
  materiales desconocidos y cantidades sin verificar permanecen explícitos.
- Tracker ofrece foco, modos y pasos; la lógica de objetivos funciona con la ventana cerrada.

El esquema 3 migra flags una sola vez, conserva copias y referencias no resueltas; reiniciar
la migración no duplica objetivos. El esquema 2 no debe reejecutarse sobre el esquema 3.
Los objetivos contienen ID, item/slot/modo/perfil, fuente, estado, prioridad, pasos,
dependencias, confianza y fechas; los pasos tienen tipo, modo, cantidades y evidencia.

## Hitos y validación

A: shell, temas, sidebar, dashboard e historial; B: equipo/selector contextual y tarjetas;
C: objetivos, generación conservadora, migración y máquina de estados. Se comprueba la base
antes de extender D (tracker) y E (fuentes/crafting). F incluye geometría, regresiones y guía
manual. No se declara terminado un hito por un módulo vacío.

No se añade una API de lectura porque exista en otro cliente. Se reutiliza la exportación
documental 16001 consultada en versiones anteriores y las comprobaciones en ejecución.
No se incorporan lecturas de misiones, bosses muertos o recetas aprendidas sin implementación
comprobada. Son pasos manuales o estados desconocidos. Los mocks no certifican el cliente real.

## Implementación entregada y límites

A funciona con sidebar por grupos, dashboard, breadcrumbs/Back y dos temas seleccionables.
Character Progress reutiliza el resumen del Dashboard; no crea una segunda copia de estado.
B añade alternativas en Equipment y filtros avanzados del catálogo; una ventana estrecha
oculta la lista redundante y conserva modelo/ranuras y detalles en dos columnas. Stats y EP
continúan en Advanced Stats; Equipment presenta diferencias básicas cuando hay datos.
C genera y persiste objetivos, pasos y dependencias. La migración es idempotente desde v2.
D ofrece Compact/Expanded/Collapsed, foco, pasos manuales, prioridad, detalles y posición.
E aporta fuentes agrupadas (Dungeons/Reputations/Activities), enlace a recetas, búsqueda de
recetas, overview de profesiones/cooldowns y demanda agregada de materiales conocidos.
F tiene regresión automatizada y recorridos de tamaños; el renderizado real sigue pendiente.

El tracker y la máquina de estados funcionan sin la ventana principal abierta. InventoryScanner
conserva el debounce; no se añaden escaneos periódicos. Las barras muestran pasos o cantidades
conocidas. En reputación sólo se usa un umbral de cantidad si el siguiente rango que expone
el cliente ES el rango requerido. Si faltan umbrales posteriores, no se fabrica un total
hasta Exaltado: se muestran rangos y progreso cuantitativo desconocido.

Las zonas y las cadenas completas de dungeon/quests no se han importado. Las vistas son
fuentes y objetivos personales con cobertura parcial, no un Adventure Guide completo. No se
leen muertes, misiones ni libro de recetas por APIs nuevas. LearnRecipe/CraftItem/PurchaseItem
y muertes son pasos manuales con procedencia; completar esos pasos no equivale a posesión.
No hay predicción de DPS ni cálculo de rutas óptimas.

La estructura de dependencias acepta referencias entre pasos del objetivo y rechaza ciclos.
Los materiales se agregan entre objetivos por ID, o por nombre importado cuando no existe ID;
no se fusionan nombres de idiomas distintos sin una identidad verificada.
Los estados manuales sobreviven al desmarcar seguimiento y volver a activarlo. La adquisición
indica Observed in equipment/bags o Marked manually; se conserva el flag manual previo sin
presentarlo como detección. Los flags legacy se conservan como adaptador, no como motor nuevo.
