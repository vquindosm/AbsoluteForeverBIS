# AbsoluteForeverBIS — Forever Companion

Proyecto de addon para **World of Warcraft Forever**, versión actual **3.8.0-preview**.
El código del addon está en [`ForeverWarlockCompanion/`](ForeverWarlockCompanion/).

## Instalación

Descarga el repositorio y copia la carpeta `ForeverWarlockCompanion` completa a
`World of Warcraft/_forever_/Interface/AddOns/`. Conserva ese nombre de carpeta.
Sustituye la versión anterior y ejecuta `/reload`; abre la interfaz con `/fwc`.

## Estado

Incluye Dashboard, Equipment, Stats, profesiones, objetivos, tracker, importador offline
y un piloto de adquisición de Arcanoweave Cloak. Las fichas añaden alternativas visuales,
requisitos publicados para los 157 objetos y 17 mejoras con fórmulas, materiales y orígenes.
El botín incorpora indicadores de mejora. El hover muestra un indicador compacto bajo el nombre,
con puesto BiS publicado, porcentaje de mejora y diferencia GS/EP, sólo ante una mejora calculada.
Se activa por defecto; `/fwc loot off` lo desactiva y `/fwc loot on` lo activa.
Los colores siguen la escala: 1 naranja, 2–3 morado, 4–5 azul y resto verde.
Sin ranking compatible la mejora aparece en verde, sin inventar un puesto BiS.
La comparación nativa por pareja recupera pérdidas que no aparecen como ceros en las tablas
de atributos. Opcionalmente usa la API pública de Forever Leveling BiS para puntuar con su
perfil activo, conservando tus pesos EP cuando los has configurado. Selección en Settings.
La presentación de Fel Cape fue aprobada por el usuario; el nuevo hover sigue pendiente de prueba en WoW.
El inspector 2.0 se activa exclusivamente para Fel Cape (279269): atributos visuales,
comparación común, receta con existencias y costes separados. El rating usa pesos EP
propios válidos; el resto de fichas conserva su presentación durante la validación del piloto.
Los datos incompletos permanecen UNKNOWN y las referencias offline no conceden EP ficticio.
El acceso autenticado y el adaptador del piloto están comprobados. El catálogo masivo y la
validación en el cliente siguen pendientes. Las claves sólo se usan fuera del addon.

Datos del piloto y referencias offline: [Data from ForeverDB.net](https://foreverdb.net).

- [Tooltip e integración con Forever Leveling BiS](ForeverWarlockCompanion/docs/LOOT-TOOLTIP-3.6.md)
- [Indicador BiS compacto 3.8](ForeverWarlockCompanion/docs/UPGRADE-TOOLTIP-3.8.md)
- [Tooltip antes/después](ForeverWarlockCompanion/docs/validation-3.8/tooltip-comparison.png)
- [Inspector 2.0: Fel Cape y prueba en WoW](ForeverWarlockCompanion/docs/ITEM-INSPECTOR-3.7.md)
- [Preview antes/después](ForeverWarlockCompanion/docs/validation-3.7/item-comparison.png)
- [Preview de adquisición y costes](ForeverWarlockCompanion/docs/validation-3.7/acquisition-comparison.png)
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
python3 tools/build_zip.py /tmp/ForeverCompanion-3.8.0-preview.zip
```

No subas archivos `.env`, claves de API, SavedVariables personales ni respuestas privadas de API.
