<p align="center">
  <img src="assets/citara-logo.png" alt="Citara" width="420">
</p>

**Citara** es una plataforma SaaS para peluquerías y salones de uñas. Centraliza las reservas y conecta la agenda de cada trabajador con los servicios realizados, la factura, las comisiones, el inventario y los reportes, para que el dueño delegue la operación diaria y consulte resultados por trabajador y sede.

Proyecto final de Programación Avanzada.

## Qué incluye el sistema

- **Reservas** del cliente por enlace público, con catálogo reducido: uñas (tradicional, acrílicas, semipermanentes) y cabello (corte, color, peinado).
- **Duraciones fijas** (uñas 45 min, cabello 30 min) y un **bot de asesoría por chat** para los casos que necesitan más tiempo.
- **Agenda de empleados** que se actualiza con cada cambio y se muestra en un **televisor del salón** (turno actual, siguiente y tiempo restante).
- **Factura** única por cita, con **historial de facturas** (sin integración con proveedor electrónico).
- **Comisiones y pagos** diarios, semanales, quincenales o mensuales.
- **Inventario** de uso interno y de venta, con alerta de existencias bajas.
- **Finanzas** con ingresos por servicios y por productos, gastos, y ganancia bruta y neta.
- **Roles:** cliente, empleado, administrador y dueño.

## Contenido del repositorio

| Carpeta | Qué hay |
|---|---|
| [`docs/enunciado-profesora.md`](docs/enunciado-profesora.md) | Enunciado de la profesora: módulos exigidos, hallazgos de las entrevistas y referencias. |
| [`docs/levantamiento-de-informacion.md`](docs/levantamiento-de-informacion.md) | Levantamiento de información, decisiones del equipo (23 de noviembre), roles, supuestos y alcance. |
| [`docs/flujos-por-modulo.md`](docs/flujos-por-modulo.md) | Diagramas de flujo de los ocho módulos del enunciado, corregidos con las decisiones del 23 de noviembre. |
| [`docs/flujos-de-usuario.md`](docs/flujos-de-usuario.md) | Flujos de usuario corregidos de cliente, empleado, administrador y dueño (diagramas). |
| [`docs/flujo-por-panel.md`](docs/flujo-por-panel.md) | Flujo por panel: qué hace el usuario en cada pantalla y qué tablas lee y escribe. |
| [`docs/modelo-de-datos.md`](docs/modelo-de-datos.md) | Borrador del modelo de datos (diagrama entidad-relación) y reglas que debe garantizar. |
| [`design/Citara_Computador.pdf`](design/Citara_Computador.pdf) | Maquetación para computador: 25 pantallas (administración, dueño, televisor). |
| [`design/Citara_Celular.pdf`](design/Citara_Celular.pdf) | Maquetación para celular: 8 pantallas (app del cliente y del empleado). |
| [`assets/`](assets) | Logo de Citara e imagen del sistema visual. |

## Sistema visual

Crema y azul noche como base, un acento iris (`#6D5EF0`) y colores pastel que identifican el tipo de servicio: celeste para corte y peinado, rosa para color, menta para uñas. Títulos en Fraunces y texto en DM Sans.

![Sistema visual de Citara](assets/sistema-visual.png)

> En los PDF los títulos pueden verse con una tipografía de reemplazo; el diseño final usa Fraunces y DM Sans.
