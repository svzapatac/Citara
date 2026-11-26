-- =====================================================================
-- CITARA · 06 · Usuarios de la base de datos
-- CAMBIAR las claves antes de usar fuera de una máquina local.
--   citara_app   → la aplicación. Solo ve el esquema citara_app (aislado por negocio).
--   citara_admin → la plataforma (altas de negocios, soporte). Ve todo; nunca desde la web pública.
-- =====================================================================
SET NAMES utf8mb4;
CREATE USER IF NOT EXISTS 'citara_app'@'%'   IDENTIFIED BY 'CAMBIAR_clave_app_1';
CREATE USER IF NOT EXISTS 'citara_admin'@'%' IDENTIFIED BY 'CAMBIAR_clave_admin_1';

GRANT SELECT, INSERT, UPDATE, DELETE ON citara_app.* TO 'citara_app'@'%';
GRANT EXECUTE ON citara_app.* TO 'citara_app'@'%';
-- La app NO tiene permisos sobre el esquema `citara`: no puede saltarse las vistas.

GRANT ALL PRIVILEGES ON citara.*     TO 'citara_admin'@'%';
GRANT ALL PRIVILEGES ON citara_app.* TO 'citara_admin'@'%';
FLUSH PRIVILEGES;
