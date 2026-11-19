# Estado de entrega — 3.3.3-preview

El acceso autenticado a ForeverDB y el adaptador del vendedor piloto ya están comprobados.
Data from [ForeverDB.net](https://foreverdb.net). Documentación: https://foreverdb.net/developers.
Se conserva el gate de un vendedor antes del catálogo masivo y las otras verticales.

| Parte | Implementado / evidencia | Pendiente |
|---|---|---|
| Acceso | Seis respuestas autenticadas HTTP 200: meta, cuatro items y vendors/227853 | Ampliar endpoints sólo dentro del alcance revisado |
| Datos | Catalog/api-vendor-slice.json activo, procedencia/hash/atribución por fuente; Lua y SQLite reproducibles | Verificar en cliente y ampliar adaptadores |
| Vendedor | NPC 227853; coordenadas 28.5/75.8; currency 3469 ×75; 0 cobre publicado por compra | Reputación, quests y otras restricciones no publicadas; stock actual |
| Progreso | C_CurrencyInfo, no item 226404 en bolsas; mismo objetivo/método/notas | Lectura del cliente real |
| Mercader | GUID permite nombres localizados; coste/stock de ventana abierta prevalecen temporalmente | Contrastar APIs/precios con el vendedor dentro de WoW |
| Stats | API del build 1.60.1.70959; Felcloth daño de sombras, Dreamweave poder con hechizos; referencias parciales con fuente visible | Unidades Hit y atributos/modificaciones del cliente real |
| Rating | EP manual anterior conservado; referencias/incompletos no puntúan | Pesos/simulación nuevos y puntuación global |
| Seguridad | Clave usada en sesión privada temporal ya cerrada; no distribuida. meta.client queda fuera del catálogo. ZIP rechaza credenciales | Configurar FOREVERDB_API_KEY fuera del addon para futuras actualizaciones |
| Cobertura | Cuatro items y una oferta; snapshot público anterior preservado como fixture histórico | Recetas nuevas de las doce profesiones y quests: 0 importadas |

Autenticarse no demuestra que todos los campos sean completos o estén verificados localmente.
Afiliación y reputación de descuento no son requisitos de compra. La oferta ilimitada publicada
no garantiza stock actual. UNKNOWN no equivale a ausencia de requisito ni a cero.
La posesión completa el objetivo, sin certificar las restricciones desconocidas de la fuente.
Las observaciones históricas de mercader no se reutilizan como actuales después de cerrarlo.

## Validación local

| Variante simulada | Original | v3 | Layout | Stats fase 1 | Público histórico | API |
|---|---:|---:|---:|---:|---:|---:|
| modern | 134 | 60 | 201 | 64 | 66 | 41 |
| legacy | 130 | 60 | 201 | 64 | 66 | 41 |
| no-model | 132 | 60 | 201 | 64 | 66 | 41 |
| player-model | 133 | 60 | 201 | 64 | 66 | 41 |

2.257 comprobaciones Lua y 24 tests Python pasan; 44 archivos pasan sintaxis Lua 5.1.
Se comprueban saldo real frente a item homónimo, Unknown/0, cambio de fuente en objetivos
persistidos, notas, GUID localizado, costes temporales, atribución en cada panel y referencias
estadísticas sin EP. El adaptador rechaza cambios de formato/build/tipos no revisados.
Los productos se reconstruyen sin red desde el snapshot normalizado y se escanean credenciales.
Los datos originales de objetos/recetas, Dashboard y MainWindow se mantienen sin cambios.

Los registros fuente proceden de la API, pero los estados del jugador y mercader de los tests
son controles simulados. No certifican la ejecución del addon en WoW. Seguir VENDOR_SLICE_TEST.md
para cerrar ese gate. No se declara una base completa, una mejora EP ni una captura de juego.
