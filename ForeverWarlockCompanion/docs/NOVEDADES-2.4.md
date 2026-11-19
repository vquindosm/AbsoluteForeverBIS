# 2.4.0-preview

Rediseño basado en las capturas aportadas: seguimiento inspirado en objetivos del juego,
con iconos y progreso; listas con iconos y fondo oscuro de tonos cálidos. Los botones
secundarios se despliegan con More options. No se incluyen imágenes externas de mazmorras
ni se copian assets de otros addons.

El progreso usa C_Reputation de la documentación exportada para Forever 16001. La barra
indica progreso dentro del rango actual y hasta el siguiente; el rango requerido figura
aparte y procede de la fuente importada sin clasificación. Solo fuentes de reputación
con requisito Honored/Revered/Exalted admiten esta lectura. Selección manual de facción
por objetivo: More options > Choose faction. Si no hay asociación fiable, valores accesibles
o la facción no figura en la lista del cliente, el seguimiento indica Progress unavailable.
No se alteran reputaciones ni se modifica la facción seguida por WoW.

Probado con Lua 5.1 y APIs simuladas; verificar en cliente real el diseño, escalado,
tooltips, progreso y selección de facciones en el idioma del usuario.
