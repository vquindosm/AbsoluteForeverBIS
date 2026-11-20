# Item Inspector 2.0 — Fel Cape, piloto 3.7

El inspector nuevo se activa **exclusivamente para Fel Cape (279269)**. No se rediseñan
Dashboard, navegación, Talents ni la distribución de Equipment. El resto de fichas conserva
su presentación hasta validar el piloto en el cliente. Los componentes nuevos y el cálculo
común están preparados para la ampliación posterior.

## Datos revisados

Data from [ForeverDB.net](https://foreverdb.net).
[Fel Cape](https://foreverdb.net/item/279269), revisado el 20-11-2026: épica, capa de tela,
ilvl 65, nivel 60, 50 armadura, 16 aguante, 15 daño de Sombras y 14 crítico. No se transforma
14 en porcentaje. La referencia de cliente publicada corresponde al build 1.60.1.70959.
Los valores publicados sirven para la ficha incluso si la lectura del cliente está pendiente;
se señalan como referencia y no se convierten automáticamente en datos de EP personales.

El snapshot API revisado el 19-11, ya incluido en Catalog/item-guide.json, contiene la receta
1306543 de Tailoring 300 y Pattern: Fel Cape (279318). Materiales para una capa:

| Material | Cantidad |
|---|---:|
| Malleable Essence of Nature (274030) | 1 |
| Mooncloth (14342) | 1 |
| Bolt of Runecloth (14048) | 5 |

Requiere Loom. La procedencia del patrón no está confirmada: no se inventa vendedor,
mazmorra o reputación. Sastrería 300 es habilidad de fabricación, no requisito para vestirla.
Los contadores de bolsas usan ID y distinguen lectura pendiente de cero confirmado.

Los **99s 99c son precio de reventa**, separados de compra y materiales. La compra al
vendedor no tiene oferta publicada; el mercado no tiene precio/reino/fecha que permita
mostrar una estimación. No se suman materiales en oro con precios inventados.

La guía de Aflicción JcE 60 publica una diferencia respecto a su mejor capa. La afinidad
se muestra como referencia de ForeverDB, separada de la comparación personal. No se
extrapola a otras especializaciones ni se utiliza ese porcentaje como mejora del personaje.

## Composición y cálculo

La vista principal contiene cabecera compacta, hasta cuatro atributos, equipo/candidato,
deltas positivos/negativos, receta, materiales y siguiente acción. El scroll conserva la
fuente legible. Alternatives se expande hasta tres tarjetas; View All abre Item Explorer.
More options muestra Advanced Details, con ID, URL del objeto, procedencia, importación,
API, identificadores y avisos. El crédito con enlace a ForeverDB permanece visible.

`Services/UpgradeComparison.lua` recibe enlaces/ID, clase, especialización y pesos.
Devuelve valores normalizados, deltas, score absoluto/relativo, cobertura, avisos y estado.
No compara nombres localizados. Las variantes aleatorias conservan el enlace completo.
Se reutiliza en el tooltip, el inspector y los indicadores; GearPlanner también delega el
score del piloto. Las comparaciones entre ambas manos conservan el tratamiento de loadout.

El caché se invalida cuando ItemStats recibe eventos de datos/refresh. No hay escaneos por
frame. Una tabla dispersa no basta para convertir ausencia en cero: la comparación nativa
debe aportar evidencia explícita y una dirección validada. Los aliases equivalentes se
cuentan una sola vez; los daños de escuela no se importan como Spell Power. Se bloquea EP
cuando hay representaciones solapadas o falta cobertura/pesos relevantes.

El piloto usa **pesos propios configurados**. Su falta produce Upgrade score unavailable /
EP: Not calculated, aunque haya afinidad publicada o API externa. La integración de 3.6
con Forever Leveling BiS se conserva para otros objetos. EP es un modelo lineal por objeto,
no DPS; los efectos, sets, caps e interacciones no quedan demostrados por esta estimación.

Los indicadores del piloto en Equipment e Item Explorer separan rating de posesión:
verde/rojo con EP, neutro cuando la diferencia absoluta cae dentro del umbral de Settings,
y ? si no hay cálculo válido o la compatibilidad no está confirmada.

## Previews y validación local

[Antes/después del panel](validation-3.7/item-comparison.png) y
[adquisición/costes](validation-3.7/acquisition-comparison.png) se generan desde la geometría
de los frames Lua mediante tests/export_inspector.lua y tools/render_layout.py. El antes es
el commit 7aa41af (3.6). Los datos publicados de Fel Cape son reales; la capa equipada y las
bolsas son fixtures. Iconos/fuentes se aproximan. **No son capturas del cliente WoW.**

El fixture de comparación usa una capa de prueba con 1 aguante, 11 daño de Escarcha y 70
armadura. Por tanto el cambio correcto es +15 aguante, +15 Sombras, +14 crítico, -11 Escarcha
y -20 armadura. Con pesos de control explícitos, el EP pasa de 5.7 a 23.8: +18.1. Estos pesos
son controles matemáticos de prueba y no se instalan como recomendación para el jugador.

## Recorrido en WoW Forever

1. Sustituir la carpeta completa, `/reload`, comprobar versión 3.7.0-pilot. Abrir `/fwc explorer`,
   filtrar Back y buscar Fel Cape. También se puede seleccionar como objetivo de Back.
2. Confirmar stats, ilvl, rareza y nivel con el tooltip nativo. Verificar que la ficha normal
   no muestra IDs, C_Item.GetItemStats, confirmed ni mensajes de importación.
3. Revisar Tailoring 300, patrón y materiales 1/1/5. Añadir/quitar materiales de bolsas y
   comprobar cantidades y faltantes. No aceptar que una lectura sin confirmar cuente como 0.
4. Confirmar que 99s 99c figura sólo como reventa. Comprobar que compra/subasta no presentan
   ese importe y que el porcentaje de afinidad se identifica como referencia de guía.
5. Hover en bolsa, botín y enlace de chat. El bloque Forever Companion · Upgrade debe usar
   la capa realmente equipada y mostrar los mismos deltas que la ficha. Las diferencias
   concretas dependen de tu capa real, no de los números del fixture descrito arriba.
6. Sin pesos propios, comprobar EP: Not calculated / Upgrade score unavailable e indicador ?.
   Con pesos completos de tu perfil, comprobar numéricamente el EP y su estado. Cambiar el
   umbral de Settings y verificar el estado neutro dentro del margen elegido.
7. Cambiar capa, objeto, especialización y tamaño de ventana. No debe haber mensajes Lua,
   contenido residual, solapamientos ni bloques duplicados. Probar datos no cargados y
   `/fwc loot off` / `on`. La posesión no debe confundirse con el rating.
8. Expandir alternativas y Advanced Details; comprobar View All, Set as Target, Track Objective,
   Mark as Obtained y preview del personaje. Confirmar que el resto de fichas sigue funcionando.

Compatibilidad inspeccionada: TooltipDataProcessor/AddTooltipPostCall si existe; HookScript
OnTooltipSetItem en la ruta clásica, más OnTooltipCleared/OnHide para el ciclo de vida. La
extensión sólo edita sus dos líneas nativas, sin ClearLines/SetHyperlink recursivos ni cambios
de texto ajeno. Se excluyen tooltips protegidos y valores restringidos; no hay polling de inventario.
Contrato de comparación nativa: [C_Item.GetItemStatDelta](https://warcraft.wiki.gg/wiki/API_C_Item.GetItemStatDelta).
Los dobles de API comprueban las dos rutas; la cobertura real y el renderizado requieren este
recorrido en Forever. La generalización del inspector visual queda pendiente de esa validación.
