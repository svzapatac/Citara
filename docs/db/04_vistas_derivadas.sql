-- =====================================================================
-- CITARA · 04 · Vistas derivadas (lo que se calcula, no se guarda)
-- Incluyen negocio_id: la app las usa a través de las vistas t_* de 05.
-- =====================================================================
SET NAMES utf8mb4;
USE citara;

-- Existencias en bodega por producto y sede.
CREATE OR REPLACE VIEW v_existencia_bodega AS
SELECT p.negocio_id, p.id AS producto_id, s.id AS sede_id, p.nombre AS producto, p.tipo, s.nombre AS sede,
       COALESCE(SUM(m.cantidad), 0) AS existencia, p.stock_minimo
  FROM producto p
  JOIN sede s ON s.negocio_id = p.negocio_id
  LEFT JOIN movimiento_inventario m
         ON m.negocio_id = p.negocio_id AND m.producto_id = p.id AND m.sede_id = s.id
 WHERE p.activo = 1
 GROUP BY p.negocio_id, p.id, s.id, p.nombre, p.tipo, s.nombre, p.stock_minimo;

-- Productos de venta con menos existencias que su mínimo (alerta del inventario).
CREATE OR REPLACE VIEW v_stock_bajo AS
SELECT * FROM v_existencia_bodega WHERE tipo = 'venta' AND existencia < stock_minimo;

-- Lo que cada empleado tiene en la mano, por entrega.
CREATE OR REPLACE VIEW v_en_mano_empleado AS
SELECT e.negocio_id, e.id AS entrega_id, e.empleado_id, e.producto_id, p.nombre AS producto, e.tipo,
       e.cantidad AS entregadas,
       COALESCE((SELECT SUM(d.cantidad) FROM devolucion_entrega d WHERE d.negocio_id = e.negocio_id AND d.entrega_id = e.id), 0) AS devueltas,
       COALESCE((SELECT SUM(v.cantidad) FROM venta_producto v WHERE v.negocio_id = e.negocio_id AND v.entrega_id = e.id), 0) AS vendidas,
       fn_en_mano(e.negocio_id, e.id) AS en_mano
  FROM entrega_interna e JOIN producto p ON p.negocio_id = e.negocio_id AND p.id = e.producto_id;

-- Agenda del día: un renglón por servicio.
CREATE OR REPLACE VIEW v_agenda_dia AS
SELECT c.negocio_id, c.sede_id, c.fecha, cs.id AS cita_servicio_id, c.id AS cita_id,
       cs.inicio, cs.fin, cs.empleado_id, CONCAT(e.nombres,' ',e.apellidos) AS empleado,
       cl.id AS cliente_id, CONCAT(cl.nombres,' ',cl.apellidos) AS cliente,
       s.nombre AS servicio, cs.valor, cs.estado AS estado_servicio, c.estado AS estado_cita
  FROM cita c
  JOIN cita_servicio cs ON cs.negocio_id = c.negocio_id AND cs.cita_id = c.id
  JOIN empleado e  ON e.negocio_id = cs.negocio_id AND e.id = cs.empleado_id
  JOIN cliente cl  ON cl.negocio_id = c.negocio_id AND cl.id = c.cliente_id
  JOIN servicio s  ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id;

-- Dotación: qué piezas debe tener cada empleado según su área y cuántas tiene.
CREATE OR REPLACE VIEW v_estado_dotacion AS
SELECT ea.negocio_id, ea.empleado_id, a.nombre AS area, ad.producto_id, p.nombre AS pieza,
       ad.cantidad AS requerida,
       COALESCE((SELECT SUM(fn_en_mano(e.negocio_id, e.id)) FROM entrega_interna e
                  WHERE e.negocio_id = ea.negocio_id AND e.empleado_id = ea.empleado_id
                    AND e.producto_id = ad.producto_id AND e.tipo = 'dotacion'), 0) AS entregada,
       CASE WHEN COALESCE((SELECT SUM(fn_en_mano(e.negocio_id, e.id)) FROM entrega_interna e
                  WHERE e.negocio_id = ea.negocio_id AND e.empleado_id = ea.empleado_id
                    AND e.producto_id = ad.producto_id AND e.tipo = 'dotacion'), 0) >= ad.cantidad
            THEN 'completa' ELSE 'falta' END AS estado
  FROM empleado_area ea
  JOIN area a ON a.negocio_id = ea.negocio_id AND a.id = ea.area_id
  JOIN area_dotacion ad ON ad.negocio_id = ea.negocio_id AND ad.area_id = ea.area_id
  JOIN producto p ON p.negocio_id = ad.negocio_id AND p.id = ad.producto_id;

-- Ganancia del empleado por ventas a clientes (público - empleado). El uso personal no gana.
CREATE OR REPLACE VIEW v_ganancia_empleado AS
SELECT v.negocio_id, v.empleado_id, DATE_FORMAT(v.fecha, '%Y-%m') AS mes,
       SUM(CASE WHEN v.destino = 'cliente' THEN v.cantidad * (v.precio_cobrado - v.precio_empleado) ELSE 0 END) AS ganancia,
       SUM(CASE WHEN v.destino = 'cliente' THEN v.cantidad * v.precio_empleado ELSE 0 END) AS descuento_ventas,
       SUM(CASE WHEN v.destino = 'uso_personal' THEN v.cantidad * v.precio_empleado ELSE 0 END) AS descuento_personal
  FROM venta_producto v
 WHERE v.empleado_id IS NOT NULL
 GROUP BY v.negocio_id, v.empleado_id, DATE_FORMAT(v.fecha, '%Y-%m');

-- Documentos del empleado: lo subido, lo pendiente y lo que falta subir.
CREATE OR REPLACE VIEW v_expediente_documentos AS
SELECT e.negocio_id, e.id AS empleado_id, dr.id AS documento_requerido_id, dr.nombre, dr.obligatorio, dr.orden,
       ed.id AS empleado_documento_id, ed.subido_en, ed.verificado_en,
       CASE WHEN ed.id IS NULL THEN 'Falta subir' WHEN ed.estado = 'verificado' THEN 'Verificado' ELSE 'Por verificar' END AS estado
  FROM empleado e
  JOIN documento_requerido dr ON dr.negocio_id = e.negocio_id
  LEFT JOIN empleado_documento ed
         ON ed.negocio_id = e.negocio_id AND ed.empleado_id = e.id AND ed.documento_requerido_id = dr.id;
