# Validación manual de 3.0 en Forever

No se ha ejecutado este recorrido en un cliente real. No confundir los tests con certificación.
Conserva copia de los SavedVariables antes de probar la migración. La carpeta de instalación
sigue siendo ForeverWarlockCompanion; no cargues versiones antiguas simultáneamente.

## Caso completo: Spellweaver's Turban (22267)

1. Actualiza el addon completo, inicia sesión y abre `/fwc`. Revisa título 3.0.0-preview,
   Dashboard, personaje, resumen y sidebar. `/fwc diag` no debe indicar errores de módulo.
2. Usa Filters para WARLOCK / Affliction / Pre-BiS sin cambiar equipo real.
3. Abre Equipment, selecciona Head desde el icono o lista y usa Alternatives.
4. Elige Spellweaver's Turban, verifica tooltip y Set as Target. Revisa Current/Planned/Restore.
5. Track + Steps abre My Objectives. Deben aparecer Upper Blackrock Spire, General Drakkisath
   y Obtain Spellweaver's Turban, sin tasas de drop ni requisitos inventados.
6. Marca manualmente el dungeon y el jefe. El objetivo puede quedar Ready to Acquire, pero
   NO Obtained si el objeto no está disponible ni marcado explícitamente como adquirido.
7. Añade un paso personal y comprueba su marca. Obtención es un paso de evidencia separado.
8. Abre el tracker, expande el objetivo y alterna un paso manual. El cambio debe reflejarse
   en My Objectives. Cambia prioridad y fija Focus; otros objetivos deben seguir disponibles.
9. View source abre Dungeons con el grupo conocido. Pulsa el objeto relacionado para regresar
   a sus pasos. Back debe recuperar sección, contexto y selección anterior.
10. Ejecuta `/reload`, cierra y vuelve a iniciar sesión. Deben conservarse objetivo, modo,
    pasos manuales, foco y posición del tracker. No debe duplicarse el objetivo.
11. Si tienes el objeto o puedes moverlo entre equipo y bolsas, comprueba adquisición observada.
    Una marca manual debe indicar Marked manually; la observada, Observed in equipment/bags.
12. Deja de seguir y vuelve a seguir el mismo objeto: sus pasos anteriores deben recuperarse.

## Migración

- Repite con SavedVariables reales de 2.6: objetivos por nombre/ID, selecciones de todas las
  especializaciones/modos, pesos EP, profesiones, Mooncloth y actividades deben mantenerse.
- Comprueba schema=3, preV3Backup y legacyBackup. Recargar repetidamente no debe duplicar objetivos.
- Una referencia sin itemID importado permanece como Unknown; no se reemplaza silenciosamente.
- Cambia de especialización y modo, vuelve y comprueba objetivos y selecciones independientes.

## Fuente y fabricación

- Sigue un objeto de reputación y asocia facción cuando sea necesario. El rango requerido
  debe aparecer separado del actual. No debe existir una barra a Exaltado basada sólo en
  el umbral de Friendly a Honored. Si el siguiente rango es el requerido, verifica sus números.
- Sigue un objeto fabricado; abre su receta desde el objetivo. Costes desconocidos deben
  permanecer desconocidos. Crafting Planner sólo agrega los requisitos conocidos.
- Con dos recetas de coste conocido y material compartido, verifica demanda sumada y que
  las bolsas no se cuentan dos veces. No debe declararse fabricación posible sólo por materiales.
- Cooldowns conserva el historial manual y avisos sin verificar de Mooncloth.

## Visual, compatibilidad y regresión

- Prueba 880x640, 1180x780 y tamaños mayores en escalas UI distintas. Revisa sidebars con
  scroll, dos/tres columnas de Equipment, filtros plegables, títulos y nombres largos.
- Revisa ambos temas en Settings, menús activos, botones deshabilitados, hovers y vacíos.
- Prueba selector contextual, filtros avanzados, búsqueda de objetos y recetas, Stats y EP,
  talentos/snapshots, tracker y actividades anteriores. No debe perderse funcionalidad.
- En combate: no equipar, fabricar ni gastar talentos; las lecturas de inventario pendientes
  se difieren hasta salir. Inspecciona restricciones y errores del motor real.
- Comprueba que repintar o navegar no aumenta continuamente los escaneos ni parpadea el modelo.
- Reporta build/interfaz, sección y acción exacta, error Lua y `/fwc diag`. Las capturas del
  cliente ayudarán a ajustar el layout; no hay capturas auténticas generadas en este entorno.
