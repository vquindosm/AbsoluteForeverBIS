# AbsoluteForeverBIS — Forever Companion

Proyecto de addon para **World of Warcraft Forever**, versión actual **3.5.0-preview**.
El código del addon está en [`ForeverWarlockCompanion/`](ForeverWarlockCompanion/).

## Instalación

Descarga el repositorio y copia la carpeta `ForeverWarlockCompanion` completa a
`World of Warcraft/_forever_/Interface/AddOns/`. Conserva ese nombre de carpeta.
Sustituye la versión anterior y ejecuta `/reload`; abre la interfaz con `/fwc`.

## Estado

Incluye Dashboard, Equipment, Stats, profesiones, objetivos, tracker, importador offline
y un piloto de adquisición de Arcanoweave Cloak. Las fichas añaden alternativas visuales,
requisitos publicados para los 157 objetos y 17 mejoras con fórmulas, materiales y orígenes.
El botín incorpora indicadores de mejora y comparación por atributo al pasar el ratón.
Se activa por defecto; `/fwc loot off` lo desactiva y `/fwc loot on` lo activa.
La validación dentro de WoW sigue pendiente.
Los datos incompletos permanecen UNKNOWN y las referencias offline no conceden EP ficticio.
El acceso autenticado y el adaptador del piloto están comprobados. El catálogo masivo y la
validación en el cliente siguen pendientes. Las claves sólo se usan fuera del addon.

Datos del piloto y referencias offline: [Data from ForeverDB.net](https://foreverdb.net).

- [Indicadores y comparación del botín](ForeverWarlockCompanion/docs/LOOT-INDICATOR-3.5.md)
- [Fichas, mejoras y requisitos de 3.4](ForeverWarlockCompanion/docs/ITEM-GUIDE-3.4.md)
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
python3 tools/build_zip.py /tmp/ForeverCompanion-3.5.0-preview.zip
```

No subas archivos `.env`, claves de API, SavedVariables personales ni respuestas privadas de API.
