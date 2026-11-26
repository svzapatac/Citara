-- =====================================================================
-- CITARA · 02 · Datos base de la plataforma (globales)
-- Roles, permisos y planes. Los límites y precios de los planes son
-- EJEMPLOS: están por confirmar con el equipo.
-- =====================================================================
SET NAMES utf8mb4;
USE citara;

INSERT INTO rol (clave, nombre) VALUES
  ('cliente','Cliente'), ('empleado','Empleado'),
  ('administrador','Administrador'), ('dueno','Dueño');

INSERT INTO permiso (modulo, accion)
SELECT m.modulo, a.accion
FROM (SELECT 'agenda' modulo UNION SELECT 'clientes' UNION SELECT 'equipo' UNION SELECT 'servicios'
      UNION SELECT 'facturas' UNION SELECT 'pagos' UNION SELECT 'inventario' UNION SELECT 'finanzas'
      UNION SELECT 'reportes' UNION SELECT 'usuarios' UNION SELECT 'negocio') m
CROSS JOIN (SELECT 'ver' accion UNION SELECT 'crear' UNION SELECT 'editar' UNION SELECT 'eliminar') a;

-- Dueño: todo.
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p WHERE r.clave = 'dueno';
-- Administrador: operación diaria (no finanzas, reportes, usuarios ni negocio).
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p
 WHERE r.clave = 'administrador'
   AND p.modulo IN ('agenda','clientes','equipo','servicios','facturas','pagos','inventario');
-- Empleado: ve su agenda, sus clientes y su inventario.
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p
 WHERE r.clave = 'empleado' AND p.accion = 'ver' AND p.modulo IN ('agenda','inventario','pagos');
-- Cliente: reserva y ve sus citas.
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p
 WHERE r.clave = 'cliente' AND p.modulo = 'agenda' AND p.accion IN ('ver','crear');

INSERT INTO plan (nombre, max_sedes, max_empleados, precio_mensual) VALUES
  ('Inicial',      1,  5,  49000),
  ('Profesional',  3, 20, 99000),
  ('Cadena',      10, 100, 249000);
