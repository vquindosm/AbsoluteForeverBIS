# Cambios 2.3.0-preview

- Iconos del equipo real alrededor del modelo, con tooltip nativo y acceso a la ranura.
- `=` identifica la coincidencia exacta con el objetivo actual; `?` indica sin valoración.
  No es una puntuación de rendimiento. La fuente no clasifica los objetos y no existen pesos
  de estadísticas validados para calcular un porcentaje de calidad fiable.
- El modelo conserva una firma del equipo y de los objetivos: repintar la interfaz sin cambios
  ya no ejecuta SetUnit/TryOn; Restore fuerza una nueva carga de la apariencia real. No hay
  bucle de reaplicación en OnModelLoaded. Las peticiones siguen dependiendo del cliente.
- Seguimiento flotante de objetos añadidos manualmente, plegable y desplazable, con prioridades,
  fuente y sugerencia del primer objetivo pendiente. No calcula rutas óptimas.
- `/fwc planner` abre Progression; `/fwc tracker` muestra u oculta el seguimiento.
  Add to Planner cambia a Remove from Planner para permitir retirar un objetivo.

Pruebas: Lua 5.1 y escenarios de APIs simuladas modernos, antiguos y sin modelo, incluidos
repintado sin SetUnit repetido, restauración y visibilidad/plegado del seguimiento.
Pendiente: comprobar visualmente en el cliente real el parpadeo, la restauración, la carga
asíncrona del modelo, iconos, tooltips, escalas y controles del seguimiento.
