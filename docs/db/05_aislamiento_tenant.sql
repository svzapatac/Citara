-- =====================================================================
-- CITARA · 05 · Aislamiento entre negocios (reemplazo de RLS)  [GENERADO]
-- Generado por generar_aislamiento.py. No editar a mano.
--
-- La app se conecta SOLO al esquema `citara_app`. Cada vista:
--   * filtra por negocio_id = fn_negocio()  (el tenant de la conexión),
--   * rechaza INSERT/UPDATE de filas de otro negocio (WITH CHECK OPTION).
-- Si la conexión no fijó el tenant (@negocio_id NULL), no ve ni escribe nada.
-- =====================================================================
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS citara_app;
CREATE DATABASE citara_app CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE citara_app;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW `area` AS SELECT `id`, `negocio_id`, `nombre`, `activa` FROM citara.`area` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `area_dotacion` AS SELECT `id`, `negocio_id`, `area_id`, `producto_id`, `cantidad`, `nota` FROM citara.`area_dotacion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `asesoria_chat` AS SELECT `id`, `negocio_id`, `cliente_id`, `cita_id`, `tipo`, `duracion_propuesta_min`, `estado` FROM citara.`asesoria_chat` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `asesoria_mensaje` AS SELECT `id`, `negocio_id`, `chat_id`, `autor`, `texto`, `enviado_en` FROM citara.`asesoria_mensaje` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `asesoria_regla` AS SELECT `id`, `negocio_id`, `servicio_id`, `motivo`, `duracion_min` FROM citara.`asesoria_regla` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `auditoria` AS SELECT `id`, `negocio_id`, `usuario_id`, `entidad`, `entidad_id`, `accion`, `antes`, `despues`, `fecha` FROM citara.`auditoria` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `bloqueo_agenda` AS SELECT `id`, `negocio_id`, `empleado_id`, `inicio`, `fin`, `motivo` FROM citara.`bloqueo_agenda` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `categoria_gasto` AS SELECT `id`, `negocio_id`, `nombre` FROM citara.`categoria_gasto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `cita` AS SELECT `id`, `negocio_id`, `sede_id`, `cliente_id`, `creada_por`, `fecha`, `origen`, `estado`, `notas`, `creada_en` FROM citara.`cita` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `cita_servicio` AS SELECT `id`, `negocio_id`, `cita_id`, `servicio_id`, `empleado_id`, `inicio`, `fin`, `duracion_min`, `valor`, `estado` FROM citara.`cita_servicio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `cliente` AS SELECT `id`, `negocio_id`, `usuario_id`, `nombres`, `apellidos`, `celular`, `correo`, `tipo_documento`, `documento`, `fecha_nacimiento`, `notas`, `acepta_recordatorios`, `origen`, `activo`, `creado_en` FROM citara.`cliente` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `comision` AS SELECT `id`, `negocio_id`, `empleado_id`, `servicio_id`, `porcentaje`, `vigente_desde`, `vigente_hasta` FROM citara.`comision` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `devolucion_entrega` AS SELECT `id`, `negocio_id`, `entrega_id`, `fecha`, `cantidad`, `motivo`, `se_cobra` FROM citara.`devolucion_entrega` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `documento_negocio` AS SELECT `id`, `negocio_id`, `tipo`, `nombre`, `archivo_url`, `subido_en` FROM citara.`documento_negocio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `documento_requerido` AS SELECT `id`, `negocio_id`, `nombre`, `obligatorio`, `orden` FROM citara.`documento_requerido` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado` AS SELECT `id`, `negocio_id`, `usuario_id`, `sede_id`, `tipo_documento`, `documento`, `nombres`, `apellidos`, `fecha_nacimiento`, `celular`, `correo`, `direccion`, `contacto_emergencia`, `telefono_emergencia`, `fecha_ingreso`, `fecha_retiro`, `motivo_retiro`, `periodicidad_pago`, `activo` FROM citara.`empleado` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado_area` AS SELECT `negocio_id`, `empleado_id`, `area_id` FROM citara.`empleado_area` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado_documento` AS SELECT `id`, `negocio_id`, `empleado_id`, `documento_requerido_id`, `archivo_url`, `estado`, `verificado_por`, `subido_en`, `verificado_en` FROM citara.`empleado_documento` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado_servicio` AS SELECT `negocio_id`, `empleado_id`, `servicio_id` FROM citara.`empleado_servicio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `entrega_interna` AS SELECT `id`, `negocio_id`, `producto_id`, `empleado_id`, `entregada_por`, `tipo`, `fecha`, `cantidad`, `precio_unitario`, `estado`, `nota` FROM citara.`entrega_interna` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `factura` AS SELECT `id`, `negocio_id`, `cita_id`, `numero`, `total`, `metodo_pago`, `estado`, `emitida_en` FROM citara.`factura` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `factura_linea` AS SELECT `id`, `negocio_id`, `factura_id`, `cita_servicio_id`, `venta_producto_id`, `empleado_id`, `descripcion`, `valor` FROM citara.`factura_linea` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `gasto` AS SELECT `id`, `negocio_id`, `sede_id`, `categoria_id`, `registrado_por`, `concepto`, `valor`, `fecha` FROM citara.`gasto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `invitacion` AS SELECT `id`, `negocio_id`, `correo`, `rol_id`, `empleado_id`, `creada_por`, `token_hash`, `expira_en`, `estado` FROM citara.`invitacion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `liquidacion` AS SELECT `id`, `negocio_id`, `empleado_id`, `pagado_por`, `periodicidad`, `desde`, `hasta`, `total_comisiones`, `total_descuentos`, `total_neto`, `estado`, `pagado_en` FROM citara.`liquidacion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `liquidacion_detalle` AS SELECT `id`, `negocio_id`, `liquidacion_id`, `cita_servicio_id`, `venta_id`, `devolucion_id`, `tipo`, `descripcion`, `base`, `porcentaje`, `valor` FROM citara.`liquidacion_detalle` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `movimiento_inventario` AS SELECT `id`, `negocio_id`, `producto_id`, `sede_id`, `entrega_id`, `venta_id`, `registrado_por`, `tipo`, `cantidad`, `fecha`, `nota` FROM citara.`movimiento_inventario` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `negocio` AS SELECT `id`, `slug`, `nombre`, `nit`, `plan_id`, `estado`, `zona_horaria`, `moneda`, `ultimo_numero_factura`, `creado_en` FROM citara.negocio WHERE id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `permiso` AS SELECT `id`, `modulo`, `accion` FROM citara.`permiso`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `plan` AS SELECT `id`, `nombre`, `max_sedes`, `max_empleados`, `precio_mensual`, `activo` FROM citara.`plan`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `producto` AS SELECT `id`, `negocio_id`, `nombre`, `tipo`, `codigo`, `unidad`, `costo`, `precio_publico`, `precio_empleado`, `stock_minimo`, `proveedor`, `activo` FROM citara.`producto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `rol` AS SELECT `id`, `clave`, `nombre` FROM citara.`rol`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `rol_permiso` AS SELECT `rol_id`, `permiso_id` FROM citara.`rol_permiso`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `sede` AS SELECT `id`, `negocio_id`, `nombre`, `direccion`, `ciudad`, `telefono`, `principal`, `activa` FROM citara.`sede` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `sede_horario` AS SELECT `id`, `negocio_id`, `sede_id`, `dia_semana`, `apertura`, `cierre` FROM citara.`sede_horario` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `servicio` AS SELECT `id`, `negocio_id`, `area_id`, `nombre`, `descripcion`, `duracion_min`, `precio`, `permite_asesoria`, `activo` FROM citara.`servicio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `suscripcion` AS SELECT `id`, `negocio_id`, `plan_id`, `estado`, `inicio`, `fin` FROM citara.`suscripcion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `televisor` AS SELECT `id`, `negocio_id`, `sede_id`, `nombre`, `token_hash`, `activo` FROM citara.`televisor` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `turno_empleado` AS SELECT `id`, `negocio_id`, `empleado_id`, `sede_id`, `fecha`, `inicio`, `fin` FROM citara.`turno_empleado` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `usuario` AS SELECT `id`, `negocio_id`, `correo`, `clave_hash`, `rol_id`, `activo`, `ultimo_acceso` FROM citara.`usuario` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `usuario_sede` AS SELECT `negocio_id`, `usuario_id`, `sede_id` FROM citara.`usuario_sede` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_agenda_dia` AS SELECT `negocio_id`, `sede_id`, `fecha`, `cita_servicio_id`, `cita_id`, `inicio`, `fin`, `empleado_id`, `empleado`, `cliente_id`, `cliente`, `servicio`, `valor`, `estado_servicio`, `estado_cita` FROM citara.`v_agenda_dia` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_en_mano_empleado` AS SELECT `negocio_id`, `entrega_id`, `empleado_id`, `producto_id`, `producto`, `tipo`, `entregadas`, `devueltas`, `vendidas`, `en_mano` FROM citara.`v_en_mano_empleado` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_estado_dotacion` AS SELECT `negocio_id`, `empleado_id`, `area`, `producto_id`, `pieza`, `requerida`, `entregada`, `estado` FROM citara.`v_estado_dotacion` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_existencia_bodega` AS SELECT `negocio_id`, `producto_id`, `sede_id`, `producto`, `tipo`, `sede`, `existencia`, `stock_minimo` FROM citara.`v_existencia_bodega` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_expediente_documentos` AS SELECT `negocio_id`, `empleado_id`, `documento_requerido_id`, `nombre`, `obligatorio`, `orden`, `empleado_documento_id`, `subido_en`, `verificado_en`, `estado` FROM citara.`v_expediente_documentos` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_ganancia_empleado` AS SELECT `negocio_id`, `empleado_id`, `mes`, `ganancia`, `descuento_ventas`, `descuento_personal` FROM citara.`v_ganancia_empleado` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_stock_bajo` AS SELECT `negocio_id`, `producto_id`, `sede_id`, `producto`, `tipo`, `sede`, `existencia`, `stock_minimo` FROM citara.`v_stock_bajo` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `venta_producto` AS SELECT `id`, `negocio_id`, `producto_id`, `empleado_id`, `entrega_id`, `cliente_id`, `cita_id`, `fecha`, `cantidad`, `destino`, `precio_cobrado`, `precio_empleado` FROM citara.`venta_producto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;

-- Rutinas que la app puede usar. El negocio NUNCA es un parámetro: sale de la conexión.
DELIMITER $$
CREATE PROCEDURE sp_set_negocio(IN p_negocio BIGINT UNSIGNED) BEGIN CALL citara.sp_set_negocio(p_negocio); END$$
CREATE PROCEDURE sp_limpiar_negocio() BEGIN CALL citara.sp_limpiar_negocio(); END$$
CREATE PROCEDURE sp_emitir_factura(IN p_cita BIGINT UNSIGNED, IN p_metodo VARCHAR(15), OUT p_factura BIGINT UNSIGNED)
BEGIN
  IF citara.fn_negocio() IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Falta fijar el negocio de la conexión'; END IF;
  CALL citara.sp_emitir_factura(citara.fn_negocio(), p_cita, p_metodo, p_factura);
END$$
DELIMITER ;

