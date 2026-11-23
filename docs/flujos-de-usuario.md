# Flujos de usuario por rol

Versión corregida con las decisiones del equipo del 23 de noviembre: catálogo reducido, duraciones fijas con asesoría por chat, agenda en televisor, factura solo como historial y empleados sin tiempo para revisar el celular.

En cada flujo, los nodos con borde punteado son **lo que vive o piensa el cliente** mientras el rol hace su trabajo. Los nombres entre corchetes son los paneles de la maqueta (carpeta [`design/`](../design)).

## 1. Cliente

```mermaid
flowchart TD
    A([Recibe el enlace de reserva por WhatsApp o Facebook]) --> B[Cliente · Registro<br/>o reserva sin cuenta]
    B --> C{¿Necesita más tiempo<br/>del habitual?}
    C -- No --> D[Cliente · Reservar<br/>elige servicios: cabello 30, uñas 45,<br/>barba 30, cejas 15 min]
    C -- Sí --> K[Cliente · Asesoría por chat]
    K --> L[El bot indica cuánto tarda<br/>y quién está disponible<br/>ej. decoloración 5 h con Patty o Sofía]
    K --> M[Caso de uñas complicado<br/>ej. se partió una acrílica:<br/>el cliente escribe su caso]
    M --> N[El bot propone un tiempo<br/>y el administrador lo confirma]
    L --> D
    N --> D
    D --> E[Elige profesional habilitado<br/>o consulta quién está libre]
    E --> F[Elige un horario disponible]
    F --> G[Confirma la reserva]
    G --> H[Cliente · Reserva confirmada<br/>una factura por cita]
    H --> I[Va al salón]
    I --> J[Cliente · Mis citas<br/>citas e historial de facturas]
    B -.-> p1[/"Piensa: no quiero llamar ni esperar respuesta"/]
    G -.-> p2[/"Piensa: ya quedó, no tengo que confirmar por chat"/]
    J -.-> p3[/"Piensa: aquí veo mi factura cuando la necesite"/]
    style p1 stroke-dasharray: 4 4
    style p2 stroke-dasharray: 4 4
    style p3 stroke-dasharray: 4 4
```

## 2. Empleado

El empleado no revisa el celular durante la jornada: la información le llega en el televisor del salón.

```mermaid
flowchart TD
    A([Llega al salón]) --> B[Mira el televisor<br/>turno actual, tiempo restante y turnos del día]
    B --> C[Atiende al cliente]
    C --> D[Empleado · Registrar servicio<br/>marca el servicio como realizado, con un toque]
    D --> E[La agenda se actualiza<br/>y el televisor cambia de turno]
    E --> F{¿Más turnos hoy?}
    F -- Sí --> B
    F -- No --> G([Sale al terminar su último turno])
    D --> H[La comisión se suma a su pago]
    C --> V[Empleado · Mis productos<br/>registra la venta a un cliente<br/>o su compra de uso personal]
    V --> I
    H --> I[Empleado · Mis pagos<br/>comisión, descuentos del mes,<br/>ganancia por ventas y total]
    C -.-> c1[/"Cliente: me atienden a la hora que reservé"/]
    E -.-> c2[/"Cliente: el siguiente turno ya está listo"/]
    style c1 stroke-dasharray: 4 4
    style c2 stroke-dasharray: 4 4
```

## 3. Administrador

```mermaid
flowchart TD
    A([Inicia sesión]) --> B[Agenda · Día<br/>turnos de todos los empleados]
    B --> C[Nueva cita<br/>reservas que llegan por chat]
    C --> D{¿Se traslapa con otra reserva?}
    D -- Sí --> C
    D -- No --> E[Cita guardada y agenda actualizada]
    E --> F[Factura de la cita en el historial]
    B --> G[Confirma el tiempo que propone el bot<br/>en casos de uñas complicados]
    B --> H[Equipo · empleados y documentos<br/>registro, expediente, retiro]
    B --> I[Turnos y Servicios<br/>horarios y servicios habilitados]
    B --> J[Inventario, dotación por área y entregas<br/>de productos para vender al empleado]
    B --> K[Finanzas · registrar gastos]
    B --> L[Comisiones y pagos<br/>detalle individual, por confirmar con el profesor]
    C -.-> c1[/"Cliente: me confirmaron mi cita sin llamar"/]
    style c1 stroke-dasharray: 4 4
```

## 4. Dueño

```mermaid
flowchart TD
    A([Registra su negocio]) --> B[Registro del dueño · Cuenta]
    B --> C[Negocio y sede]
    C --> D[Servicios y precios]
    D --> E[Sube los documentos del negocio]
    E --> F[Invita al administrador y a los empleados<br/>Permisos]
    F --> G([Opera con el panel del administrador])
    G --> H[Finanzas<br/>ingresos por servicios y productos,<br/>gastos, ganancia bruta y neta]
    G --> I[Reportes<br/>filtros por trabajador, sede y fecha]
    G --> J[Comisiones y pagos<br/>costo acumulado, solo dueño]
    G --> K[Sedes<br/>un televisor por sede]
    I -.-> c1[/"Cliente: el salón me atiende igual aunque el dueño no esté"/]
    style c1 stroke-dasharray: 4 4
```
