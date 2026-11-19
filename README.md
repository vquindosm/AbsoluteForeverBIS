# AbsoluteForeverBIS — Forever Companion

Proyecto de addon para **World of Warcraft Forever**, versión actual **3.3.2-preview**.
El código del addon está en [`ForeverWarlockCompanion/`](ForeverWarlockCompanion/).

## Instalación

Descarga el repositorio y copia la carpeta `ForeverWarlockCompanion` completa a
`World of Warcraft/_forever_/Interface/AddOns/`. Conserva ese nombre de carpeta.
Sustituye la versión anterior y ejecuta `/reload`; abre la interfaz con `/fwc`.

## Estado

Incluye Dashboard, Equipment, Stats, profesiones, objetivos, tracker, importador offline
y un piloto de adquisición de Arcanoweave Cloak. La validación dentro de WoW sigue pendiente.
Los datos incompletos permanecen UNKNOWN y las referencias offline no conceden EP ficticio.
El catálogo masivo y el acceso autenticado a ForeverDB están pendientes; no se distribuyen claves.

- [Guía completa](ForeverWarlockCompanion/README.txt)
- [Estado y cobertura](ForeverWarlockCompanion/docs/DATA_FOUNDATION_STATUS.md)
- [Fuentes y condiciones de uso](ForeverWarlockCompanion/docs/DATA_SOURCES.md)
- [Prueba del vendedor en el cliente](ForeverWarlockCompanion/docs/VENDOR_SLICE_TEST.md)
- [Actualización del catálogo](ForeverWarlockCompanion/docs/UPDATE_CATALOG.md)
- [Pruebas locales](ForeverWarlockCompanion/tests/README.md)

## Desarrollo

Las pruebas Lua necesitan Lua 5.1; las herramientas offline usan Python 3 y las dependencias
de `ForeverWarlockCompanion/tools/data/requirements.txt`. Ejecuta las suites desde la carpeta
del addon según `tests/README.md`. El addon no necesita Python, SQLite ni HTTP dentro del juego.

Para generar el ZIP instalable, desde `ForeverWarlockCompanion/`:

```sh
python3 tools/build_zip.py /tmp/ForeverCompanion-3.3.2-preview.zip
```

No subas archivos `.env`, claves de API, SavedVariables personales ni respuestas privadas de API.
