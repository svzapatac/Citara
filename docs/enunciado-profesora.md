# Proyecto de Programación Avanzada — Gestión de peluquerías y salones de uñas

## Objetivo

Desarrollar un sistema que centralice las reservas y conecte la agenda de cada trabajador con los servicios realizados, la facturación, las comisiones, el inventario y los reportes. La oportunidad comercial es ayudar al dueño a delegar la operación diaria y consultar los resultados por trabajador y sede.

## Qué exige el enunciado

| Módulo | Qué implementar |
|---|---|
| Empleados y documentos | Registrar y actualizar datos personales, retirar del equipo a quienes ya no trabajan allí y verificar los documentos solicitados por la Secretaría de Salud. Conservar el historial de servicios y pagos. |
| Clientes y reservas | Registrar clientes. Permitir que cliente y administrador reserven según servicio, duración, horario y disponibilidad. El cliente puede elegir a un profesional habilitado o consultar quién está disponible. |
| Agenda de empleados | Asignar turnos según horario y servicios habilitados. El administrador consulta turnos por fecha y el empleado consulta sus turnos programados y realizados. |
| Factura | Mostrar una sola factura por cita, con cada servicio, su valor y el empleado que lo prestó. |
| Comisiones y pagos | Calcular el pago a partir de servicios realizados y el porcentaje de comisión. Admitir pagos diarios, semanales, quincenales o mensuales según elija el empleado. Mostrar el detalle y el total individual. |
| Inventario | Separar productos de uso interno y de venta. Registrar empleado, fecha y cantidad en cada entrega interna. Listar productos para venta con existencias inferiores a cinco unidades. |
| Finanzas | Mostrar por separado los ingresos por servicios y por venta de productos. Registrar gastos, como arriendo y servicios, y calcular ganancias brutas y netas. |
| Roles | Cliente, empleado, administrador y dueño. El dueño puede hacer todo lo que hace el administrador y consultar ganancias totales y costo de pagos. Confirmar con el profesor si el administrador ve el detalle y total individual mientras el costo acumulado queda reservado al dueño. |

## Qué encontramos en las cuatro entrevistas

- Los dueños perciben estabilidad económica y quieren reducir su dependencia de la operación presencial para dedicar más tiempo a investigar y desarrollar oportunidades para el negocio.
- La prioridad es automatizar la agenda. Las solicitudes llegan por WhatsApp, Facebook y otros canales. Los empleados tienen poco tiempo para revisar el celular y suelen salir al terminar sus turnos, pues el pago está ligado a los servicios atendidos.
- Se describió un modelo donde el gerente entrega productos o herramientas y su costo se refleja como descuento en el pago final. Para el proyecto, registrar la entrega y, cuando corresponda, mostrar el cobro como un concepto separado.
- Los dueños quieren documentos digitales disponibles cuando se los soliciten y métricas claras por trabajador y por sede.
- Los negocios consultados ya usan facturación electrónica. El proyecto debe visualizar la factura detallada. La integración con su proveedor puede evaluarse durante la validación comercial.
- El rango de inversión mencionado fue de **$1 a $3 millones COP**. Falta confirmar si corresponde a implementación, presupuesto anual u otra modalidad. Las cuatro entrevistas orientan el piloto y el precio sigue por validar.

## Estado del arte y referencias

El estado del arte compara las soluciones existentes con los requisitos del proyecto. Las entrevistas aportan el diagnóstico de los establecimientos consultados.

