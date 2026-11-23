# Flujo por panel y tablas que usa cada uno

Cada panel de la maqueta ([`design/`](../design)) se describe con lo que el usuario hace en él y con las **tablas que lee y escribe**. Sirve para derivar el modelo de datos ([`modelo-de-datos.md`](modelo-de-datos.md)) y para repartir el trabajo del front y del back.

Convención: **L** = lee, **E** = escribe (crea o actualiza). Los nombres de tablas están en el [modelo de datos](modelo-de-datos.md).

## Mapa de navegación

```mermaid
flowchart LR
    subgraph Acceso
        Login --> RD1[Registro dueño 1<br/>cuenta] --> RD2[Registro dueño 2<br/>negocio y sede] --> RD3[Registro dueño 3<br/>servicios]
    end
    subgraph Cliente
        CR[Registro] --> CRes[Reservar] --> CCon[Confirmada] --> CMis[Mis citas]
        CRes <--> CAse[Asesoría chat]
    end
    subgraph Administración
        AD[Agenda día] <--> AS[Agenda semana]
        AD --> NC[Nueva cita]
        AD --> Cl[Clientes]
        AD --> Fa[Facturas] --> FD[Factura detalle]
        AD --> Eq[Equipo] --> ER[Registro empleado] --> EE[Expediente]
        Eq --> Tu[Turnos]
        AD --> Se[Servicios]
        AD --> Co[Comisiones] --> PD[Pago detalle]
        AD --> In[Inventario] --> EI[Entrega interna]
    end
    subgraph Dueño
        Fi[Finanzas] --- Re[Reportes] --- Pe[Permisos] --- Sd[Sedes]
    end
    subgraph Empleado
        EH[Mi agenda hoy] --> ESv[Registrar servicio] --> EP[Mis pagos]
    end
    TV[[Televisor]]
    NC -. actualiza .-> TV
    ESv -. actualiza .-> TV
    RD3 --> AD
    CCon -. crea cita .-> AD
```

## Acceso y registro del dueño

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Login | Entra con correo y contraseña; elige reservar como cliente o registrar su negocio. | usuario | — |
| Registro del dueño 1 · Cuenta | Crea su cuenta: nombres, documento, celular, correo, contraseña. | — | usuario (rol dueño) |
| Registro del dueño 2 · Negocio y sede | Datos del negocio, primera sede y horario; sube los documentos del negocio. | — | negocio, sede, sede_horario, documento_negocio |
| Registro del dueño 3 · Servicios | Activa el catálogo (uñas y cabello) con precio. Duración fija: uñas 45 min, cabello 30 min. | — | servicio |

## App del cliente (celular)

```mermaid
flowchart LR
    R[Registro] --> Rs[Reservar]
    Rs -->|necesita más tiempo| A[Asesoría chat]
    A --> Rs
    Rs --> C[Confirmada]
    C --> M[Mis citas]
```

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Cliente · Registro | Se registra con nombre, celular y correo. | — | cliente |
| Cliente · Reservar | Elige servicio, profesional (o quién está libre) y horario. | servicio, empleado_servicio, turno_empleado, cita_servicio (disponibilidad) | cita, cita_servicio |
| Cliente · Asesoría por chat | Pide asesoría; el bot responde duración y empleados disponibles. Para uñas complicadas, el cliente escribe su caso. | asesoria_regla, empleado_servicio | asesoria_chat, asesoria_mensaje |
| Cliente · Reserva confirmada | Ve la factura de la cita con una línea por servicio. | cita, cita_servicio, factura | factura |
| Cliente · Mis citas | Consulta sus citas y el historial de facturas. | cita, cita_servicio, factura | — |

## Administración diaria

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Agenda · Día | Ve los turnos de cada empleado, abre el detalle y marca los servicios realizados. | cita_servicio, empleado, cliente, factura | cita_servicio (estado) |
| Agenda · Semana | Vista semanal de la agenda por empleado. | cita_servicio, empleado | — |
| Nueva cita | Registra una reserva que llegó por chat; valida traslapes. | cliente, servicio, empleado_servicio, turno_empleado, cita_servicio | cita, cita_servicio, factura |
| Clientes | Lista y ficha del cliente con su historial. | cliente, cita, factura | cliente |

## Equipo, documentos y servicios

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Equipo | Lista el equipo, su especialidad y estado. | empleado, empleado_servicio | empleado (activo o retirado) |
| Empleado · Registro | Crea o actualiza datos personales, porcentaje de comisión y periodicidad de pago. | empleado, comision_config | empleado, usuario, comision_config |
| Empleado · Expediente | Sube y verifica los documentos de la Secretaría de Salud; ve historial de servicios y pagos. | documento_requerido, empleado_documento, cita_servicio, liquidacion | empleado_documento |
| Turnos | Asigna turnos según horario y servicios habilitados. | empleado, empleado_servicio | turno_empleado |
| Servicios | Administra el catálogo, duraciones y quién puede hacer cada servicio. | servicio, empleado_servicio, asesoria_regla | servicio, empleado_servicio, asesoria_regla |

## Facturas y pagos

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Facturas | Historial de facturas con filtros por fecha y cliente. | factura, cita, cliente | — |
| Factura · Detalle | Una factura por cita: cada servicio, su valor y su empleado. | factura, cita_servicio, empleado | — |
| Comisiones y pagos | Liquidación por empleado y periodo (diario, semanal, quincenal o mensual). | liquidacion, cita_servicio, comision_config | liquidacion, liquidacion_detalle |
| Pago · Detalle | Detalle de un pago: servicios, comisión, descuentos (por ejemplo tijeras) y total. | liquidacion, liquidacion_detalle, entrega_interna | liquidacion (estado pagado) |

## Inventario, finanzas y permisos

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Inventario | Separa productos de uso interno y de venta; alerta de venta con menos de cinco unidades. | producto | producto |
| Entrega interna | Registra empleado, fecha y cantidad; marca si se cobra como descuento. | producto, empleado | entrega_interna, liquidacion_detalle |
| Finanzas | Ingresos por servicios y por productos, gastos, ganancia bruta y neta. Registra gastos. | factura, venta_producto, liquidacion, gasto | gasto |
| Reportes | Reportes con filtros por trabajador, sede y fecha. | cita_servicio, factura, liquidacion, gasto | — |
| Permisos | Asigna rol (administrador, empleado) y alcance a cada usuario. | usuario | usuario (rol) |
| Sedes | Gestiona sedes, horarios y televisor de cada una. | sede, sede_horario, televisor | sede, sede_horario, televisor |

## App del empleado y televisor

| Panel | Qué hace el usuario | Lee | Escribe |
|---|---|---|---|
| Empleado · Mi agenda de hoy | Ve sus turnos programados y realizados. | cita_servicio, cliente | — |
| Empleado · Registrar servicio | Marca el servicio como realizado con un toque; suma su comisión. | cita_servicio, comision_config | cita_servicio (estado), liquidacion_detalle |
| Empleado · Mis pagos | Ve el detalle y el total de su pago por periodo. | liquidacion, liquidacion_detalle | — |
| Televisor | Muestra por empleado el turno actual, el siguiente y el tiempo restante; se actualiza con cada cambio. | cita_servicio, empleado, turno_empleado | — |
