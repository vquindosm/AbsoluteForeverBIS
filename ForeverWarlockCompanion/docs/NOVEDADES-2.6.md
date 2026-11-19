# Corrección 2.6: sección de estadísticas visible

La versión 2.5 sólo tenía un campo de texto de pesos avanzados en Settings. No existía una
sección propia para editar los pesos por nombres y consultar los valores de ambos objetos.
Esta entrega añade la pestaña Stats y `/fwc stats`, con selectores de ranura y candidato.
El botón Equipped de los detalles abre esta sección con la ranura y candidato seleccionados.

La tabla compara estadísticas de los objetos, no los totales del personaje. Columnas:
estadística, equipado, candidato, diferencia y peso EP. Incluye nombres legibles para los
atributos habituales y añade las claves adicionales reales del cliente. Las variantes de
crit/hit que el cliente expone con claves distintas se conservan por separado, sin convertir
unidades de forma implícita. Spell pierce sólo tendrá valor si la API expone su clave.

Las diferencias se muestran sin configurar pesos. Guardar pesos permite calcular el EP en
esta tabla y en las comparaciones existentes. Los valores no se rellenan con recomendaciones
inventadas. Campos vacíos dejan el peso sin configurar; 0 lo ignora explícitamente. Se conserva
el modelo lineal y sus límites documentados en NOVEDADES-2.5.md (no es DPS ni un sim).

Una tabla vacía de GetItemStats ahora se considera desconocida. Una tabla no vacía permite
mostrar 0 para las claves ausentes, con la advertencia de que ausencia de clave no garantiza
que el cliente exponga todos los efectos o estadísticas. Ni fuente web ni tooltip se convierten
a rating/porcentajes por suposición.

Pruebas con Lua 5.1 y dobles de API: pestaña accesible por comando, filas y valores visibles,
guardado por campos, actualización EP y rechazo de entrada inválida sin sobrescribir pesos.
También pasan los escenarios sin modelo y de APIs alternativas. No se ha ejecutado WoW
Forever: deben verificarse en el cliente los datos devueltos, claves, unidades y presentación.

Comprobación inicial: `/fwc stats`, elegir WARLOCK/Affliction/Pre-BiS y Head. Deben verse los
nombres de equipado y candidato. Revisar valores frente a los tooltips, cambiar candidato,
introducir pesos conocidos y guardar. Si aparece ?, comprobar caché con Actualizar datos.
Una captura de esta pestaña y el build ayudarían si los valores continúan sin aparecer.
