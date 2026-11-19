# Prueba de Fase 1 en WoW Forever — pendiente

No declarar validadas las estadísticas reales basándose en las suites de mocks.
Esta entrega 3.3.1 conserva el layout y se detiene antes de rating global / fases 2–6.

1. Conserva copia de SavedVariables; instala toda la carpeta ForeverWarlockCompanion.
   Abre `/fwc settings`. Comprueba la versión/build/interface y presencia de APIs en el informe.
2. Activa **Item stat diagnostics** y pulsa **Inspect Felcloth Gloves**. Espera a la carga.
   El apartado Inspected item y los logs deben reflejar el resultado final; si hay error,
   usa `/fwc refresh` y repite la inspección. Anota Data pending/Read error sin tratarlos como cero.
3. Abre `/fwc stats`, selecciona Hands y Felcloth Gloves. Revisa el nombre del equipado y
   del candidato y abre sus tooltips nativos. Compara los atributos que el cliente exponga.
   Intellect sólo puede ser 0 si la respuesta contiene un 0; un atributo que no figura debe
   decir Not present. Shadow damage debe aparecer si la API devuelve una clave equivalente;
   si falta, comprueba el log crudo. No debe rellenarse con el 33 de la guía importada.
4. Con un equipado encantado o con sufijo, comprueba en el diagnóstico que `input` y `link`
   conservan sus campos completos aunque `GetItemInfo link` sea distinto. El candidato debe
   utilizar su propio enlace. GetItemStats puede no exponer los efectos del encantamiento;
   preservar el enlace no certifica cobertura de todas las modificaciones.
5. Cambia de candidato y de pantalla. La ficha, Stats y la comparación deben coincidir.
   Un dato pendiente/error nunca debe producir mejora positiva/negativa ni un EP ficticio.
   Los deltas sólo aparecen con valores explícitos comparables; Not present no se resta como 0.
6. Pulsa Guardar pesos / Usar como objetivo / Actualizar datos y comprueba el mensaje de la
   acción en Stats. No introduzcas pesos nuevos para ocultar un problema de lectura.
   Usa /reload: la elección debe permanecer; los atributos deben leerse otra vez del cliente.
7. Prueba un equipado que no esté en el catálogo y cuya información se cargue después.
   Sus eventos también deben refrescar el diagnóstico. No cambiar el equipo real desde el addon.
8. Desactiva diagnósticos. El log no debe crecer; Clear log permite borrarlo. /fwc diag imprime
   capacidades y trazas. Tras /reload o logout, el registro está en `itemStatDiagnostics` de
   ForeverWarlockCompanionDB, en el SavedVariables por personaje del addon.

Evidencia para cerrar esta fase:
- build/interface y funciones disponibles;
- enlace del equipado y candidato usados;
- tabla cruda de Felcloth Gloves y tooltip del mismo objeto;
- ejemplos de cero explícito, atributo no expuesto y carga pendiente/error cuando se produzcan;
- coincidencia entre Stats, Equipment e Item Details; persistencia tras /reload; ausencia de errores Lua.

Si el tooltip muestra algo que GetItemStats no expone, debe quedar como falta de cobertura,
no como cero. Revisar una fuente verificable o un adaptador específico antes de incluirlo en EP.
Hasta cerrar esta comprobación, rating global, nuevos perfiles EP y árboles visuales siguen pendientes.
