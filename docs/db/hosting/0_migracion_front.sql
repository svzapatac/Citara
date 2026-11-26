-- =====================================================================
-- CITARA · Migración para el Front en PHP (MariaDB / MySQL del hosting)
-- Córrelo UNA vez sobre la base que ya tienes cargada (después de los
-- archivos 1 y 2). Se puede repetir sin dañar nada.
-- =====================================================================
ALTER TABLE negocio
  ADD COLUMN IF NOT EXISTS tipo VARCHAR(40)  NULL AFTER nit,
  ADD COLUMN IF NOT EXISTS logo VARCHAR(255) NULL AFTER tipo;

ALTER TABLE usuario
  ADD COLUMN IF NOT EXISTS nombres        VARCHAR(80) NULL AFTER clave_hash,
  ADD COLUMN IF NOT EXISTS apellidos      VARCHAR(80) NULL AFTER nombres,
  ADD COLUMN IF NOT EXISTS tipo_documento VARCHAR(30) NULL AFTER apellidos,
  ADD COLUMN IF NOT EXISTS documento      VARCHAR(30) NULL AFTER tipo_documento,
  ADD COLUMN IF NOT EXISTS celular        VARCHAR(30) NULL AFTER documento;

-- Tablas de un ajuste anterior que ya no se usan (el Front usa sede, usuario y servicio)
DROP TABLE IF EXISTS servicios;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS sedes;
DROP TABLE IF EXISTS negocios;

-- Nombres para los usuarios de prueba (así el menú muestra a quién entró)
UPDATE usuario u JOIN rol r ON r.id = u.rol_id
   SET u.nombres   = CASE r.clave WHEN 'dueno' THEN 'Dueño' WHEN 'administrador' THEN 'Administrador' ELSE 'Empleado' END,
       u.apellidos = CONCAT('Negocio ', u.negocio_id)
 WHERE u.nombres IS NULL;
