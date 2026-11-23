# Diagramas de flujo por módulo

Los ocho módulos del enunciado, tomados del tablero «Diagramas de flujo por módulo» y **corregidos con las decisiones del equipo del 23 de noviembre**: catálogo reducido (uñas y cabello), duraciones fijas con asesoría por chat, agenda del empleado en el televisor, factura solo como historial y empleados sin tiempo para revisar el celular.

Colores: azul = paso, amarillo = decisión, verde = resultado, naranja = excepción. Los cambios respecto al tablero original están marcados con ✱.

Los flujos por rol, con lo que vive el cliente, están en [`flujos-de-usuario.md`](flujos-de-usuario.md).

## 1. Empleados y documentos

```mermaid
flowchart LR
    A[Administrador registra al empleado] --> B[Cargar documentos de la Secretaría de Salud]
    B --> C{¿Documentos verificados?}
    C -- Sí --> D[Habilitar servicios y horario]
    C -- No --> E[Pendiente: no recibe turnos]
    D --> F[Activo en la agenda]
    F --> G[Retirar del equipo]
    G --> H[Se conserva historial de servicios y pagos]
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef dec fill:#fef9c3,stroke:#ca8a04
    classDef ok fill:#dcfce7,stroke:#16a34a
    classDef exc fill:#ffedd5,stroke:#ea580c
    class A,B,D,G paso
    class C dec
    class F,H ok
    class E exc
```

## 2. Clientes y reservas

✱ Se agrega la asesoría por chat para los servicios que necesitan más tiempo que el fijo (uñas 45 min, cabello 30 min).

```mermaid
flowchart LR
    A[Cliente abre el enlace público de reserva] --> B[Elegir servicio<br/>uñas 45 min · cabello 30 min]
    A2[Administrador registra una solicitud de chat] --> B
    B --> Q{✱ ¿Necesita más tiempo<br/>del habitual?}
    Q -- Sí --> AS[✱ Asesoría por chat<br/>el bot indica duración y quién está disponible]
    AS --> CF[✱ Caso de uñas complicado:<br/>el cliente escribe su caso<br/>y el administrador confirma el tiempo]
    Q -- No --> P[Elegir profesional o ver disponibles]
    CF --> P
    P --> D{¿Hay espacio libre?}
    D -- Sí --> R[Registrar cliente y confirmar]
    R --> G[Agenda de cada empleado<br/>y televisor actualizados]
    D -- No --> O[Ofrecer otros horarios]
    O --> P
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef dec fill:#fef9c3,stroke:#ca8a04
    classDef ok fill:#dcfce7,stroke:#16a34a
    classDef exc fill:#ffedd5,stroke:#ea580c
    class A,A2,B,AS,CF,P,R paso
    class Q,D dec
    class G ok
    class O exc
```

## 3. Agenda de empleados

✱ El empleado ya no consulta el celular: ve su turno actual, el siguiente y el tiempo restante en el televisor, que se actualiza con cada cambio.

```mermaid
flowchart LR
    A[Administrador define turnos y horario] --> B[Asignar servicios habilitados]
    B --> C[✱ Televisor del salón:<br/>turno actual, siguiente y tiempo restante]
    C --> D[Atiende el servicio]
    D --> E[Marca el servicio como realizado]
    E --> F[Detalle de la cita y factura actualizados]
    E --> G[Alimenta comisión y reporte de la sede]
    B --> H[Administrador consulta turnos por fecha]
    H --> X[✱ Cambio de cita: se actualiza<br/>la agenda y el televisor]
    X --> C
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef ok fill:#dcfce7,stroke:#16a34a
    classDef exc fill:#ffedd5,stroke:#ea580c
    class A,B,C,D,E,H paso
    class F,G ok
    class X exc
```

## 4. Factura

✱ Solo se guarda y muestra el **historial de facturas**; no hay integración con un proveedor de facturación electrónica.

