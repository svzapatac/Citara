# Levantamiento de información — Gestión de peluquerías y salones de uñas

12 de noviembre de 2026

## Resumen

El sistema centraliza las reservas y conecta la agenda de cada trabajador con los servicios realizados, la factura, las comisiones, el inventario y los reportes, para que el dueño delegue la operación diaria y consulte resultados por trabajador y sede.

Este documento reúne lo levantado en cuatro entrevistas con dueños de salones, las reglas del enunciado, el estado del arte y lo que sigue sin confirmar. Es la base para el modelo de datos y para el trabajo de los desarrolladores.

## Decisiones del equipo (23 de noviembre)

Estas cinco decisiones ajustan el alcance del enunciado y prevalecen sobre las secciones siguientes cuando haya diferencia.

1. **Los empleados no tienen tiempo.** No pueden revisar el celular durante la jornada: el sistema les pide lo mínimo y les muestra la información sin que la busquen.
2. **Catálogo reducido.** Solo se ofrecen uñas (tradicional, acrílicas, semipermanentes) y cabello (corte, color, peinado).
3. **Duraciones fijas, con excepciones por chat.** Las uñas siempre duran 45 minutos y el cabello 30. Los casos que necesitan más tiempo tienen dos caminos, ambos con un bot en formato chat:
   - Asesoría antes de reservar: el cliente dice que necesita asesoría y el bot le indica cuánto puede tardar el servicio y quién está disponible. Ejemplo: una decoloración toma unas 5 horas y están disponibles Patty y Sofía.
   - Diseño de uñas más complicado de lo esperado (por ejemplo, se partió una uña acrílica): el bot le pide al cliente que escriba su caso, como en un chat.
4. **Factura electrónica solo como historial.** No se integra con ningún proveedor; el sistema guarda y muestra el historial de facturas para no complicar el alcance.
5. **Agenda en un televisor.** La agenda de los empleados se actualiza con cada cambio y se muestra en un televisor del salón: en qué turno va cada empleado, cuál es el siguiente y cuánto se demorará en el turno actual.

**Por definir a partir de estas decisiones**

- Cómo calcula el bot el tiempo. Supuesto: una tabla configurable por servicio con la duración especial y los empleados habilitados (por ejemplo, decoloración con Patty y Sofía).
- Quién confirma el tiempo cuando el cliente escribe un caso de uñas. Supuesto: el bot propone un tiempo y el administrador lo confirma antes de reservar.
- En qué canal vive el bot: el enlace público de reserva, WhatsApp o ambos.
- Cuántos televisores hay. Supuesto: uno por sede.

## Hallazgos de las entrevistas

La prioridad de los dueños es automatizar la agenda: las solicitudes llegan por WhatsApp, Facebook y otros canales, y hoy dependen de la operación presencial.

- Los dueños perciben estabilidad económica y quieren dedicar su tiempo a investigar y desarrollar oportunidades, no a coordinar el día a día.
- Los empleados tienen poco tiempo para revisar el celular y suelen salir al terminar sus turnos, porque su pago está ligado a los servicios atendidos.
- Un modelo descrito: el gerente entrega productos o herramientas y su costo se descuenta del pago final. Para el proyecto se registra la entrega y, cuando corresponda, el cobro se muestra como un concepto separado.
- Quieren documentos digitales disponibles cuando se los soliciten y métricas claras por trabajador y por sede.
- Los negocios ya usan facturación electrónica. Decisión del equipo: el sistema solo guarda y muestra el historial de facturas, sin integrarse con el proveedor.
- El rango de inversión mencionado fue de $1 a $3 millones COP. Falta confirmar si es implementación, presupuesto anual u otra modalidad.

## Reglas del enunciado por módulo

El enunciado exige ocho módulos; estas son las reglas que el sistema debe cumplir en cada uno.

| Módulo | Reglas que implementar |
|---|---|
| Empleados y documentos | Registrar y actualizar datos personales; retirar del equipo a quienes ya no trabajan allí; verificar los documentos que pide la Secretaría de Salud; conservar el historial de servicios y pagos. |
| Clientes y reservas | Registrar clientes. Cliente y administrador reservan según servicio, duración, horario y disponibilidad. El cliente puede elegir a un profesional habilitado o consultar quién está disponible. |
| Agenda de empleados | Asignar turnos según horario y servicios habilitados. El administrador consulta turnos por fecha; el empleado consulta sus turnos programados y realizados. |
| Factura | Una sola factura por cita, con cada servicio, su valor y el empleado que lo prestó. |
| Comisiones y pagos | Calcular el pago con los servicios realizados y el porcentaje de comisión. Pagos diarios, semanales, quincenales o mensuales, según elija el empleado. Mostrar detalle y total individual. |
| Inventario | Separar productos de uso interno y de venta. En cada entrega interna registrar empleado, fecha y cantidad. Listar los productos de venta con menos de cinco unidades. |
| Finanzas | Mostrar por separado ingresos por servicios e ingresos por venta de productos. Registrar gastos (arriendo, servicios) y calcular ganancias brutas y netas. |
| Roles | Cliente, empleado, administrador y dueño. El dueño hace todo lo del administrador y además consulta ganancias totales y costo de pagos. |

