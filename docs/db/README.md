# Base de datos de Citara (MySQL 8.0.16+)

Multi-tenant en "pool": una sola base para todos los negocios, con `negocio_id` en cada tabla. El diseño y el diagrama E-R están en [`../modelo-de-datos.md`](../modelo-de-datos.md).

## Instalar

```bash
cd docs/db
./instalar.sh                 # crea las bases `citara` y `citara_app` (borra las que existan)
CON_DEMO=1 ./instalar.sh      # además carga 2 negocios de ejemplo y corre las pruebas
CON_MASIVO=1 ./instalar.sh    # además carga 55 negocios con más de 50 filas por tabla
```

O todo de una vez: `mysql -u root -p < citara_mysql.sql`.

## Qué hay en cada archivo

| Archivo | Contenido |
|---|---|
| `01_esquema.sql` | 43 tablas, claves foráneas compuestas, únicos por negocio, `CHECK` e índices |
| `02_datos_base.sql` | Roles, permisos y planes (los planes son ejemplo) |
| `03_logica.sql` | Reglas: turnos y citas sin cruzarse, inventario sin negativos, entregas y devoluciones, facturas con consecutivo, alta de un negocio |
| `04_vistas_derivadas.sql` | Existencias, stock bajo, lo que tiene cada empleado, agenda del día, estado de la dotación, ganancia del empleado, documentos del expediente |
| `05_aislamiento_tenant.sql` | Esquema `citara_app`: una vista por tabla filtrada por negocio (reemplaza a RLS). Se genera con `generar_aislamiento.py` |
| `06_roles.sql` | Usuarios `citara_app` (la aplicación) y `citara_admin` (la plataforma). **Cambiar las claves** |
| `07_datos_demo.sql` | Dos negocios de ejemplo (Salón Demo y Barbería Norte) |
| `08_pruebas.sql` | 26 comprobaciones de aislamiento y reglas |
| `09_datos_masivos.sql` | 55 negocios con más de 50 filas en casi todas las tablas, para probar (generado con `generar_masivo.py`; ids desde 1001). `rol` (4, límite del `CHECK`) y `plan` (3) se quedan cortos a propósito |
| `citara_mysql.sql` | 01 a 06 en un solo archivo |

## Cómo debe usarla la aplicación

1. La aplicación se conecta como `citara_app` y **solo** al esquema `citara_app`.
2. El backend decide el negocio (por el `slug` de la URL o por la sesión del usuario ya verificada, nunca por un dato que mande el navegador) y, al tomar una conexión del pool, ejecuta `CALL sp_set_negocio(<id>)`. Al devolverla, `CALL sp_limpiar_negocio()`.
3. Cada `INSERT` lleva su `negocio_id`; si no es el de la conexión, la base lo rechaza.
4. Para facturar: `CALL sp_emitir_factura(<cita>, 'efectivo', @factura)`.
5. Para dar de alta un negocio nuevo (solo la plataforma, como `citara_admin`): `CALL sp_crear_negocio('mi-salon', 'Mi Salón', <plan>, 'dueno@correo.co', '<hash>', @negocio)`.

## Reglas que hace cumplir la base de datos

- Un registro de un negocio no puede apuntar a otro negocio (claves compuestas).
- Un empleado no tiene dos citas ni dos turnos que se crucen; una cita cae dentro de un turno, en un servicio que el empleado tiene habilitado, y no sobre un bloqueo de agenda.
- La bodega no queda en negativo; los movimientos de inventario y la auditoría no se editan ni se borran.
- Un empleado no puede devolver ni vender más de lo que tiene.
- Un producto de venta lleva precio público y de empleado (el de empleado no es mayor); dotación y uso interno no llevan precio.
- Cada negocio tiene su propia numeración de facturas.

## Pendientes y decisiones por confirmar

- Cálculo automático de la liquidación (hoy las tablas `liquidacion` y `liquidacion_detalle` están listas, falta el procedimiento): depende del modelo de comisión que defina el equipo.
- Límites y precios de los planes (los de `02_datos_base.sql` son de ejemplo).
- Si una misma persona puede tener cuenta en varios negocios (hoy el correo es único por negocio).
- Qué hacer al borrar un negocio: el diseño usa baja lógica (`estado = 'cancelado'`), no borrado físico.

## Front en PHP (carpeta `Front/`)

Todas las pantallas leen y escriben en esta base. El negocio sale siempre de la sesión.
En hosting: corre en este orden `hosting/1`, `2`, (`3` opcional), `4` y por último **`0_migracion_front.sql`**;
sube `Front/` completo (con `conexion.php` con tus credenciales). La carpeta `Front/uploads/` se crea sola
al subir logos o documentos. Pantalla de TV: `Front/turnos-hoy.php?t=TOKEN`.
