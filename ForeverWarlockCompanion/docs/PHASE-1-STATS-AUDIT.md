# Fase 1 — auditoría previa (base 3.3.0-preview)

Se implementa únicamente la obtención individual de estadísticas. La activación de un rating
global, los perfiles EP nuevos y los árboles visuales quedan detrás de la validación en el cliente.
El Dashboard y el layout general se conservan.

Hallazgos reproducibles en código:
- StatsPanel reemplaza claves ausentes por cero mediante `stats[key] or 0` y calcula deltas con
  ese mismo supuesto. Un dato no expuesto se presenta como un cero confirmado.
- ItemDetails utiliza `sourceStats` importados, mientras Stats y EP consultan sólo GetItemStats.
  Felcloth Gloves (18407) tiene Armor 55 / Stamina 9 / Shadow damage 33 en la importación,
  pero esos datos están marcados imported_unranked, no verificados contra el cliente actual.
- Shadow damage no figura en la tabla principal de Stats; varias rutas también discrepan en
  el orden de las palabras de HIT_SPELL_RATING / SPELL_HIT_RATING (y crit).
- Los errores de lectura se ocultan en Compat.Call; una tabla vacía, nil y un error se reducen
  a la misma ausencia de datos. Un atributo ausente no debe demostrar valor cero.
- Compat.ItemInfo sustituye el enlace solicitado por el devuelto por GetItemInfo. No garantiza
  conservar encantamientos/sufijos de una instancia equipada.
- La solicitud asíncrona se limita a IDs sin nombre, con una marca requested que no se reinicia.
  No hay continuación Item ni invalidación de estadísticas por enlace completo.
- Los eventos de datos sólo actualizan IDs presentes en catálogo/bolsas; un equipado ajeno
  al catálogo puede quedarse fuera del refresco.

No se afirma que la API real devuelva un resultado concreto para Felcloth Gloves: faltan
el enlace y la salida del cliente del usuario. Se reproducirán esas ramas mediante fixtures,
y la entrega incluirá el diagnóstico necesario para contrastar el fallo observado en juego.

Fuentes revisadas el 19-11-2026:
- Exportación ya disponible: docs/api-functions.json, de Atraeau/WoW-Addons, build 70790,
  interfaz 16001. GetItemStats recibe un itemLink. Es evidencia documental, no ejecución.
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectAPI/Mainline/Item.lua
  Define CreateFromItemLink/ID, GetItemLink y ContinueOnItemLoad. Se comprobarán en runtime.
- https://wowforevertalents.com/about/ se examinó como referencia para fases posteriores.
  Declara datos del build 70938 y también cambios anunciados con colocación aproximada.
  No se importan árboles ni se equiparan automáticamente con datos verificados del cliente.

## Corrección implementada: 3.3.1-preview

`Services/ItemStats.lua` centraliza identidad, enlace usado, API/procedencia, atributos crudos,
normalización y estado por atributo. Sus consumidores son Stats, Equipment, Item Details,
el tooltip de ranura y el EP individual ya existente. No hay rating agregado nuevo.

- `confirmed`: valor numérico explícito; `zero`: cero explícito en el atributo.
- `absent` / Not present: el atributo no figura en la respuesta disponible. No prueba cero.
- `pending` / Data pending: identidad/enlace/datos no cargados.
- `error` / Read error: excepción, valor restringido, dato inválido, conflicto o carga fallida.
- `unknown` / Unknown: API o identidad no disponible.
- Una respuesta vacía con identidad cargada se distingue como `empty`; no se puntúa.
  Una respuesta parcial con errores conserva los atributos legibles y bloquea EP.

Los deltas requieren números explícitos en ambas respuestas. El EP anterior se restringe
cuando hay estados no válidos, claves ausentes, pesos contradictorios o valores no finitos.
Hit de hechizo (rating), Hit genérico, porcentajes, daño de escuela, daño ofensivo y spell power
no se fusionan. Sólo se normalizan nombres que representan la misma cantidad y unidad.
Los pesos existentes se interpretan con esos alias sin inventar ni activar valores nuevos.

El enlace completo suministrado se mantiene incluso si GetItemInfo devuelve uno base. El
candidato obtiene su propio enlace; el equipado sin enlace de instancia no toma stats del ID
base. La caché diferencia intención y enlace (incluidos sufijos/modificaciones), se invalida
por eventos y detecta cambios de inventario. No se persisten tablas de atributos para otra sesión.

Se comprueban funciones/métodos en ejecución. Se usa Item:ContinueOnItemLoad cuando existe,
y RequestLoadItemDataByID cuando está disponible como alternativa. Item:GetItemLink también
puede resolver el candidato. Las peticiones se agrupan por ID y se acotan; una carga fallida
no entra en un bucle automático. Refresh data o /fwc refresh reinicia un intento de forma
explícita. Los eventos de equipados ajenos al catálogo también invalidan sus respuestas.

El catálogo actual no tiene atributos verificados para fallback. Sus números importados se
mantienen sólo como guía sin verificar en Advanced, sin completar lecturas silenciosamente.
El adaptador acepta un bloque futuro `verifiedStats={variant='base',build='...',source='...',
values={...}}` únicamente para la variante base y el build coincidente; no cubre modificaciones
ni sustituye una lectura cliente válida. Esa rama se prueba con un fixture, no se añade una
certificación ficticia a ningún objeto real.

Settings activa/desactiva logs específicos, inspecciona 18407 y permite limpiar el registro.
Guarda hasta 80 mensajes deduplicados en SavedVariables: build, API, entrada, enlace usado,
enlace devuelto por GetItemInfo, cargador, atributos crudos, errores y procedencia. /fwc diag
imprime ese informe. No se envía a ningún servicio externo desde el addon.

## Límites y gate

Los fixtures prueban las correcciones del código, no las respuestas reales del cliente.
GetItemStats no garantiza exponer todos los encantamientos, gemas, efectos de uso/proc o sets.
No se analizan números de tooltips localizados ni se convierten unidades por suposición.
La causa concreta de que el cliente del usuario omita un atributo sólo podrá cerrarse con
su respuesta cruda y tooltip. El recorrido de validación está en PHASE-1-CLIENT-TEST.md.
