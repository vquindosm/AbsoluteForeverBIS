# Prueba verificable de vendedor — 3.3.3-preview

Caso real publicado: [Arcanoweave Cloak 272411](https://foreverdb.net/item/272411), Pix Xizzix,
75 Tarnished Undermine Real, currency 3469, requiere nivel 60.
Data from [ForeverDB.net](https://foreverdb.net). API: vendors/227853, build 1.60.1.70959.
Son datos publicados por la fuente sobre Forever, no una observación de nuestro cliente.
El JSON conserva sus hashes/build/fechas. No contiene los cuatro casos completos ni una base masiva.

## Automatizado

Instalar dependencias de tools/data/requirements.txt. Desde la carpeta del addon:

```sh
python3 -m unittest discover -s tests -p data_foundation.py
lua tests/authenticated_foundation.lua modern
lua tests/authenticated_foundation.lua legacy
lua tests/authenticated_foundation.lua no-model
lua tests/authenticated_foundation.lua player-model
```

El fixture público histórico sigue cubierto por foundation.lua. Ejecutar también run.lua, v3.lua, visual_layout.lua y phase1_stats.lua con las mismas variantes.
El test del importador usa el JSON real conservado y reconstruye Lua/SQLite sin red. Las
respuestas de jugador/mercader y los grafos alternativos adversos son controles de prueba,
no registros reales añadidos al catálogo. No certifican lectura, posición o precios dentro del cliente.

## Dentro de WoW — pendiente

1. Guardar copia de SavedVariables, instalar toda la carpeta y ejecutar /reload.
   Abrir Settings > Track vendor: Arcanoweave Cloak. Debe mostrarse el precio publicado en moneda,
   mostrar 0 cobre publicado y reputación desconocida, y enlazar a ForeverDB.net. Comprobar que el layout no se ha rediseñado.
2. Revisar currency 3469 con C_CurrencyInfo (no item 226404 en bolsas) y el siguiente paso. Si hay 40 monedas, debe mostrar
   40/75. Sin acceso a una lectura válida debe mostrar Unknown, nunca un cero de relleno.
3. Abrir My Objectives e Item Details; los pasos y la fuente deben coincidir. Los requisitos
   no publicados forman un aviso UNKNOWN, no una lista de quests fabricadas. La afiliación
   Horde publicada para el vendedor no se transforma en una restricción ni reputación requerida.
4. Acudir al vendedor real, abrir su ventana y después el addon. Settings > Inspect open vendor
   solicita otra lectura. Si las APIs lo permiten, se registra GUID/NPC ID, enlace del objetivo,
   precio efectivo en cobre, costes y stock. No se compra ni gasta desde el addon.
   El ID 227853 publicado permite asociar un nombre localizado mediante GUID. Un NPC con otro
   ID no debe sustituir el coste de esta oferta. Link observed NPC sigue disponible para
   fuentes sin ID publicado; una asociación manual no verifica la base externa.
5. Comparar lo observado con el vendedor. Un cero explícito de precio se distingue de oro
   desconocido. -1 en stock sólo se traduce a ilimitado por el significado de esa respuesta API.
   Si la API anuncia coste extendido pero no devuelve sus filas, no se debe mostrar gratis.
6. Si cambia el coste actual, comprobar que sustituye el publicado para el plan del vendedor
   abierto. Stock cero bloquea el avance. Al cerrar la ventana el precio/stock guardado se
   conserva como evidencia histórica, no como estado o descuento actual del personaje.
7. No confundir poder comprar ahora con conocer todas las condiciones universales. Reputación,
   quests y otros campos siguen UNKNOWN hasta que una fuente fiable los confirme. No inferirlos
   de isPurchasable, una visita o la posesión del objeto. Ese flag sólo se conserva como evidencia.
8. Comprar manualmente si se desea; al entrar 272411 en bolsas/equipo el objetivo debe pasar
   a Obtained. Eso no certifica datos de precio/reputación que todavía estén sin publicar.
9. Añadir notas propias, comprobar dependencias y /reload. Se conservan método, notas, progreso,
   plan anterior y observaciones; el mercader cerrado no se trata como abierto tras recargar.
10. Para stats, comprobar Felcloth Gloves 18407 y Dreamweave Gloves 10019 con diagnósticos.
    La referencia offline sólo se aplica a igual build y variante base. * significa referencia
    publicada parcial, no valor confirmado por nuestro cliente. Nunca concede EP ni delta de mejora.
    Un valor explícito del cliente, incluido 0, prevalece sobre esa referencia.

## Evidencia para cerrar el gate

Registrar build/interface, vendedor/GUID, coste y stock observados, lectura de la moneda,
fuente de requisitos extra cuando existan, transición antes/después de adquirir, persistencia
tras /reload y ausencia de errores Lua. Contrastar los registros con el cliente del usuario.

Hasta completar esa prueba no declarar validado el objetivo en juego ni ampliar a catálogo
masivo, los otros tres ejemplos o pesos/simulación nuevos. Las APIs pueden no estar disponibles;
el resultado entonces debe ser UNKNOWN y quedar documentado, no reemplazado por un supuesto.
