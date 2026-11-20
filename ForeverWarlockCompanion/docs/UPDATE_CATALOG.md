# Actualizar el catálogo

Herramientas fuera del juego; nunca añadir claves a Lua, JSON de catálogo, comandos compartidos o ZIP.

1. Instalar dependencias de compilación: `python3 -m pip install -r tools/data/requirements.txt`.
2. Revisar términos, build, IDs y alcance. No activar importación masiva antes de validar el vendedor.
3. Para reproducir la instantánea pública histórica (no es la entrada del build actual):

```sh
python3 tools/import_foundation.py public-slice
python3 tools/import_foundation.py compile Catalog/public-vendor-slice.json --sqlite Catalog/foundation.sqlite
```

El adaptador se detiene si cambia el formato/nombre/build. No copia páginas completas en el addon.
La procedencia registra un hash de lo consultado y la fecha de importación. Revisar el diff del JSON:
una actualización del sitio no se acepta automáticamente como una corrección verificable del juego.

Para acceder a ForeverDB autenticado, configurar la variable FOREVERDB_API_KEY mediante un
mecanismo privado del entorno. No pegar el valor en el chat ni guardarlo en este directorio.
Con la variable disponible, obtener exclusivamente registros puntuales:

```sh
python3 tools/import_foundation.py fetch-api items/272411 --out-dir /tmp/fwc-api-quarantine
python3 tools/import_foundation.py fetch-api vendors/227853 --out-dir /tmp/fwc-api-quarantine
```

No se incluyen claves de ejemplo funcionales. El transporte sólo acepta HTTPS al host revisado,
usa User-Agent de la aplicación, no sigue redirecciones, no imprime respuestas de error ni claves,
respeta la interrupción por límites y mantiene las respuestas fuera del directorio distribuible.
Un error 401 requiere clave/aprobación; 403 puede requerir revisar el acceso/User-Agent; 402/429,
revisar cuota y Retry-After. No repetir solicitudes automáticamente.

El adaptador autenticado de 3.3.3 consume cinco respuestas individuales revisadas:
`items/272411`, `items/226404`, `items/18407`, `items/10019`, `vendors/227853`.
Espaciar consultas al menos 2,1 segundos para respetar 30/min; detenerse ante 402/429 y
respetar Retry-After. No recorrer el catálogo. El adaptador no hace solicitudes de red.

```sh
python3 tools/import_foundation.py api-slice --input-dir /tmp/fwc-api-quarantine
python3 tools/import_foundation.py compile Catalog/api-vendor-slice.json --sqlite Catalog/foundation.sqlite
```

`--imported-at` permite reproducir la fecha de una importación auditada. El adaptador valida
identidades, procedencia Forever, envelope, build coherente, tipos de costes y stack 1.
Cambios no revisados (por ejemplo eventos históricos, diferencias liveClient o stack distinto)
requieren revisar el mapping. El ID 3469 procede de costs[type=currency], no de buscar un
item con el mismo nombre. `price` es cobre por compra; `sellPrice` no se usa. reputationFaction
es descuento, no un requisito. Lo no publicado permanece UNKNOWN.
La cuarentena completa no se empaqueta; se normalizan exclusivamente los hechos del piloto.
Se conservan texto de atribución, cadenas sin quitar marcas y hash del original. meta.client
es específico de la cuenta y no se publica. No añadir claves o respuestas completas al repositorio.
Cada panel que muestre datos debe conservar el crédito y enlace visible a https://foreverdb.net.

tools/build_zip.py recompila Catalog/api-vendor-slice.json, la instantánea local revisada antes de generar el ZIP, sin red.
Compilar valida JSON Schema y referencias; los productos deben ser reproducibles desde la misma
entrada. Ejecutar las suites de tests y el recorrido manual del vendedor antes de empaquetar.
`tools/build_zip.py` incluye la carpeta del addon; mantener cuarentena, .env y exports privados fuera.
La base SQLite es un producto de compilación/consulta, no una dependencia del cliente.

Cobertura actual: `docs/DATA_COVERAGE.json`. Mientras recipes/quests estén sin importar, no
anunciar catálogo completo ni generar cadenas, precios, reputaciones o pesos de relleno.


## Fichas y mejoras: 3.4

La ampliación solicitada usa un adaptador separado. Con FOREVERDB_API_KEY configurada de
forma privada fuera del addon:

```sh
python3 tools/import_item_guide.py fetch --out-dir /tmp/fwc-guide-private
python3 tools/import_item_guide.py normalize --input-dir /tmp/fwc-guide-private --guide-html /tmp/fwc-guide-private/affliction-bis.html
python3 tools/import_item_guide.py compile
```

`fetch` sólo consulta los IDs del catálogo y las rutas de profesiones/spells indicadas en el
adaptador, con pausa de 2,1 s y sin reintentos automáticos. `--only-missing` sirve para reanudar
la misma importación, no para mezclar inadvertidamente builds. Una actualización de cobertura o
paginación de profesiones requiere revisar esos límites; no se ofrece un barrido ilimitado.
La cuarentena retiene bytes originales con permisos privados. No copiarla al repositorio.

`normalize` selecciona campos y recetas pertinentes, preserva marcas/cadenas y atribución y
registra omisiones/coverage parcial. Los datos desconocidos permanecen null; no hay pesos o
precios inventados. `compile` genera Data/ItemGuide.lua y docs/ITEM_GUIDE_COVERAGE.json.
El empaquetador compila ambas entradas revisadas sin red y rechaza claves o archivos privados.
Ver la semántica y prueba manual en ITEM-GUIDE-3.4.md antes de declarar validación en juego.