| Referencia | Qué aporta al proyecto |
|---|---|
| Javier Duque Peluquería, Bogotá | Referencia para el catálogo de servicios y la venta de productos. Permite plantear una demo con corte y manicure en una sola cita. [Servicios](https://javierduquepeluquerias.com/servicios/) · [Productos](https://javierduquepeluquerias.com/) |
| Norberto Peluquería, Bogotá | Referencia para organizar servicios por categorías y asociarlos a las especialidades del equipo. [Catálogo](https://norbertopeluqueria.com/servicios/) |
| TONI&GUY | Referencia para mostrar horarios disponibles y permitir que el cliente busque una cita con su estilista preferido. [Reservas](https://toniandguy.com/pages/faq) |
| Encanto y Belleza, UNAD | Ceballos Benjumea (2026) desarrolló un prototipo móvil con agenda central, consulta de citas por empleado y registro de servicios atendidos. [Proyecto académico](https://repository.unad.edu.co/handle/10596/82531) |
| AgendaPro | Sus fundadores identificaron que los negocios necesitaban digitalizar su agenda para poder participar en un marketplace. Empezaron por reservas y añadieron pagos, clientes e inventario. En Colombia ofrece planes mensuales con opciones por sucursal. [Historia](https://fenventures.com/portfolio/agenda-pro/) · [Funciones](https://agendapro.com/co/peluqueria/software-para-peluquerias) · [Planes](https://agendapro.com/co/planes-int) |
| Fresha | Empezó como Shedul, un SaaS gratuito para salones y spas. Después añadió un marketplace y cobros asociados a servicios como pagos y captación de clientes. Hoy combina suscripciones con tarifas por nuevos clientes captados en su marketplace. Su documentación sirve de referencia para comisiones, avisos al equipo y permisos de informes. [Historia](https://techcrunch.com/2018/08/02/shedul/) · [Precios](https://www.fresha.com/es/pricing) · [Comisiones](https://www.fresha.com/es/help-center/knowledge-base/team/98-set-up-commissions-for-team-members) · [Avisos](https://www.fresha.com/es/help-center/knowledge-base/calendario/101218-gestionar-los-ajustes-de-las-reservas-online) · [Permisos](https://www.fresha.com/es/help-center/knowledge-base/reports/192-manage-report-access-for-team-members) |

**Conclusión del estado del arte.** La agenda digital, las comisiones y los reportes ya existen. El aporte propuesto es conectar esos módulos con las reglas de los salones entrevistados. La hipótesis comercial es que el dueño dedicará menos tiempo a coordinar citas y cerrar pagos si cada servicio atendido queda vinculado al profesional, su comisión y los indicadores de la sede.

## Qué hacer y en qué orden

1. [ ] **Aclarar reglas y diseñar los datos.** Confirmar permisos de pagos con el profesor. Modelar negocio, sede, usuarios, empleados, documentos, servicios, horarios, clientes, citas y detalle por servicio, facturas, inventario, comisiones y gastos.
2. [ ] **Construir la agenda.** Crear un enlace público de reserva para compartir por WhatsApp y Facebook. Permitir que el administrador registre en el mismo calendario las solicitudes que recibe por chat. Validar traslapes, incluso con reservas simultáneas. Automatizar conversaciones sería una integración posterior.
3. [ ] **Probar el flujo del trabajador.** Mostrar próxima cita y cambios en una vista rápida. Validar con los trabajadores qué aviso ven durante la jornada. Registrar cada servicio completado y actualizar el detalle de la cita.
4. [ ] **Completar la entrega académica.** Implementar factura detallada, liquidación por período, expediente digital, inventario, gastos y reportes con permisos. Añadir filtros por trabajador, sede y fecha para la propuesta comercial.
5. [ ] **Hacer un piloto en una sede.** Configurar un negocio entrevistado, probar una jornada real y comparar cuántas reservas requieren intervención del dueño y cuánto tarda el cierre de pagos.
6. [ ] **Incorporar un segundo negocio.** Usar la misma aplicación con horarios, servicios, sedes y comisiones configurables. Verificar que los datos de cada negocio estén aislados y que incorporarlo no requiera programar módulos a medida.
7. [ ] **Validar el cobro.** Probar una suscripción mensual por sede y cotizar por separado la puesta en marcha si exige migración o capacitación. Medir citas centralizadas, intervención del dueño, tiempo de liquidación, uso por el equipo y renovación. Comparar lo cobrado con los costos de alojamiento, avisos, configuración y soporte.

## Caso para la demostración

Una clienta reserva **corte a las 10:00 con Laura** y **manicure a las 10:45 con Camila**. El sistema valida la duración y disponibilidad de cada servicio, actualiza ambas agendas y genera **una factura con dos líneas**. Al marcar los servicios como realizados, cada uno alimenta la comisión de la trabajadora que lo atendió y el reporte de la sede.

## Viabilidad

- **Técnica.** Viable como piloto si se validan las reservas simultáneas, los permisos y el aislamiento de datos entre negocios.
- **Operativa.** Los dueños expresaron disposición al cambio. El piloto debe mostrar si el equipo consulta la agenda y registra los servicios sin depender del dueño.
- **Comercial.** Por validar. La evidencia buscada es que dos salones puedan usar el mismo producto, que al menos uno pague por continuar y que el ingreso cubra el costo de atenderlo.

**Primer paso.** Acordar con uno de los salones entrevistados qué servicio y qué trabajadores participarían en la prueba, y usar esa jornada para diseñar el primer flujo de reserva.
