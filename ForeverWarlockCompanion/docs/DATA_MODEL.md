# Modelo offline y procedencia

Entrada: JSON con esquema en `Catalog/schema.json` (Draft 2020-12). El compilador valida
estructura, valores finitos, procedencia, identidades, referencias, costes y ausencia de credenciales.
Produce SQLite relacional por entidad, Lua determinista y un informe de cobertura con SHA256.
La validación estructural no verifica por sí sola que un hecho sea cierto en el juego.

Entidades: Item, Vendor, VendorOffer, Recipe, Quest y AcquisitionSource. Las colecciones se
indexan por ID estable. Vendor añade `vendorKey`: permite identificar una fuente por un nombre
estable del registro mientras `npcId` es UNKNOWN, sin inventar un ID numérico. Un GUID leído
posteriormente del vendedor se guarda por separado como observación de cliente.

Un campo usa `{status, value, provenance}`. KNOWN exige valor explícito; UNKNOWN exige null.
LEGACY y APPROXIMATE conservan su clasificación. Listas vacías sólo significan ausencia de
requisitos si la fuente lo confirma. La omisión o null no se convierten en cero ni lista vacía.
En Lua un null puede omitirse, pero la etiqueta UNKNOWN se conserva. false y 0 confirmados
no desaparecen por operadores de fallback.

Cada entrada de procedencia incluye sourceName, sourceURL, sourceBuild, importedAt,
evidenceType, verifiedStatus, redistributionBasis y, en el importador público, hash de página.
Los atributos especifican unidad y clave normalizada; una unidad no identificada no obtiene
una equivalencia de rating. El +10 Hit publicado no se convierte por suposición al +1 de la
guía anterior ni a un porcentaje. Stats/effects/equipRestrictions pueden tener cobertura parcial.

SQLite separa items, vendors, vendorOffers, recipes, quests, acquisitions y provenance.
VendorOffer enlaza vendedor e item con claves foráneas; AcquisitionSource enlaza item/fuente.
Los detalles y su procedencia permanecen en JSON para conservar campos desconocidos sin columnas
engañosas con defaults 0. Un importador nuevo debe declarar sus mappings y política de actualización.

El addon carga únicamente `Data/Foundation.lua`, generado offline. No usa HTTP, SQLite,
Python ni credenciales en WoW. Los datos anteriores se mantienen y no se sobreescriben.
SavedVariables conserva esquema 3; incorpora campos nuevos de método/observación y respaldo
`legacyAcquisitionSteps` / `legacySourceId` cuando un objetivo anterior adopta la nueva fuente.
No se elimina el progreso manual previo; las notas propias siguen disponibles y conservan dependencias.

El resolver compone ALL, ANY, QUANTITY, MANUAL y UNKNOWN. ANY es una elección lógica,
no una lista de pasos que deban completarse todos. Un ALL sin datos no se considera satisfecho.
Los campos normalizados de la oferta añaden sus restricciones explícitas; nunca se genera
reputación por la afiliación del vendedor. Los costes actuales observados en el vendedor
sustituyen, de forma temporal, costes publicados para ese método, no precios base universales.
El coste de compra, oro actual, cantidad de moneda y posesión del objetivo son hechos distintos.

Una asociación manual opcional de NPC se guarda como vendorSourceBindings por personaje.
Permite usar la observación en locales cuyo nombre difiere del registro público; requiere
una elección explícita del usuario con el NPC/GUID mostrado. No transforma npcId UNKNOWN
del catálogo en un ID verificado ni certifica requisitos de compra.


## Adaptador API 3.3.3

Catalog/api-vendor-slice.json es la entrada activa. El JSON público anterior es histórico.
La procedencia API incluye hash de envelope, atribución recibida y documentación revisada;
no incluye meta.client ni credenciales. Se conservan cadenas y marcas de la fuente.
Un coste currency usa currencyId y C_CurrencyInfo, un coste item usa itemId e inventario;
los nombres iguales no permiten intercambiar esas identidades. purchaseStack conserva la
unidad de compra y priceBasis identifica el precio publicado, no un precio base universal.
stockLimit=unlimited_published describe el catálogo, mientras el stock de la ventana abierta
sigue siendo una observación distinta. El adaptador no declara ausencia de restricciones
por campos de descuento/facción ni por el hecho de autenticarse correctamente.
