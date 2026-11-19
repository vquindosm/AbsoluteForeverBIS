# Pendiente y límites 3.0

- No se ha ejecutado el addon en un cliente real de Forever. No hay capturas auténticas
  de esta versión, ni certificación de fuentes, modelos, tooltips, restricciones de combate
  o lectura de datos del build del usuario. Las comprobaciones de geometría son dobles.
- Fuentes basadas en los metadatos importados: cobertura parcial de jefes, objetos y zonas.
  Dungeons muestra objetivos personales agrupados; no es un journal de loot completo.
  No hay NPCs, coordenadas, tasas de drop, prerrequisitos ni cadenas de misiones inventados.
- Sólo se generaron pasos a partir de fuentes/costes existentes. Misiones, bosses, aprendizaje
  de recetas, compras y fabricación siguen siendo manuales; no hay nuevas APIs de detección.
- El cliente sólo documenta el umbral de reputación actual/siguiente. No se deduce un total
  hasta Exaltado si faltan umbrales. En ese caso se muestra el rango actual y el requerido,
  sin una barra de cantidad que afirme un progreso no verificado.
- No se declara fabricable por tener materiales. Aprendizaje y cooldowns reales continúan
  sin detectar; costes de muchas recetas de sastrería faltan. Mooncloth es registro manual
  y su coste/cooldown heredado sigue sin verificar. El planificador agrega costes conocidos.
- Los objetivos desconocidos y referencias legacy se retienen. Los estados de adquisición
  manuales y observados se identifican. Las coincidencias de materiales sólo por nombre
  tienen las limitaciones de idioma/caché documentadas por InventoryScanner.
- Dependencias entre pasos y rechazo de ciclos implementados; editor gráfico de árboles,
  dependencias arbitrarias entre objetivos, mapas/rutas y calendario de raids pendientes.
- Character Progress reutiliza el Dashboard. Cooldowns y overview de profesiones reúnen datos
  disponibles, no un catálogo completo de todas las profesiones. Búsqueda e inspección de
  recetas aprendidas desde el libro real siguen pendientes.
- Talents conserva lectura/snapshots cuando el cliente lo permite; no es un editor de puntos.
- EP conserva el modelo lineal de objetos. No se convierte en DPS ni clasificación de BiS.
  No se añaden pesos de estadísticas predeterminados no verificados.
- Otros catálogos y builds siguen pendientes; las 29 variantes son seleccionables sin datos
  inventados. Actividades diarias/semanales son checklists locales, no resets del reino.
