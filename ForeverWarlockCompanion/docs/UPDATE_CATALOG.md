# Actualizar el catálogo

Herramientas fuera del juego; nunca añadir claves a Lua, JSON de catálogo, comandos compartidos o ZIP.

1. Instalar dependencias de compilación: `python3 -m pip install -r tools/data/requirements.txt`.
2. Revisar términos, build, IDs y alcance. No activar importación masiva antes de validar el vendedor.
3. Para refrescar los cuatro registros públicos concretos:

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

**No hay todavía un mapping autenticado certificado.** La forma real de las respuestas sólo
se conoce después de obtenerlas: revisar campos como seenInForever, precio por compra/stack,
costes, reputación de descuento frente a requisito, disponibilidad y marcas de legado.
La cuarentena no se compila directamente. Convertir mediante un adaptador revisado al esquema
normalizado, conservando evidencia y marcas de la fuente, y añadir fixtures de esos registros.
No eliminar sus marcas de atribución ni declarar una API probada sólo por su documentación.

tools/build_zip.py recompila la instantánea local revisada antes de generar el ZIP, sin red.
Compilar valida JSON Schema y referencias; los productos deben ser reproducibles desde la misma
entrada. Ejecutar las suites de tests y el recorrido manual del vendedor antes de empaquetar.
`tools/build_zip.py` incluye la carpeta del addon; mantener cuarentena, .env y exports privados fuera.
La base SQLite es un producto de compilación/consulta, no una dependencia del cliente.

Cobertura actual: `docs/DATA_COVERAGE.json`. Mientras recipes/quests estén sin importar, no
anunciar catálogo completo ni generar cadenas, precios, reputaciones o pesos de relleno.
