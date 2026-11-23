# Modelo de datos (borrador)

Primera propuesta derivada de los paneles y de las reglas del enunciado ([`flujo-por-panel.md`](flujo-por-panel.md)). Está pensada para un motor relacional; se recomienda PostgreSQL por la validación de traslapes entre citas.

Decisiones del equipo reflejadas aquí: una sede en la entrega pero con negocio y sede desde el inicio, catálogo para cualquier cliente (cabello, uñas, barbería y cejas), duración fija por servicio con excepciones, varios turnos por día, productos entregados al empleado con descuento mensual, dotación por área, documentos sin vencimiento, factura solo como historial y un televisor por sede.

## Modelo entidad-relación

Modelo completo del software, con todas las tablas, sus campos y sus relaciones. Los colores agrupan las tablas por módulo. `PK` es la llave primaria y `FK` la llave foránea. Las relaciones usan notación de patas de gallo: la pata indica «muchos», la raya «uno» y el círculo «opcional».

[![Modelo entidad-relación completo](er/00-modelo-er-completo.png)](er/00-modelo-er-completo.png)

La imagen es grande. Ábrela y acércate, o descarga la versión vectorial [`00-modelo-er-completo.svg`](er/00-modelo-er-completo.svg), que se puede ampliar sin perder calidad.

### Por módulos

Los mismos datos, divididos para leerlos con calma. Las tablas con solo el nombre son de otro módulo y se muestran para ver cómo se conectan.

**1. Negocio, sedes y accesos**

![Negocio, sedes y accesos](er/01-negocio-sedes-accesos.png)

**2. Equipo: documentos, turnos y comisión**

![Equipo](er/02-equipo-y-documentos.png)

**3. Áreas, servicios y quién los presta**

![Áreas y servicios](er/02b-areas-y-servicios.png)

**4. Reservas, asesoría y facturas**

![Reservas y facturas](er/03-reservas-y-facturas.png)

**5. Comisiones y pagos**

![Comisiones y pagos](er/04-comisiones-y-pagos.png)

**6. Inventario, dotación, ventas y gastos**

![Inventario](er/05-inventario-dotacion-gastos.png)

Para regenerar las imágenes después de cambiar el modelo, edita [`er/modelo-er.mmd`](er/modelo-er.mmd) y ejecuta `python3 docs/er/generar.py` (necesita Graphviz).


## Reglas que el modelo debe garantizar

- **Una factura por cita:** `factura.cita_id` es único; cada servicio es una línea (`cita_servicio`) con su valor y su empleado.
- **Sin traslapes:** un empleado no puede tener dos `cita_servicio` cuyo intervalo `inicio`–`fin` se cruce.
- **Duración:** el valor por defecto sale de `servicio.duracion_min`; los casos especiales salen de `asesoria_regla` o de un caso de uñas confirmado por el administrador.
- **Inventario:** los productos de venta con `existencias_bodega < 5` aparecen en la alerta; cada `entrega_interna` guarda empleado, fecha, cantidad y tipo (dotación, venta o uso interno). Lo que un empleado tiene en mano es lo entregado para vender menos lo vendido, lo de uso personal y lo devuelto.
- **Dotación por área:** `area_dotacion` define el kit de cada área; al registrar a un empleado se entrega el kit de su(s) `empleado_area`. No se cobra; si se pierde o daña, el administrador decide si genera una línea `descuento_dotacion`.
- **Venta de productos:** el negocio entrega al empleado a `precio_empleado`; el empleado cobra al cliente `precio_publico` y se queda con la diferencia. Al cierre del mes se descuenta (`descuento_venta`) lo vendido a precio de empleado y lo de uso personal (`descuento_personal`, sin ganancia); lo devuelto no se descuenta. El ingreso del negocio por productos es el precio de empleado de lo vendido más las ventas de mostrador.
- **Turnos:** una persona puede tener varios `turno_empleado` el mismo día, siempre que no se crucen; una cita solo puede caer dentro de un turno.
- **Catálogo:** los servicios no dependen del género del cliente; una cita puede combinar servicios de varias áreas (por ejemplo corte y barba).
- **Finanzas:** ganancia bruta = ingresos (facturas + ventas de productos) − comisiones; ganancia neta = bruta − gastos. Los ingresos por servicios y por productos se muestran por separado.
- **Pagos:** la comisión de un servicio realizado se suma a la `liquidacion` del periodo que elige el empleado; los descuentos por productos son líneas separadas (`descuento_venta`, `descuento_personal`).
- **Permisos:** el administrador ve el detalle individual de pagos; el costo acumulado es del dueño (por confirmar con el profesor).

## Por confirmar

Los supuestos abiertos del [levantamiento](levantamiento-de-informacion.md) cambian este modelo: comisión por empleado o por servicio, documentos que pide la Secretaría de Salud, si un empleado puede atender dos clientes a la vez, y las cuatro reglas de productos (qué se descuenta si no se vende, quién cobra al cliente, cuándo se descuenta y si la dotación perdida se cobra).