```mermaid
flowchart LR
    A[Cita con uno o más servicios] --> B[Crear una sola factura por cita]
    B --> C[Una línea por servicio:<br/>valor y empleado]
    C --> D{¿Servicio realizado?}
    D -- Sí --> E[Línea queda como realizada]
    E --> F[Factura detallada:<br/>ver, imprimir o PDF]
    F --> H[✱ Se guarda en el historial de facturas]
    D -- No --> G[La línea sigue programada]
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef dec fill:#fef9c3,stroke:#ca8a04
    classDef ok fill:#dcfce7,stroke:#16a34a
    classDef exc fill:#ffedd5,stroke:#ea580c
    class A,B,C,E paso
    class D dec
    class F,H ok
    class G exc
```

## 5. Comisiones y pagos

```mermaid
flowchart LR
    A[Empleado elige: diario, semanal,<br/>quincenal o mensual] --> B[Reunir servicios realizados del período]
    B --> C[Aplicar el porcentaje de comisión]
    C --> D{¿Hay entregas con cobro?}
    D -- Sí --> E[Restar el descuento como concepto aparte]
    E --> F[Detalle y total a pagar por empleado]
    D -- No --> G[Sin descuentos]
    G --> F
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef dec fill:#fef9c3,stroke:#ca8a04
    classDef ok fill:#dcfce7,stroke:#16a34a
    class A,B,C,E,G paso
    class D dec
    class F ok
```

## 6. Inventario

```mermaid
flowchart LR
    A[Registrar producto] --> B{¿Venta o uso interno?}
    B -- Venta --> C[Registrar la venta<br/>ingreso aparte]
    C --> D[Descontar existencias]
    D --> E[Revisar existencias del producto]
    E --> F{¿Quedan menos de 5?}
    F -- Sí --> G[Alerta de stock bajo<br/>en la lista de venta]
    B -- Interno --> H[Entrega interna:<br/>empleado, fecha y cantidad]
    H --> I{¿Se cobra al empleado?}
    I -- Sí --> J[Descuento en el pago,<br/>como concepto aparte]
    I -- No --> K[Solo queda registrada la entrega]
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef dec fill:#fef9c3,stroke:#ca8a04
    classDef ok fill:#dcfce7,stroke:#16a34a
    classDef exc fill:#ffedd5,stroke:#ea580c
    class A,C,D,E,H,J paso
    class B,F,I dec
    class K ok
    class G exc
```

## 7. Finanzas

Fórmulas por confirmar con el profesor; el supuesto de trabajo es bruta = ingresos − comisiones y neta = bruta − gastos.

```mermaid
flowchart LR
    S[Ingresos por servicios realizados] --> T[Ingresos totales,<br/>mostrados por separado]
    P[Ingresos por venta de productos] --> T
    T --> C[Restar costo de pagos<br/>comisiones]
    C --> B[Ganancia bruta]
    B --> G[Restar gastos del período]
    X[Registrar gastos:<br/>arriendo, servicios] --> G
    G --> N[Ganancia neta]
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef ok fill:#dcfce7,stroke:#16a34a
    class S,P,T,C,G,X paso
    class B,N ok
```

## 8. Roles y permisos

El alcance del administrador sobre los pagos está por confirmar con el profesor.

```mermaid
flowchart LR
    A[Iniciar sesión] --> R{¿Qué rol tiene?}
    R --> C[Cliente]
    R --> E[Empleado]
    R --> M[Administrador]
    R --> D[Dueño]
    C --> C2[Reserva, pide asesoría por chat<br/>y consulta sus citas y facturas]
    E --> E2[✱ Ve sus turnos en el televisor,<br/>marca servicios realizados<br/>y consulta su detalle y total de pago]
    M --> M2[Agenda, empleados y documentos,<br/>inventario y gastos; registra reservas de chat]
    D --> D2[Todo lo del administrador,<br/>más ganancias totales y costo de pagos]
    classDef paso fill:#dbeafe,stroke:#3b82f6
    classDef dec fill:#fef9c3,stroke:#ca8a04
    classDef ok fill:#dcfce7,stroke:#16a34a
    class A,C,E,M,D paso
    class R dec
    class C2,E2,M2,D2 ok
```
