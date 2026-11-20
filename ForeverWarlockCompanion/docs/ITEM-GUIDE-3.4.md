# Fichas, mejoras y requisitos — 3.4.0-preview

Data from [ForeverDB.net](https://foreverdb.net). API y condiciones:
https://foreverdb.net/developers. Referencia de composición: captura aportada por el usuario.

## Diferencias estructurales y composición nueva

| Antes (3.3.3) | Ahora (3.4) |
|---|---|
| Estadísticas/origen arriba; comparación y checklist inmediatamente después | Atributos y dos alternativas con icono arriba; franja de mejoras; requisitos y origen; comparación y pasos al final |
| Alternativas dentro de un desplegable al pie | Dos tarjetas pulsables con tooltip y desplegable para el resto |
| Sin sección de mejoras | Opciones por ranura, selección contextual y detalles expandibles con materiales y origen |
| Nivel, vinculación y restricciones sin sección propia | Requisitos de equipar separados de fabricación y de aplicación de mejora |
| Lista del explorador con nombre/origen/propiedad | Tarjetas con atributos publicados, origen, propiedad e índice de guía cuando existe |

El personaje y las ranuras siguen siendo la columna protagonista de Equipment. No se cambia
el Dashboard, el modelo 3D ni las selecciones guardadas. Las notas técnicas permanecen en
More options; se conservan las acciones de objetivo, seguimiento, preview y comparación.

## Datos y límites

- 157 objetos consultados individualmente: todos tienen nivel publicado y cobertura parcial.
- 17 mejoras seleccionadas para Aflicción JcE 60, incluyendo utilidad para capa.
- Recetas/materiales publicados para 29 objetos fabricables del catálogo.
- Ubicaciones, coordenadas y costes de fórmulas donde existen; facciones como alternativas.
- Un origen Classic se etiqueta como pendiente de confirmar en Forever; un origen desconocido
  no se sustituye por una localización supuesta.
- Mystic Rugged Armor Kit exige nivel de objeto 35, distinto del nivel del personaje.
- La habilidad de fabricar y aprender una receta no se convierte en restricción de llevarla.
- recipe.requiredLevel se conserva sin mapear a nivel del elaborador: semántica no confirmada.
- Índices publicados: guía Aflicción JcE 60, todas las fuentes (puede incluir bandas). No alimentan
  el motor EP, no ordenan el catálogo Pre-BiS y no expresan mejora de DPS del personaje.
- No se afirma que las restricciones de reputación, misión, clase/profesión o compra de cada
  objeto estén completas. Las no publicadas siguen indicadas como sin confirmar.

Los datos y sus marcas se preservan en Catalog/item-guide.json, con fuente/build/hash.
Data/ItemGuide.lua e ITEM_GUIDE_COVERAGE.json se compilan sin red; el juego no usa claves ni HTTP.
El catálogo/recetas anteriores y los objetivos existentes no se sustituyen por recomendaciones.

## Validación visual

Comparativas antes/después construidas desde geometría de frames nativos con APIs simuladas:

- [Detalle de objeto](validation-3.4/item-comparison.png)
- [Equipment](validation-3.4/equipment-comparison.png)
- [Item Explorer](validation-3.4/explorer-comparison.png)

Las imágenes lo indican expresamente: no son capturas del cliente. Iconos son marcadores,
fuentes aproximadas y el modelo 3D un marcador. Sirven para revisar la distribución, sin
certificar renderizado del juego, escala de UI, tooltips o lectura real de bolsas.
Los tests comprueban tres tamaños: 880×640, 1180×780 y 1700×1040.

## Recorrido pendiente dentro de WoW

1. Instalar el addon completo y abrir `/fwc gear`. Seleccionar Head y abrir el detalle.
   El personaje mantiene sus ranuras. Head debe mostrar atributos y alternativas visuales.
2. Hover y pulsar una alternativa: tooltip nativo y cambio de ficha, conservando la ranura.
   Set as Target sigue guardando el objetivo y la previsualización planificada.
3. Abrir las mejoras de Head: Presence of Sight y Arcanum of Focus muestran origen sin confirmar,
   sin inventar una cadena de obtención. Cambiar de objeto cierra el detalle anterior.
4. En Neck, abrir Enchant Necklace - Spell Power. Comprobar proveedor para la facción, moneda
   y materiales contra ForeverDB y el cliente. No confundir coste de la fórmula con materiales.
5. Añadir/quitar materiales de bolsas: los contadores deben reflejar el inventario observado;
   una lectura no disponible debe quedar como `?`, no como cero.
6. En Chest/Hands/Legs/Feet, verificar requisito de nivel de objeto 35 del kit; encantamiento y
   kit son opciones permanentes alternativas. No se aplica ni se compra nada automáticamente.
7. Comprobar Robe of the Void: nivel para equipar separado de Tailoring 295/materiales para fabricar.
   Verificar que restricciones no publicadas siguen sin confirmar.
8. Revisar un origen Classic y un registro de build anterior: conservar la advertencia. No tratar
   los índices de guía como mejora frente al equipo actual ni como prueba de disponibilidad.
9. Probar ventana mínima, scroll, cambio de perfil, navegación Back y `/reload`. Confirmar crédito
   visible a ForeverDB.net en cada vista de datos y ausencia de errores Lua.

No declarar esta validación completada a partir de tests o de las comparativas de geometría.
