-- Citara · reglas (disparadores/procedimientos) y vistas. Requiere permiso TRIGGER/ROUTINE en el hosting.
SET NAMES utf8mb4;
-- =====================================================================
-- CITARA · 03 · Reglas en la base de datos: funciones, procedimientos
-- y disparadores (MySQL no tiene EXCLUDE ni RLS, así que se hacen aquí).
-- Se ejecuta con el cliente `mysql` (usa DELIMITER).
-- =====================================================================
DELIMITER $$

-- ---------------------------------------------------------------------
-- Tenant de la conexión. Con un pool de conexiones, la app DEBE llamar
-- sp_set_negocio al tomar la conexión y sp_limpiar_negocio al devolverla.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_negocio() RETURNS BIGINT UNSIGNED
  NO SQL DETERMINISTIC
BEGIN
  RETURN @negocio_id;      -- NULL si nadie lo fijó: las vistas no devuelven nada
END$$

CREATE PROCEDURE sp_set_negocio(IN p_negocio BIGINT UNSIGNED)
BEGIN
  DECLARE v_estado VARCHAR(15);
  SELECT estado INTO v_estado FROM negocio WHERE id = p_negocio;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Negocio no existe';
  ELSEIF v_estado <> 'activo' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Negocio suspendido o cancelado';
  END IF;
  SET @negocio_id = p_negocio;
END$$

CREATE PROCEDURE sp_limpiar_negocio()
BEGIN
  SET @negocio_id = NULL;
END$$

