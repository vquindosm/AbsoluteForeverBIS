# Pruebas dentro de WoW Forever

Estas pruebas **no se han ejecutado en este entorno**. El paquete se considera una preview
hasta realizarlas en el build real del usuario. Conserva una copia de los SavedVariables al
probar una migración. Activa los errores Lua desde las opciones del cliente, si están disponibles.

1. Instala la carpeta con su nombre original, inicia sesión y ejecuta `/fwc gear`.
   Deben aparecer título, personaje, filtros, siete pestañas y tres columnas, sin errores.
   En Settings comprueba build/interfaz; `/fwc diag` muestra fallos registrados.
2. Selecciona WARLOCK / Affliction / Pre-BiS. Deben existir las 17 ranuras; desplázate hasta
   Ranged / Relic / Wand. Otras clases siguen mostrando ranuras aunque no tengan catálogo.
3. Pulsa Head. Debe abrir Item Explorer con 10 candidatos. Busca `Crimson`, borra la búsqueda
   y prueba el filtro de fuente. El orden se describe como importado sin clasificación.
4. Selecciona un casco, pulsa Set as Target y comprueba el nombre/ID y la vuelta al personaje.
   El visor estará en Planned. Si el cliente acepta la previsualización, verifica visualmente
   el casco; si la rechaza, debe aparecer un estado de compatibilidad sin romper las listas.
5. Alterna Current / Planned; pulsa Restore actual appearance. Comprueba que el personaje real
   no cambia de equipo. Rota con arrastre o flechas y usa rueda/+/- si el método está disponible.
   Prueba otra raza/sexo, un casco oculto por opciones de apariencia y un arma de mano izquierda.
6. Pasa el ratón por el icono y por Equipped. Comprueba tooltips nativos y comparación numérica
   cuando ambos objetos estén en caché. Una caché vacía debe producir un aviso, nunca cifras falsas.
7. Cambia prioridad, marca adquisición manual y añade una alternativa al planificador sin
   convertirla en objetivo. Comprueba Missing/Completed/High priority/Added manually.
8. Cierra la ventana y ejecuta `/reload`. El objetivo debe mantenerse. Sal y vuelve a entrar
   para comprobar persistencia real en disco. Cambia a Demonology y vuelve a Affliction:
   la selección previa debe regresar. Cambia Pre-BiS/BiS y comprueba aislamiento de objetivos.
9. Si migras v2.1, comprueba selecciones, marcas, rutas e historial. Un nombre sin ID debe
   quedar explicado como selección heredada pendiente. Verifica que `legacyBackup` se conserva.
10. Mueve el casco entre bolsas y equipo; espera el lote de eventos o pulsa Refresh gear.
    Debe distinguir Equipped, In bags, Not found y Unchecked. Una marca manual no debe cambiar
    el estado observado. Prueba dos objetivos iguales de anillo y una sola copia física:
    el planificador no debe contar dos copias. Banco cerrado y alts quedan fuera del cálculo.
11. Entra en combate, mueve un objeto si el cliente lo permite y comprueba que el escaneo se
    difiere hasta salir. El número de `/fwc diag` no debe aumentar por repintar o abrir pestañas.
12. Elige Enchanting en ambos filtros: sólo deben mostrarse sus recetas. Cambia a Tailoring.
    Comprueba cantidades de pilas en bolsas, materiales sin caché y los estados desconocidos.
    En cliente no inglés, los materiales importados sólo por nombre pueden quedar sin comprobar.
13. Registra Mooncloth únicamente tras una fabricación real. Comprueba historial, protección
    frente a clics duplicados durante 60 segundos, etiqueta de estimación y toggle de avisos.
    La estimación heredada no confirma el cooldown real ni bloquea un registro posterior.
14. Abre Talents. Si hay datos legibles, revisa ramas/rangos contra la interfaz oficial, guarda
    un snapshot y selecciónalo. Si no, debe explicar la limitación. No debe gastar puntos.
15. Prueba Daily / Weekly, marca una actividad y vuelve a entrar. Los resets son calendario
    local/lunes local; no se afirman resets oficiales del reino.
16. Redimensiona al mínimo y al máximo permitido, usa una resolución pequeña y escala UI alta.
    Revisa nombres largos, menús, scroll, botones, tooltip y cierre. Mueve la ventana, recarga
    y comprueba posición/tamaño. Reporta cualquier solapamiento: las pruebas de geometría no
    sustituyen al renderizado real de fuentes y modelos.

Para informar de un fallo: build e interfaz de Settings, texto del error Lua, acción que lo
provoca y salida de `/fwc diag`. No hacen falta credenciales ni datos de cuenta.
