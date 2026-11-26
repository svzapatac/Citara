-- =====================================================================
-- CITARA · Claves de acceso de prueba (hash bcrypt, compatible con password_verify de PHP)
-- Cada rol tiene una clave distinta. Solo para desarrollo: cambiarlas en producción.
--   dueño          → Dueno123*
--   administrador  → Admin123*
--   empleado       → Empleado123*
--   cliente        → Cliente123*
--   plataforma     → Plataforma123*
-- Ingreso: correo del usuario + la clave de su rol, ej. dueno@negocio001.co / Dueno123*
-- =====================================================================
UPDATE usuario u JOIN rol r ON r.id = u.rol_id SET u.clave_hash = CASE r.clave
  WHEN 'dueno'         THEN '$2y$10$glr8P1ezbzWlih2Yn.2xxOgHa0N4Ep1sj0zrRBDh1887euZiwFRnC'
  WHEN 'administrador' THEN '$2y$10$8Nxvg1kfzRq4fZU49VwhBuS8SIz2dOfdJuAfedTc3TRC6ATF6B4wK'
  WHEN 'empleado'      THEN '$2y$10$eQpfbvhAGhMJWngzpZKZDuzLsIQ8wwkXJeGHv22ONd8QCExtV0cn.'
  ELSE                      '$2y$10$zUeOff6pblWyi6bcbaAjO.7DwRzFvh6XDcO4L6YZzB47Nh60VoZ1u' END;

UPDATE admin_plataforma SET clave_hash = '$2y$10$uZtC4SSOwxdkypV.aSxVCOQmbyDT/tNEgqeRfEJDawLRRqsvliPOG';

-- Para cambiar la clave de UN usuario (genera el hash en PHP con password_hash('NuevaClave', PASSWORD_DEFAULT)):
-- UPDATE usuario SET clave_hash = '<hash>' WHERE negocio_id = 1001 AND correo = 'dueno@negocio001.co';
