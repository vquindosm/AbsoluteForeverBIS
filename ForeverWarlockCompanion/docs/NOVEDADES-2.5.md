# Comparación del equipo: 2.5.0-preview

Los botones del modelo muestran el inventario real: icono nativo si está disponible y tooltip
SetInventoryItem con fallback a enlace. Un clic selecciona la ranura y abre los detalles y
comparación del objetivo. En la lista izquierda se abre el explorador; Set as Target aplica
la selección al plan y a la vista previa. No equipa objetos reales.

## Pesos EP

WoWSims Forever Warlock define `epReferenceStat: Stat.StatSpellDamage` pero en su configuración
inicial usa `epWeights: new Stats()`, no una tabla universal de pesos de Affliction:
https://github.com/wowsims/forever/blob/master/ui/specs/warlock/dps/spec.ts
Los pesos de una simulación dependen de equipo, talentos, encuentro y configuración. El addon
no incluye pesos inventados ni importa automáticamente una configuración WoWSims.

Settings acepta una lista de claves ITEM_MOD del cliente y pesos numéricos por punto de ESA
clave. Debes convertir previamente las unidades de la simulación a las unidades devueltas por
`C_Item.GetItemStats`: porcentaje, rating y poder de hechizo no son intercambiables. No hay
conversión automática. El texto y los pesos se guardan por perfil de personaje/clase/spec.

EP(objeto)=suma(valor de estadística * peso). El porcentaje de cambio divide la diferencia
entre ambos EP por el valor absoluto del EP equipado. Es una estimación lineal del objeto,
no un porcentaje de DPS, ni una simulación ni garantía de mejor equipo. Procs, efectos de uso,
bonos de conjunto, topes de hit, interacción de slots, armas y encantamientos pueden cambiar el
resultado. No se combinan stats de la fuente web con los stats nativos: se requieren datos del
cliente para ambos enlaces. Se rechaza el cálculo si falta un peso de una clave ITEM_MOD
presente, si la caché no devuelve ambos objetos o si el denominador no es positivo. El usuario
puede indicar peso 0 explícito. No se afirma que esto cubra efectos que GetItemStats no expone.

Verificación: Lua 5.1 y pruebas con APIs simuladas de parsing, campos faltantes, denominador
cero, perfil e interfaz. Pendiente comprobación real en Forever, especialmente claves exactas,
restricciones de valores, enlaces en caché, tooltip de inventario y unidades.