## Roles y permisos

Cuatro roles con alcance creciente; el cliente solo ve lo propio y el dueño ve todo el negocio.

| Rol | Qué puede hacer | Qué no ve |
|---|---|---|
| Cliente | Reservar, elegir profesional o ver quién está libre, y consultar sus citas y su factura. | Datos de otros clientes, pagos y finanzas. |
| Empleado | Ver sus turnos en el televisor del salón y consultar los programados y realizados, marcar servicios como realizados y consultar su detalle y total de pago. | Agenda y pagos de otros empleados; finanzas. |
| Administrador | Gestionar agenda, empleados y documentos, clientes, inventario y gastos; registrar reservas que llegan por chat. | Ganancias totales y costo acumulado de pagos (por confirmar con el profesor). |
| Dueño | Todo lo del administrador, más ganancias totales y costo de pagos, con filtros por trabajador, sede y fecha. | Nada dentro de su negocio. |

**Pendiente:** confirmar si el administrador ve el detalle y total individual de pagos mientras el costo acumulado queda reservado al dueño.

## Estado del arte y referencias

La agenda digital, las comisiones y los reportes ya existen en el mercado; el aporte propuesto es conectarlos con las reglas de los salones entrevistados.

| Referencia | Qué aporta al proyecto |
|---|---|
| Javier Duque Peluquería, Bogotá ([servicios](https://javierduquepeluquerias.com/servicios/), [productos](https://javierduquepeluquerias.com/)) | Catálogo de servicios y venta de productos; permite plantear una demo con corte y manicure en una sola cita. |
| Norberto Peluquería, Bogotá ([catálogo](https://norbertopeluqueria.com/servicios/)) | Servicios organizados por categorías y asociados a las especialidades del equipo. |
| TONI&GUY ([reservas](https://toniandguy.com/pages/faq)) | Horarios disponibles y búsqueda de cita con el estilista preferido. |
| Encanto y Belleza, UNAD ([proyecto académico](https://repository.unad.edu.co/handle/10596/82531)) | Prototipo móvil de Ceballos Benjumea (2026) con agenda central, consulta de citas por empleado y registro de servicios atendidos. |
| AgendaPro ([historia](https://fenventures.com/portfolio/agenda-pro/), [funciones](https://agendapro.com/co/peluqueria/software-para-peluquerias), [planes](https://agendapro.com/co/planes-int)) | Empezó por reservas y añadió pagos, clientes e inventario. En Colombia ofrece planes mensuales con opciones por sucursal. |
| Fresha ([historia](https://techcrunch.com/2018/08/02/shedul/), [precios](https://www.fresha.com/es/pricing), [comisiones](https://www.fresha.com/es/help-center/knowledge-base/team/98-set-up-commissions-for-team-members), [avisos](https://www.fresha.com/es/help-center/knowledge-base/calendario/101218-gestionar-los-ajustes-de-las-reservas-online), [permisos](https://www.fresha.com/es/help-center/knowledge-base/reports/192-manage-report-access-for-team-members)) | Nació como SaaS gratuito y hoy combina suscripciones con tarifas por clientes captados. Su documentación sirve de referencia para comisiones, avisos al equipo y permisos de informes. |

La hipótesis comercial es que el dueño dedicará menos tiempo a coordinar citas y cerrar pagos si cada servicio atendido queda vinculado al profesional, su comisión y los indicadores de la sede.

## Caso para la demostración

Una clienta reserva en una sola cita un corte con Laura y un manicure con Camila, y el sistema deja una factura con dos líneas.

1. Reserva **corte a las 10:00 con Laura** y **manicure a las 10:30 con Camila**.
2. El sistema valida la duración (30 minutos el corte, 45 el manicure) y la disponibilidad de cada servicio y actualiza ambas agendas.
3. Genera **una factura con dos líneas**, cada una con su valor y su empleada.
4. Al marcar cada servicio como realizado, alimenta la comisión de quien lo atendió y el reporte de la sede.

## Supuestos y preguntas abiertas

Nueve puntos siguen sin confirmar; los cuatro primeros cambian el modelo de datos y conviene cerrarlos antes de programar.

| Pregunta | Se confirma con | Supuesto de trabajo |
|---|---|---|
| ¿El administrador ve el detalle y total individual de pagos, y el costo acumulado es solo del dueño? | Profesor | Sí: el administrador ve el detalle individual; el costo acumulado es del dueño. |
| ¿Cómo se definen ganancia bruta y neta? | Profesor | Bruta = ingresos − comisiones; neta = bruta − gastos. |
| ¿Se espera multi-negocio real o basta una sede en la entrega académica? | Profesor | Modelo con negocio y sede desde el inicio; se usa una sede en la entrega. |
| ¿Hay stack obligatorio, fecha de entrega y tamaño del equipo? | Profesor y equipo | Sin definir; se recomienda PostgreSQL por la validación de traslapes. |
| ¿Qué documentos pide en la práctica la Secretaría de Salud y si vencen? | Salones | Cada documento con fecha de vencimiento opcional. |
| ¿El descuento por productos o herramientas se cobra siempre o solo a veces? | Salones | Se registra la entrega y el cobro es un concepto separado cuando corresponde. |
| ¿La comisión es un porcentaje único por empleado o varía por servicio? | Salones | Porcentaje por empleado, con opción de ajustarlo por servicio. |
| ¿Cuánto dura cada servicio y un empleado puede atender dos clientes a la vez? | Salones | Un cliente a la vez por empleado; duración configurable por servicio. |
| El rango de $1 a $3 millones COP, ¿es implementación, presupuesto anual u otra modalidad? | Salones | Por validar; el piloto no depende de este dato. |

## Alcance, orden de trabajo y viabilidad

La entrega académica cubre los pasos 1 a 4; los pasos 5 a 7 son validación comercial y quedan como fase posterior.

**Entrega académica**

1. Aclarar reglas y diseñar los datos: negocio, sede, usuarios, empleados, documentos, servicios, horarios, clientes, citas, detalle por servicio, facturas, inventario, comisiones y gastos.
2. Construir la agenda: enlace público de reserva para WhatsApp y Facebook, registro de solicitudes de chat por el administrador y validación de traslapes con reservas simultáneas y bot de asesoría por chat para los servicios que necesitan más tiempo.
3. Probar el flujo del trabajador: turno actual, siguiente y duración en un televisor que se actualiza con cada cambio, y registro de cada servicio completado.
4. Completar la entrega: historial de facturas con su detalle, liquidación por período, expediente digital, inventario, gastos y reportes con permisos y filtros por trabajador, sede y fecha.

**Fase posterior (validación comercial)**

5. Piloto en una sede: una jornada real, comparando cuántas reservas requieren al dueño y cuánto tarda el cierre de pagos.
6. Segundo negocio con la misma aplicación, verificando el aislamiento de datos y que no requiera módulos a medida.
7. Validar el cobro con una suscripción mensual por sede y cotizar aparte la puesta en marcha.

**Viabilidad**

- Técnica: viable como piloto si se validan las reservas simultáneas, los permisos y el aislamiento de datos entre negocios.
- Operativa: los dueños expresaron disposición al cambio; el piloto debe mostrar si el equipo usa la agenda sin depender del dueño.
- Comercial: por validar. La evidencia buscada es que dos salones usen el mismo producto, que al menos uno pague por continuar y que el ingreso cubra el costo de atenderlo.

Primer paso: acordar con uno de los salones entrevistados qué servicio y qué trabajadores participarían en la prueba, y usar esa jornada para diseñar el primer flujo de reserva.

## Material de diseño preparado

Ya hay una maqueta de pantallas y un tablero de flujos para que los desarrolladores empiecen en paralelo con el modelo de datos.

| Material | Qué contiene |
|---|---|
| [Maqueta de pantallas](https://claude.ai/artifact/QzeV7U7JaXWVw1mFZJbEBJ) | Reserva del cliente con catálogo reducido, chat de asesoría, historial de facturas, agenda del administrador, televisor del salón, comisiones y pagos, inventario y finanzas del dueño. Los datos son de ejemplo. |
| [Diagramas de flujo por módulo y por rol](https://claude.ai/artifact/XUxKQyBm7kqEZBJDoKWP1S) | Ocho flujos (empleados, reservas, agenda, factura, comisiones, inventario, finanzas y roles) y cuatro flujos de usuario que muestran, junto a cada rol, lo que vive el cliente. |

Las pantallas también están en PDF en la carpeta [`design/`](../design).