-- ---------------------------------------------------------------------
-- TURNOS: varios por día, sin cruzarse por empleado.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_validar_turno(
  IN p_negocio BIGINT UNSIGNED, IN p_id BIGINT UNSIGNED, IN p_empleado BIGINT UNSIGNED,
  IN p_fecha DATE, IN p_inicio TIME, IN p_fin TIME)
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  -- Serializa a quienes tocan el mismo empleado: evita dos turnos simultáneos que se crucen.
  SELECT id INTO v_lock FROM empleado WHERE negocio_id = p_negocio AND id = p_empleado FOR UPDATE;
  IF EXISTS (SELECT 1 FROM turno_empleado t
              WHERE t.negocio_id = p_negocio AND t.empleado_id = p_empleado AND t.fecha = p_fecha
                AND t.id <> COALESCE(p_id, 0) AND t.inicio < p_fin AND t.fin > p_inicio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El turno se cruza con otro turno del mismo empleado';
  END IF;
END$$

CREATE TRIGGER trg_turno_bi BEFORE INSERT ON turno_empleado FOR EACH ROW
BEGIN
  CALL sp_validar_turno(NEW.negocio_id, NULL, NEW.empleado_id, NEW.fecha, NEW.inicio, NEW.fin);
END$$

CREATE TRIGGER trg_turno_bu BEFORE UPDATE ON turno_empleado FOR EACH ROW
BEGIN
  CALL sp_validar_turno(NEW.negocio_id, OLD.id, NEW.empleado_id, NEW.fecha, NEW.inicio, NEW.fin);
END$$

-- ---------------------------------------------------------------------
-- CITAS: un servicio de una cita debe
--   * empezar y terminar el mismo día de la cita,
--   * ser de un empleado habilitado para ese servicio,
--   * caer dentro de un turno del empleado en esa sede,
--   * no cruzarse con otra cita ni con un bloqueo de agenda.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_validar_cita_servicio(
  IN p_negocio BIGINT UNSIGNED, IN p_id BIGINT UNSIGNED, IN p_cita BIGINT UNSIGNED,
  IN p_servicio BIGINT UNSIGNED, IN p_empleado BIGINT UNSIGNED,
  IN p_inicio DATETIME, IN p_fin DATETIME, IN p_estado VARCHAR(12))
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  DECLARE v_fecha DATE;
  DECLARE v_sede BIGINT UNSIGNED;
  DECLARE v_activo TINYINT(1);

  IF p_estado <> 'cancelado' THEN
    SELECT id, activo INTO v_lock, v_activo FROM empleado
     WHERE negocio_id = p_negocio AND id = p_empleado FOR UPDATE;

    SELECT fecha, sede_id INTO v_fecha, v_sede FROM cita WHERE negocio_id = p_negocio AND id = p_cita;

    IF DATE(p_inicio) <> DATE(p_fin) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio debe empezar y terminar el mismo día';
    END IF;
    IF v_fecha <> DATE(p_inicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio no coincide con la fecha de la cita';
    END IF;
    IF v_activo = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no está activo';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM empleado_servicio
                    WHERE negocio_id = p_negocio AND empleado_id = p_empleado AND servicio_id = p_servicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no está habilitado para este servicio';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM turno_empleado t
                    WHERE t.negocio_id = p_negocio AND t.empleado_id = p_empleado AND t.sede_id = v_sede
                      AND t.fecha = DATE(p_inicio) AND t.inicio <= TIME(p_inicio) AND t.fin >= TIME(p_fin)) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio queda fuera de los turnos del empleado';
    END IF;
    IF EXISTS (SELECT 1 FROM cita_servicio c
                WHERE c.negocio_id = p_negocio AND c.empleado_id = p_empleado
                  AND c.estado <> 'cancelado' AND c.id <> COALESCE(p_id, 0)
                  AND c.inicio < p_fin AND c.fin > p_inicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado ya tiene una cita en ese horario';
    END IF;
    IF EXISTS (SELECT 1 FROM bloqueo_agenda b
                WHERE b.negocio_id = p_negocio AND b.empleado_id = p_empleado
                  AND b.inicio < p_fin AND b.fin > p_inicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El horario está bloqueado en la agenda del empleado';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_citaserv_bi BEFORE INSERT ON cita_servicio FOR EACH ROW
BEGIN
  CALL sp_validar_cita_servicio(NEW.negocio_id, NULL, NEW.cita_id, NEW.servicio_id,
                                NEW.empleado_id, NEW.inicio, NEW.fin, NEW.estado);
END$$

CREATE TRIGGER trg_citaserv_bu BEFORE UPDATE ON cita_servicio FOR EACH ROW
BEGIN
  -- Solo revalida si cambia lo que afecta la agenda (cerrar o facturar un servicio no la revalida).
  IF NOT (NEW.inicio = OLD.inicio AND NEW.fin = OLD.fin AND NEW.empleado_id = OLD.empleado_id
          AND NEW.servicio_id = OLD.servicio_id AND NOT (OLD.estado = 'cancelado' AND NEW.estado <> 'cancelado')) THEN
    CALL sp_validar_cita_servicio(NEW.negocio_id, OLD.id, NEW.cita_id, NEW.servicio_id,
                                  NEW.empleado_id, NEW.inicio, NEW.fin, NEW.estado);
  END IF;
END$$

-- ---------------------------------------------------------------------
-- INVENTARIO
-- Existencia en bodega = suma del libro de movimientos.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_stock_bodega(p_negocio BIGINT UNSIGNED, p_producto BIGINT UNSIGNED, p_sede BIGINT UNSIGNED)
  RETURNS INT READS SQL DATA
BEGIN
  DECLARE v INT;
  SELECT COALESCE(SUM(cantidad), 0) INTO v FROM movimiento_inventario
   WHERE negocio_id = p_negocio AND producto_id = p_producto AND sede_id = p_sede;
  RETURN v;
END$$

-- Unidades que el empleado aún tiene de una entrega (entregadas - devueltas - vendidas/usadas).
CREATE FUNCTION fn_en_mano(p_negocio BIGINT UNSIGNED, p_entrega BIGINT UNSIGNED)
  RETURNS INT READS SQL DATA
BEGIN
  DECLARE v INT;
  SELECT e.cantidad
         - COALESCE((SELECT SUM(d.cantidad) FROM devolucion_entrega d
                      WHERE d.negocio_id = e.negocio_id AND d.entrega_id = e.id), 0)
         - COALESCE((SELECT SUM(v.cantidad) FROM venta_producto v
                      WHERE v.negocio_id = e.negocio_id AND v.entrega_id = e.id), 0)
    INTO v FROM entrega_interna e WHERE e.negocio_id = p_negocio AND e.id = p_entrega;
  RETURN v;
END$$

-- La bodega nunca queda en negativo.
CREATE TRIGGER trg_mov_bi BEFORE INSERT ON movimiento_inventario FOR EACH ROW
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  IF NEW.cantidad < 0 THEN
    SELECT id INTO v_lock FROM producto WHERE negocio_id = NEW.negocio_id AND id = NEW.producto_id FOR UPDATE;
    IF fn_stock_bodega(NEW.negocio_id, NEW.producto_id, NEW.sede_id) + NEW.cantidad < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay existencias suficientes en la bodega';
    END IF;
  END IF;
END$$

-- El libro de inventario y la auditoría solo se agregan: no se editan ni se borran.
CREATE TRIGGER trg_mov_bu BEFORE UPDATE ON movimiento_inventario FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos de inventario no se editan: registra un ajuste'; END$$
CREATE TRIGGER trg_mov_bd BEFORE DELETE ON movimiento_inventario FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos de inventario no se borran: registra un ajuste'; END$$
CREATE TRIGGER trg_aud_bu BEFORE UPDATE ON auditoria FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La auditoría no se edita'; END$$
CREATE TRIGGER trg_aud_bd BEFORE DELETE ON auditoria FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La auditoría no se borra'; END$$

-- Entrega al empleado: coherente con el producto y saca las unidades de la bodega.
CREATE TRIGGER trg_entrega_bi BEFORE INSERT ON entrega_interna FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(12);
  DECLARE v_precio DECIMAL(12,2);
  SELECT tipo, precio_empleado INTO v_tipo, v_precio FROM producto
   WHERE negocio_id = NEW.negocio_id AND id = NEW.producto_id;
  IF v_tipo <> NEW.tipo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tipo de la entrega no coincide con el tipo del producto';
  END IF;
  IF NEW.tipo = 'venta' AND NEW.precio_unitario IS NULL THEN
    SET NEW.precio_unitario = v_precio;      -- por defecto, el precio de empleado del producto
  END IF;
END$$

CREATE TRIGGER trg_entrega_ai AFTER INSERT ON entrega_interna FOR EACH ROW
BEGIN
  DECLARE v_sede BIGINT UNSIGNED;
  SELECT sede_id INTO v_sede FROM empleado WHERE negocio_id = NEW.negocio_id AND id = NEW.empleado_id;
  INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, entrega_id, registrado_por, tipo, cantidad, nota)
  VALUES (NEW.negocio_id, NEW.producto_id, v_sede, NEW.id, NEW.entregada_por, 'entrega', -NEW.cantidad, NEW.nota);
END$$

-- Devolución: no puede devolver más de lo que tiene. Lo dañado o perdido no regresa a la bodega.
CREATE TRIGGER trg_devolucion_bi BEFORE INSERT ON devolucion_entrega FOR EACH ROW
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  SELECT id INTO v_lock FROM entrega_interna WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id FOR UPDATE;
  IF NEW.cantidad > fn_en_mano(NEW.negocio_id, NEW.entrega_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Devuelve más unidades de las que el empleado tiene';
  END IF;
  IF NEW.motivo IN ('danada','perdida') AND NEW.se_cobra IS NULL THEN SET NEW.se_cobra = 0; END IF;
  IF NEW.motivo IN ('no vendida','retiro') THEN SET NEW.se_cobra = 0; END IF;
END$$

CREATE TRIGGER trg_devolucion_ai AFTER INSERT ON devolucion_entrega FOR EACH ROW
BEGIN
  DECLARE v_producto BIGINT UNSIGNED; DECLARE v_empleado BIGINT UNSIGNED; DECLARE v_sede BIGINT UNSIGNED;
  SELECT producto_id, empleado_id INTO v_producto, v_empleado FROM entrega_interna
   WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
  IF NEW.motivo IN ('no vendida','retiro') THEN
    SELECT sede_id INTO v_sede FROM empleado WHERE negocio_id = NEW.negocio_id AND id = v_empleado;
    INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, entrega_id, tipo, cantidad, nota)
    VALUES (NEW.negocio_id, v_producto, v_sede, NEW.entrega_id, 'devolucion', NEW.cantidad, NEW.motivo);
  END IF;
  IF fn_en_mano(NEW.negocio_id, NEW.entrega_id) = 0 THEN
    UPDATE entrega_interna SET estado = 'cerrada' WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
  END IF;
END$$

-- Venta: si sale de una entrega, no vende más de lo que el empleado tiene (la bodega ya
-- se descontó al entregar). Si es de mostrador, descuenta la bodega de la sede.
CREATE TRIGGER trg_venta_bi BEFORE INSERT ON venta_producto FOR EACH ROW
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  DECLARE v_pe DECIMAL(12,2);
  DECLARE v_prod BIGINT UNSIGNED; DECLARE v_emp BIGINT UNSIGNED; DECLARE v_tipo VARCHAR(12);
  IF NEW.entrega_id IS NOT NULL THEN
    SELECT id, producto_id, empleado_id, tipo INTO v_lock, v_prod, v_emp, v_tipo FROM entrega_interna
     WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id FOR UPDATE;
    IF v_tipo <> 'venta' OR v_prod <> NEW.producto_id OR v_emp <> NEW.empleado_id THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no corresponde a la entrega indicada';
    END IF;
    IF NEW.cantidad > fn_en_mano(NEW.negocio_id, NEW.entrega_id) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no tiene tantas unidades';
    END IF;
    IF NEW.precio_empleado IS NULL THEN
      SELECT precio_unitario INTO v_pe FROM entrega_interna WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
      SET NEW.precio_empleado = v_pe;
    END IF;
  ELSEIF NEW.destino <> 'mostrador' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta de un empleado debe indicar la entrega de la que sale';
  END IF;
END$$

CREATE TRIGGER trg_venta_ai AFTER INSERT ON venta_producto FOR EACH ROW
BEGIN
  DECLARE v_sede BIGINT UNSIGNED;
  IF NEW.entrega_id IS NULL THEN
    IF NEW.cita_id IS NOT NULL THEN
      SELECT sede_id INTO v_sede FROM cita WHERE negocio_id = NEW.negocio_id AND id = NEW.cita_id;
    ELSE
      SELECT id INTO v_sede FROM sede WHERE negocio_id = NEW.negocio_id AND principal = 1 LIMIT 1;
    END IF;
    INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, venta_id, tipo, cantidad)
    VALUES (NEW.negocio_id, NEW.producto_id, v_sede, NEW.id, 'venta', -NEW.cantidad);
  ELSE
    IF fn_en_mano(NEW.negocio_id, NEW.entrega_id) = 0 THEN
      UPDATE entrega_interna SET estado = 'cerrada' WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
    END IF;
  END IF;
END$$

-- ---------------------------------------------------------------------
-- FACTURA: consecutivo por negocio, líneas desde la cita y total.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_emitir_factura(
  IN p_negocio BIGINT UNSIGNED, IN p_cita BIGINT UNSIGNED, IN p_metodo VARCHAR(15),
  OUT p_factura BIGINT UNSIGNED)
BEGIN
  DECLARE v_num INT UNSIGNED; DECLARE v_total DECIMAL(12,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  IF EXISTS (SELECT 1 FROM factura WHERE negocio_id = p_negocio AND cita_id = p_cita) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita ya tiene factura';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cita_servicio WHERE negocio_id = p_negocio AND cita_id = p_cita AND estado = 'realizado') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita no tiene servicios realizados para facturar';
  END IF;
  -- El UPDATE bloquea la fila del negocio: dos facturas simultáneas no repiten número.
  UPDATE negocio SET ultimo_numero_factura = ultimo_numero_factura + 1 WHERE id = p_negocio;
  SELECT ultimo_numero_factura INTO v_num FROM negocio WHERE id = p_negocio;

  INSERT INTO factura (negocio_id, cita_id, numero, total, metodo_pago) VALUES (p_negocio, p_cita, v_num, 0, p_metodo);
  SET p_factura = LAST_INSERT_ID();

  INSERT INTO factura_linea (negocio_id, factura_id, cita_servicio_id, empleado_id, descripcion, valor)
  SELECT cs.negocio_id, p_factura, cs.id, cs.empleado_id, s.nombre, cs.valor
    FROM cita_servicio cs JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
   WHERE cs.negocio_id = p_negocio AND cs.cita_id = p_cita AND cs.estado = 'realizado';

  INSERT INTO factura_linea (negocio_id, factura_id, venta_producto_id, empleado_id, descripcion, valor)
  SELECT v.negocio_id, p_factura, v.id, v.empleado_id, pr.nombre, v.cantidad * v.precio_cobrado
    FROM venta_producto v JOIN producto pr ON pr.negocio_id = v.negocio_id AND pr.id = v.producto_id
   WHERE v.negocio_id = p_negocio AND v.cita_id = p_cita AND v.destino = 'cliente';

  SELECT COALESCE(SUM(valor), 0) INTO v_total FROM factura_linea WHERE negocio_id = p_negocio AND factura_id = p_factura;
  UPDATE factura SET total = v_total WHERE negocio_id = p_negocio AND id = p_factura;
  UPDATE cita SET estado = 'finalizada' WHERE negocio_id = p_negocio AND id = p_cita;
  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- ALTA DE UN NEGOCIO (tenant) con todo lo que necesita para empezar:
-- sede principal, áreas, catálogo base, documentos requeridos, categorías
-- de gasto y el usuario dueño.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_crear_negocio(
  IN p_slug VARCHAR(60), IN p_nombre VARCHAR(120), IN p_plan BIGINT UNSIGNED,
  IN p_correo_dueno VARCHAR(160), IN p_clave_hash VARCHAR(255),
  OUT p_negocio BIGINT UNSIGNED)
BEGIN
  DECLARE v_cab BIGINT UNSIGNED; DECLARE v_uni BIGINT UNSIGNED;
  DECLARE v_bar BIGINT UNSIGNED; DECLARE v_cej BIGINT UNSIGNED;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  INSERT INTO negocio (slug, nombre, plan_id) VALUES (p_slug, p_nombre, p_plan);
  SET p_negocio = LAST_INSERT_ID();

  INSERT INTO suscripcion (negocio_id, plan_id, estado, inicio) VALUES (p_negocio, p_plan, 'prueba', CURRENT_DATE);
  INSERT INTO sede (negocio_id, nombre, principal) VALUES (p_negocio, 'Sede principal', 1);
  INSERT INTO usuario (negocio_id, correo, clave_hash, rol_id)
    SELECT p_negocio, p_correo_dueno, p_clave_hash, id FROM rol WHERE clave = 'dueno';

  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Cabello'); SET v_cab = LAST_INSERT_ID();
  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Uñas');    SET v_uni = LAST_INSERT_ID();
  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Barbería');SET v_bar = LAST_INSERT_ID();
  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Cejas');   SET v_cej = LAST_INSERT_ID();

  -- Catálogo base: cabello y barba 30 min, uñas 45 min, cejas 15 min. El dueño ajusta precios.
  INSERT INTO servicio (negocio_id, area_id, nombre, duracion_min, precio, permite_asesoria) VALUES
    (p_negocio, v_cab, 'Corte', 30, 35000, 0),
    (p_negocio, v_cab, 'Color', 30, 80000, 1),
    (p_negocio, v_cab, 'Peinado', 30, 40000, 0),
    (p_negocio, v_uni, 'Tradicional', 45, 30000, 0),
    (p_negocio, v_uni, 'Acrílicas', 45, 70000, 1),
    (p_negocio, v_uni, 'Semipermanentes', 45, 45000, 0),
    (p_negocio, v_bar, 'Barba', 30, 20000, 0),
    (p_negocio, v_cej, 'Cejas', 15, 15000, 0);

  INSERT INTO documento_requerido (negocio_id, nombre, obligatorio, orden) VALUES
    (p_negocio,'Documento de identidad',1,1), (p_negocio,'Afiliación a salud (EPS)',1,2),
    (p_negocio,'Certificado de bioseguridad',1,3), (p_negocio,'Examen médico ocupacional',1,4),
    (p_negocio,'Hoja de vida',0,5);

  INSERT INTO categoria_gasto (negocio_id, nombre) VALUES
    (p_negocio,'Arriendo'), (p_negocio,'Servicios públicos'), (p_negocio,'Insumos'),
    (p_negocio,'Nómina'), (p_negocio,'Publicidad'), (p_negocio,'Otros');
  COMMIT;
END$$

DELIMITER ;
-- =====================================================================
-- CITARA · 04 · Vistas derivadas (lo que se calcula, no se guarda)
-- Incluyen negocio_id: la app las usa a través de las vistas t_* de 05.
-- =====================================================================

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
