# Fuentes de datos — revisión 19-11-2026

Alcance de esta entrega: auditoría, importador offline y un objetivo de vendedor. No se
certifica una base completa ni se importan las doce profesiones antes de validar ese objetivo.

| Fuente | Acceso / formato comprobado | Cobertura y actualización | Licencia / reutilización en esta entrega |
|---|---|---|---|
| [ForeverDB developers](https://foreverdb.net/developers) | API con clave aprobada; las 11 rutas probadas sin clave devolvieron 401. Documenta JSON `data`/`meta` y paginación. La forma de una respuesta autenticada aún no se ha comprobado. | Build en metadatos; separa cliente, observaciones Forever y legado Classic. | Permite empaquetar datos; exige crédito visible, no revender, respetar límites y no distribuir claves. Se implementa transporte con clave por variable de entorno y cuarentena fuera del addon. |
| [ForeverDB Arcanoweave](https://foreverdb.net/item/272411), [moneda](https://foreverdb.net/item/226404), [Felcloth](https://foreverdb.net/item/18407), [Dreamweave](https://foreverdb.net/item/10019) | HTML público 200 con datos semánticos extraíbles; sólo cuatro registros factuales, con hash de cada página. | Las páginas indican build 1.60.1.70959, extracción 18-11-2026. Fuente publicada, no inspección local del cliente. | Transcripción mínima de hechos y atribución/enlace; no se copian guías, artículos, código, imágenes ni bases completas. Es la única fuente de registros nuevos distribuida aquí. |
| [gBlaku/wow-forever-kb](https://github.com/gBlaku/wow-forever-kb) | Meta JSON público 200; ofrece JSON/CSV/SQLite sin clave. IDs de item/quest/NPC/spell permiten cruces. | Meta: build 70959, generado 18-11-2026; workflow diario. Mezcla cliente, Questie Forever y vmangos Classic; `estimated` no es verificación Forever. | No se encontró LICENSE general. Declara Questie GPLv3 y vmangos GPLv2 para partes de la procedencia. No se redistribuyen sus archivos/código ni se atribuye una licencia única al conjunto. |
| [ForeverTome professions](https://forevertome.com/professions) / [términos](https://forevertome.com/terms) | HTML público; no API/exportación oficial verificada en esta revisión. Identificadores de recetas/materiales visibles. | Página: 2.561 recetas, 15 categorías, build 70707. No coincide con asumir doce categorías completas/actuales. | Términos permiten lectura, enlaces y citas razonables con crédito; no implican permiso para clonar la base o guías. Sin importación masiva ni copia de contenido. |
| [Legacy professions](https://legacyofwarcraft.com/db/forever/professions/index.html) / [términos](https://legacyofwarcraft.com/terms.html) | HTML público con recetas/materiales. No exportación estructurada o licencia de base confirmada. | 2.499 recetas en 12 profesiones. Advierte que precios/habilidad de entrenadores pueden proceder de Classic 1.12, aunque materiales sean del cliente Forever. | No convertir esos campos en Forever verificados. Se usa como referencia de cobertura; no se copia el catálogo. |
| [WoWSims Forever](https://www.wowsims.com/forever/) / [repositorio](https://github.com/wowsims/forever) / [MIT](https://github.com/wowsims/forever/blob/master/LICENSE) | Página principal sin texto útil en la herramienta; código público inspeccionado. | Nueve carpetas de clase. Warlock DPS contiene presets Demo Fire/Shadow Brand, Destro, SM/Ruin y Aff Wrack. Los perfiles dependen de build, APL, equipo, buffs y objetivo. | MIT permite reutilizar código con aviso/licencia. No se copia su motor ni pesos. En `ui/specs/warlock/dps/spec.ts` los pesos predeterminados son vacíos; usa SpellDamage como referencia EP. No hay una tabla oficial universal que importar. |
| [XNWLK/WarlockSIM](https://github.com/XNWLK/WarlockSIM) | JS público inspeccionado en engine y app; última actividad consultada 18-11-2026. | Warlock nivel 60 vs jefe 63, builds/razas/buffs/combate configurables. Calcula derivadas finitas `(DPS modificado − DPS base) / incremento`, con semillas relacionadas y normalización de presentación a spell power. Unidades como porcentaje y puntos son distintas. | No se encontró LICENSE en el árbol consultado; código visible no equivale a permiso para copiar. Sólo se documenta el método; no se copia código, tablas ni resultados. Los pesos dependen de la configuración completa. |
| [WoW Forever Info builder](https://wowforeverinfo.com/character-builder/) / [términos](https://wowforeverinfo.com/terms/) | Constructor HTML/JS y exportación a WoWSims. | Explica simulación WoWSims: 500 iteraciones, 3 minutos, jefe 63, presets del spec; excluye objetos sin soporte e indica limitaciones del panel de talentos/buffs. No es una fuente de pesos estáticos verificados. | Términos permiten enlaces/citas breves/builds; prohíben copias sustanciales y scraping masivo. No se importa su herramienta o contenido. |

## API principal: acceso y actualización

La clave debe configurarse como `FOREVERDB_API_KEY` fuera del addon. No estaba disponible
en el proceso al realizar esta entrega; no se intentó acceder con credenciales de otra cuenta.
La aprobación de acceso indicada por el usuario no sustituye la presencia de la variable.

Endpoints investigados: items/lista/detalle, vendors/lista/detalle, quests/lista/detalle,
professions/lista/slug, dungeons, merchants-favor y classes/name. Evidencia HTTP propia en
`DATA_ENDPOINT_AUDIT.json`; 401 sólo prueba el bloqueo de autenticación, no la existencia del ID.

La documentación indica límites gratuitos de 5.000/día y 30/minuto; plan de pago 10.000/día
y 60/minuto, con límites compartidos entre claves. El transporte no hace reintentos automáticos,
no sigue redirecciones ni recorre páginas en masa; ante 429/402 se detiene.

## Qué se importa, y qué no

`Catalog/public-vendor-slice.json` registra la capa de datos nueva. No sustituye los 157
objetos ni las 28 recetas anteriores. Cada atributo conserva fuente, build, fecha, evidencia
y confianza; la importación no cambia automáticamente datos heredados a verificados.

Arcanoweave Cloak: se publica una oferta de Pix Xizzix por 75 Tarnished Undermine Real,
con nivel requerido 60. El precio de venta de la capa no es su precio de compra. Oro adicional,
reputación requerida, quests, stock, coordenadas y NPC ID no se deducen de lo no publicado
en el registro usado. El ID de NPC sólo se registra al observar su GUID en el cliente.
Una afiliación de vendedor no constituye restricción de facción ni requisito de reputación.

No se han importado cuatro ejemplos completos ni recetas masivas: ese paso permanece
bloqueado por el gate de un vendedor comprobado dentro del cliente. Las simulaciones de
jugador en tests están diferenciadas de los registros de fuentes reales.
